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

# Fonction pour afficher les processus par pages
display_processes() {
    local process_list="$1"
    local page_size=10
    local total_processes=$(echo "$process_list" | wc -l)
    local total_pages=$((total_processes / page_size))
    local current_page=0
    local start_index=0
    
    while true; do
        clear
        echo "Liste des processus (Page $((current_page + 1))/$((total_pages + 1))):"
        echo "===================="
        echo "$process_list" | awk "NR > $start_index && NR <= $((start_index + page_size))"
        echo "===================="
        echo
        
        if ((current_page > 0)); then
            echo "[P]recedent"
        fi
        
        if ((current_page < total_pages)); then
            echo "[S]uivant"
        fi
        
        echo "[Q]uitter"
        echo
        
        read -p "Choisissez une option : " option
        
        case $option in
            [Pp])
                if ((current_page > 0)); then
                    ((current_page--))
                    ((start_index -= page_size))
                fi
                ;;
            [Ss])
                if ((current_page < total_pages)); then
                    ((current_page++))
                    ((start_index += page_size))
                fi
                ;;
            [Qq])
                break
                ;;
            *)
                echo "Option invalide. Veuillez choisir une option valide."
                ;;
        esac
    done
}
