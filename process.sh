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

# Déclaration du tableau des process_names
declare -A process_names
