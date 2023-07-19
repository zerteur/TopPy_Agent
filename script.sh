#!/bin/bash

# Inclure le fichier process.sh
source process.sh

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

# Obtenir la liste des processus en cours d'exécution avec leurs PIDs
process_list=$(ps -e -o pid,comm=)

# Déclaration du tableau des process_names
declare -A process_names

# Variables pour la pagination
page_size=10
current_page=1
total_pages=$(( ($(echo "$process_list" | wc -l) - 1) / $page_size + 1 ))

# Afficher les processus par pages et demander à l'utilisateur de renommer
display_processes "$process_list" $page_size $current_page $total_pages
while true; do
    read -p "Choisissez une option : [P]recedent, [S]uivant, [C]hoix, [Q]uitter : " option
    
    case $option in
        [Pp])
            if [[ $current_page -gt 1 ]]; then
                current_page=$((current_page - 1))
            fi
            ;;
        [Ss])
            if [[ $current_page -lt $total_pages ]]; then
                current_page=$((current_page + 1))
            fi
            ;;
        [Cc])
            read -p "Entrez le PID du processus que vous souhaitez renommer : " pid
            process_name=$(get_process_name "$pid")
            if [[ -z $process_name ]]; then
                echo "PID invalide. Veuillez choisir un PID valide."
                continue
            fi
            rename_process "$process_name" "$pid"
            ;;
        [Qq])
            break
            ;;
        *)
            echo "Option invalide. Veuillez choisir une option valide."
            continue
            ;;
    esac
    
    # Afficher les processus mis à jour
    display_processes "$process_list" $page_size $current_page $total_pages
    
    # Proposer deux choix supplémentaires
    read -p "Choisissez une option : [C]ontinuer à ajouter des processus, [P]asser à l'étape suivante du script : " option
    
    if [[ $option =~ ^[Cc]$ ]]; then
        continue
    elif [[ $option =~ ^[Pp]$ ]]; then
        break
    fi
done

# Faire une pause pour permettre à l'utilisateur de voir les résultats avant de poursuivre
read -p "Appuyez sur Entrée pour continuer..."

# Mettre à jour le fichier config.yaml avec les process_names renommés
echo "process_names:" > config.yaml

for process_name in "${!process_names[@]}"; do
    rename="${process_names[$process_name]}"
    echo "  - name: \"$process_name\"" >> config.yaml
    echo "    rename: \"$rename\"" >> config.yaml
done

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
