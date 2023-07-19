#!/bin/bash

# Fonction pour renommer un processus
rename_process() {
    local process_name="$1"
    local pid="$2"
    local new_name

    read -p "Voulez-vous renommer le processus '$process_name' (PID: $pid) ? (Oui/Non) " choice
    
    if [[ $choice =~ ^[Oo]$ ]]; then
        read -p "Entrez le nouveau nom pour le processus : " new_name
        process_names["$process_name"]=$new_name
    fi
}

# Fonction pour obtenir le nom d'un processus à partir de son PID
get_process_name() {
    local pid="$1"
    local process_name
    
    # Vérifier si le PID existe
    if [[ -n $pid ]]; then
        process_name=$(ps -p "$pid" -o comm= | awk '{print $1}')
    fi
    
    echo "$process_name"
}
