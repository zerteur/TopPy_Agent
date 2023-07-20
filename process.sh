#!/bin/bash

# Inclure les fichiers de fonctions
source "$(dirname "$0")/display_functions.sh"
source "$(dirname "$0")/process_functions.sh"
source "$(dirname "$0")/config_functions.sh"

# Récupérer les informations personnalisées du script principal (script.sh)
TOKEN="$1"
ORG="$2"
URL="$3"
BUCKET="$4"

# Obtenir la liste des processus en cours d'exécution avec leurs PIDs
process_list=$(ps -e -o pid,comm=)

# Déclaration du tableau des process_names
declare -A process_names

# Appeler la fonction pour choisir et renommer les processus
choose_and_rename_processes "$process_list" process_names

# Créer le fichier config.yaml avec les informations personnalisées et les processus renommés
create_config_yaml "$TOKEN" "$ORG" "$URL" "$BUCKET"

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
