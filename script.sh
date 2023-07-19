#!/bin/bash

# Nom du processus
process_name="TTAgent"

# Vérifier si Python est disponible
if ! command -v python &> /dev/null && ! command -v python3 &> /dev/null; then
    echo "Python n'est pas détecté sur ce système. Installation de Python..."
    sudo apt-get update
    sudo apt-get install -y python3
fi

# Installer les dépendances
sudo pip install -r requirements.txt

# Fonction pour afficher les processus par pages
display_processes_by_page() {
    # Nombre de processus à afficher par page
    page_size=10
    
    # Obtenir la liste des processus en cours d'exécution avec leurs PIDs
    process_list=$(ps -e -o pid,comm=)
    
    # Nombre total de processus
    total_processes=$(echo "$process_list" | wc -l)
    
    # Nombre total de pages
    total_pages=$((total_processes / page_size + 1))
    
    # Variable pour vérifier si des processus ont été affichés
    process_displayed=false
    
    # Variable pour le numéro de page actuel
    current_page=1
    
    # Variable pour le numéro de processus affiché
    process_number=0
    
    # Variable pour stocker les processus sélectionnés
    selected_processes=()
    
    # Parcourir chaque ligne du résultat de ps
    while IFS= read -r line; do
        # Extraire le PID et le nom du processus
        pid=$(echo "$line" | awk '{print $1}')
        process_name=$(echo "$line" | awk '{print $2}')
        
        # Vérifier si le numéro de processus dépasse la limite de la page actuelle
        if [[ $process_number -ge $((current_page * page_size)) ]]; then
            # Vérifier si tous les processus de la page actuelle ont déjà été sélectionnés
            if [[ ${#selected_processes[@]} -ge page_size ]]; then
                # Passer à la page suivante si tous les processus ont été sélectionnés
                current_page=$((current_page + 1))
                selected_processes=()
            fi
        fi
        
        # Afficher le processus avec son numéro et demander à l'utilisateur de le sélectionner
        process_number=$((process_number + 1))
        echo "$process_number. Processus trouvé : $process_name (PID: $pid)"
        
        read -p "Voulez-vous sélectionner ce processus ? (Oui/Non) " choice
        
        if [[ $choice =~ ^[Oo]$ ]]; then
            selected_processes+=("$process_name")
        fi
    done <<< "$process_list"
    
    # Vérifier si des processus ont été affichés
    if [[ $process_displayed = false ]]; then
        echo "Aucun processus trouvé."
    fi
    
    # Afficher les processus sélectionnés
    echo "Processus sélectionnés :"
    for process in "${selected_processes[@]}"; do
        echo "- $process"
    done
}

# Appeler la fonction pour afficher les processus par pages
display_processes_by_page

# Faire une pause pour permettre à l'utilisateur de voir les résultats avant de poursuivre
read -p "Appuyez sur Entrée pour continuer..."

# Fonction pour renommer les processus sélectionnés
rename_selected_processes() {
    # Déclaration du tableau des process_names
    declare -A process_names
    
    for process in "${selected_processes[@]}"; do
        # Demander à l'utilisateur de renommer le processus
        read -p "Voulez-vous renommer le processus '$process' ? (Oui/Non) " choice
        
        if [[ $choice =~ ^[Oo]$ ]]; then
            read -p "Entrez le nouveau nom pour le processus : " new_name
            process_names["$process"]=$new_name
        fi
    done
    
    # Mettre à jour le fichier config.yaml avec les process_names renommés
    echo "process_names:" > config.yaml
    
    for process_name in "${!process_names[@]}"; do
        rename="${process_names[$process_name]}"
        echo "  - name: \"$process_name\"" >> config.yaml
        echo "    rename: \"$rename\"" >> config.yaml
    done
}

# Appeler la fonction pour renommer les processus sélectionnés
rename_selected_processes

# Faire une pause pour permettre à l'utilisateur de voir les résultats avant de poursuivre
read -p "Appuyez sur Entrée pour continuer..."

# Vérifier si Python est disponible
if command -v python &> /dev/null; then
    # Exécuter main.py en arrière-plan en renommant le processus
    exec -a "$process_name" python main.py > $(pwd)/output.log 2>&1 &
elif command -v python3 &> /dev/null; then
    # Exécuter main.py avec Python 3 en arrière-plan en renommant le processus
    exec -a "$process_name" python3 main.py > $(pwd)/output.log 2>&1 &
else
    echo "Erreur : Python n'est pas installé sur ce système."
fi

# Obtenir le chemin absolu de main.py
main_py_path=$(realpath main.py)

# Vérifier si la tâche cron est déjà présente
if ! crontab -l | grep -q "$main_py_path"; then
    # Ajouter main.py à la liste des tâches cron
    (crontab -l 2>/dev/null; echo "@reboot python $main_py_path > $(pwd)/output.log 2>&1") | crontab -
    echo "Tâche cron ajoutée pour main.py."
else
    echo "La tâche cron pour main.py est déjà présente."
fi

# Faire une pause avant la fin du script
read -p "Appuyez sur Entrée pour quitter le script..."
