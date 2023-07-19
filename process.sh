#!/bin/bash

# Fonction pour afficher les processus avec pagination
display_processes() {
    local process_list=$1
    local page_size=$2
    local current_page=$3
    local total_pages=$4

    # Calculer l'indice de début et de fin pour la pagination
    local start_index=$(( (current_page - 1) * page_size + 1 ))
    local end_index=$(( start_index + page_size - 1 ))

    # Afficher les processus pour la page actuelle
    clear
    echo "Liste des processus (Page $current_page/$total_pages) :"
    echo "----------------------------------------------"
    echo "$process_list" | awk -v start="$start_index" -v end="$end_index" 'NR>=start && NR<=end {print $1, $2}'
    echo "----------------------------------------------"
}

# Fonction pour obtenir le nom du processus à partir du PID
get_process_name() {
    local pid=$1
    local process_name=$(ps -p $pid -o comm=)
    echo "$process_name"
}

# Fonction pour afficher un récapitulatif des processus renommés
show_summary() {
    echo "Récapitulatif des processus renommés :"
    echo "-----------------------------------"

    for process_name in "${!process_names[@]}"; do
        rename="${process_names[$process_name]}"
        echo "  - name: \"$process_name\""
        echo "    rename: \"$rename\""
    done

    echo "-----------------------------------"
}

# Fonction pour choisir et renommer les processus
choose_and_rename_processes() {
    local process_list=$1
    local -n process_names_ref=$2

    # Déclaration du tableau des process_names
    declare -A process_names

    # Vérifier si le fichier config.yaml existe et le charger s'il existe
    if [ -f "config.yaml" ]; then
        source config.yaml
    fi

    # Boucle pour afficher les processus par pages
    while true; do
        # Paramètres pour la pagination des processus
        local page_size=10
        local current_page=1
        local total_pages=$(( ( $(ps -e -o pid= | wc -l) - 1) / page_size + 1))

        # Boucle pour afficher les processus par pages
        while true; do
            # Afficher les processus pour la page actuelle
            display_processes "$process_list" $page_size $current_page $total_pages

            # Proposer les options : [C]hoix, [P]récedent, [S]uivant, [Q]uitter
            read -p "Choisissez une option : [C]hoix, [P]récedent, [S]uivant, [Q]uitter : " option

            case $option in
                C)
                    # Choix d'un processus
                    read -p "Entrez le PID du processus que vous souhaitez renommer : " pid
                    process_name=$(get_process_name "$pid")

                    read -p "Voulez-vous renommer le processus '$process_name' (PID: $pid) ? (O/N) " choice
                    if [[ $choice =~ ^[Oo]$ ]]; then
                        read -p "Entrez le nouveau nom pour le processus : " new_name
                        process_names["$process_name"]=$new_name
                        echo "Le processus '$process_name' (PID: $pid) a été renommé en '$new_name'."
                    else
                        echo "Le processus '$process_name' (PID: $pid) ne sera pas renommé."
                    fi
                    ;;
                P)
                    # Page précédente
                    if (( current_page > 1 )); then
                        (( current_page-- ))
                    fi
                    ;;
                S)
                    # Page suivante
                    if (( current_page < total_pages )); then
                        (( current_page++ ))
                    fi
                    ;;
                Q)
                    # Quitter
                    show_summary
                    break 2
                    ;;
                *)
                    echo "Option invalide. Veuillez réessayer."
                    ;;
            esac
        done
    done

    # Ajouter les nouveaux process_names renommés au tableau existant dans config.yaml
    for process_name in "${!process_names[@]}"; do
        rename="${process_names[$process_name]}"

        if [[ -z ${process_names[$process_name]} ]]; then
            # Le processus n'a pas été renommé, conserver le nom d'origine
            process_names["$process_name"]="$process_name"
        fi

        # Vérifier si le nom du processus existe déjà dans le tableau
        if [[ " ${!config_process_names[@]} " =~ " $process_name " ]]; then
            # Le nom du processus existe déjà, supprimer l'ancienne entrée
            unset "config_process_names[$process_name]"
        fi

        # Ajouter le processus renommé au tableau
        config_process_names["$process_name"]=$rename
    done

    # Mettre à jour le fichier config.yaml avec les process_names renommés
    echo "process_names:" > config.yaml

    for process_name in "${!config_process_names[@]}"; do
        rename="${config_process_names[$process_name]}"
        echo "  - name: \"$process_name\"" >> config.yaml
        echo "    rename: \"$rename\"" >> config.yaml
    done

    # Exporter le tableau process_names
    process_names_ref=("${process_names[@]}")
}
