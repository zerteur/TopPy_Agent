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
