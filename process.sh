#!/bin/bash

# Fonction pour renommer un processus
rename_process() {
    local process_name=$1
    local pid=$2

    read -p "Voulez-vous renommer le processus '$process_name' (PID: $pid) ? (Oui/Non) " choice
    
    if [[ $choice =~ ^[Oo]$ ]]; then
        read -p "Entrez le nouveau nom pour le processus : " new_name
        process_names["$process_name"]=$new_name
    fi
}

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

# Fonction pour choisir et renommer les processus
choose_and_rename_processes() {
    # Déclaration du tableau des process_names
    declare -A process_names

    # Boucle de choix pour ajouter/renommer des processus
    choice=""
    while [[ $choice != "P" ]]; do
        # Obtenir la liste des processus en cours d'exécution avec leurs PIDs
        process_list=$(ps -e -o pid,comm=)

        # Paramètres pour la pagination des processus
        page_size=10
        current_page=1
        total_pages=$(( ( $(ps -e -o pid= | wc -l) - 1) / page_size + 1))

        # Boucle pour afficher les processus par pages
        while true; do
            display_processes "$process_list" $page_size $current_page $total_pages

            # Proposer les options : [C]hoix, [P]récedent, [S]uivant, [Q]uitter
            read -p "Choisissez une option : [C]hoix, [P]récedent, [S]uivant, [Q]uitter : " option

            case $option in
                C)
                    # Choix d'un processus
                    read -p "Entrez le PID du processus que vous souhaitez renommer : " pid
                    process_name=$(get_process_name "$pid")
                    rename_process "$process_name" "$pid"
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
                    break 2
                    ;;
                *)
                    echo "Option invalide. Veuillez réessayer."
                    ;;
            esac
        done
    done

    # Affichage des process_names renommés
    echo "Processus renommés :"
    for process_name in "${!process_names[@]}"; do
        rename="${process_names[$process_name]}"
        echo "  - name: \"$process_name\""
        echo "    rename: \"$rename\""
    done
}
