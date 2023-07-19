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

# Parcourir chaque ligne du résultat de ps
while IFS= read -r line; do
    # Extraire le PID et le nom du processus
    pid=$(echo "$line" | awk '{print $1}')
    process_name=$(echo "$line" | awk '{print $2}')
    
    # Demander à l'utilisateur de renommer le processus
    rename_process "$process_name" "$pid"
    
    # Proposer deux choix supplémentaires
    read -p "Choisissez une option : [C]ontinuer à ajouter des processus, [P]asser à l'étape suivante du script : " option
    
    if [[ $option =~ ^[Cc]$ ]]; then
        continue
    elif [[ $option =~ ^[Pp]$ ]]; then
        break
    fi
done <<< "$process_list"

# Faire une pause pour permettre à l'utilisateur de voir les résultats avant de poursuivre
read -p "Appuyez sur Entrée pour continuer..."

# Mettre à jour le fichier config.yaml avec les process_names renommés
config.yaml

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
