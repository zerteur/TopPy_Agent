#!/bin/bash

# Fonction pour obtenir le nom du processus à partir du PID
get_process_name() {
    local pid=$1
    local process_name=$(ps -p $pid -o comm=)
    echo "$process_name"
}

# Fonction pour choisir et renommer les processus
choose_and_rename_processes() {
    local process_list=$1
    local -n process_names_ref=$2

    # Déclaration du tableau des process_names
    declare -A process_names

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
                    process_names["$pid"]=$new_name
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
                break
                ;;
            *)
                echo "Option invalide. Veuillez réessayer."
                ;;
        esac
    done

    # Retourner le tableau des process_names renommés
    process_names_ref=("${process_names[@]}")
}
