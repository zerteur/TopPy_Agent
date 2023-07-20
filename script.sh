#!/bin/bash

# Variables personnalisables
TOKEN="zA3nBLsuTTQf5AFTuOZfvpS2IJZDksvw7TuTmy_7ZH_GGQTdPA_UVXwVOYdXp1V8-uvtYx9xkjXmRs8d9VBtEA=="
ORG="Toptex"
URL="http://10.208.3.84:8086"
BUCKET="tt-process"

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

# Inclure le fichier process.sh
source "$(dirname "$0")/process.sh"

# Déclaration du tableau des process_names
declare -A process_names

# Appeler la fonction pour choisir et renommer les processus
choose_and_rename_processes "$process_list" process_names

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

# Construire le contenu du fichier config.yaml avec les informations personnalisables et les processus renommés
config_yaml="token: \"$TOKEN\"\n"
config_yaml+="org: \"$ORG\"\n"
config_yaml+="url: \"$URL\"\n"
config_yaml+="bucket: \"$BUCKET\"\n"
config_yaml+="process_names:\n"

for pid in "${!process_names[@]}"; do
    process_name=$(get_process_name "$pid")
    rename="${process_names[$pid]}"
    config_yaml+="  - name: \"$process_name\"\n"
    config_yaml+="    rename: \"$rename\"\n"
done

# Mettre à jour le fichier config.yaml
config_file="config.yaml"
echo -e "$config_yaml" > "$config_file"

# Afficher les processus renommés
echo "Processus renommés :"
for pid in "${!process_names[@]}"; do
    process_name=$(get_process_name "$pid")
    rename="${process_names[$pid]}"
    echo "- name: \"$process_name\""
    echo "  rename: \"$rename\""
done

# Faire une pause avant la fin du script
read -p "Appuyez sur Entrée pour quitter le script..."
