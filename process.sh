#!/bin/bash

# Fonction pour afficher les processus par pages
display_processes_by_page() {
    # Nombre de processus affichés par page
    local per_page=10
    # Compteur de processus
    local count=0
    # Compteur de pages
    local page=1
    
    # Obtenir la liste des processus en cours d'exécution avec leurs PIDs
    local process_list=$(ps -e -o pid,comm=)
    
    # Parcourir chaque ligne du résultat de ps
    while IFS= read -r line; do
        # Extraire le PID et le nom du processus
        local pid=$(echo "$line" | awk '{print $1}')
        local process_name=$(echo "$line" | awk '{print $2}')
        
        # Afficher le processus
        echo "[$pid] $process_name"
        
        # Incrémenter le compteur de processus
        ((count++))
        
        # Vérifier si le compteur de processus atteint le nombre par page
        if [[ $count -eq $per_page ]]; then
            # Demander à l'utilisateur de continuer ou de passer à la page suivante
            read -p "Appuyez sur [Entrée] pour continuer à afficher les processus ou [P] pour passer à la page suivante : " choice
            
            # Vérifier le choix de l'utilisateur
            if [[ $choice =~ ^[Pp]$ ]]; then
                # Réinitialiser le compteur de processus
                count=0
                # Incrémenter le compteur de pages
                ((page++))
                # Effacer l'écran
                clear
                # Afficher le numéro de page
                echo "Page $page :"
            fi
        fi
    done <<< "$process_list"
}

# Fonction pour renommer un processus
rename_process() {
    local pid=$1
    local process_name=$2
    
    # Demander à l'utilisateur s'il souhaite renommer le processus
    read -p "Voulez-vous renommer le processus '$process_name' (PID: $pid) ? (Oui/Non) " choice
    
    if [[ $choice =~ ^[Oo]$ ]]; then
        # Demander le nouveau nom du processus
        read -p "Entrez le nouveau nom pour le processus : " new_name
        
        # Renommer le processus
        mv "$(which "$process_name")" "$(which "$new_name")"
        echo "Le processus a été renommé avec succès."
    fi
}

