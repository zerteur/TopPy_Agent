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
process_list=$(ps -e -o pid,comm= | tail -n +2)

# Déclaration du tableau des process_names
declare -A process_names

# Afficher les processus par groupe de 10
page=1
process_count=0
page_size=10

while read -r line; do
    # Extraire le PID et le nom du processus
    pid=$(echo "$line" | awk '{print $1}')
    process_name=$(echo "$line" | awk '{print $2}')
    
    # Afficher le processus
    echo "[$pid] $process_name"
    
    process_count=$((process_count+1))
    
    # Vérifier si le nombre de processus affichés atteint la taille de la page
    if [[ $process_count -eq $page_size ]]; then
        # Demander à l'utilisateur de continuer ou de passer à la page suivante
        read -p "Appuyez sur Entrée pour afficher la page suivante ou entrez 'q' pour passer à l'étape suivante du script : " choice
        
        if [[ $choice == "q" ]]; then
            break
        fi
        
        # Réinitialiser le compteur de processus et passer à la page suivante
        process_count=0
        page=$((page+1))
        clear
        echo "Page $page :"
    fi
    
done <<< "$process_list"

# Demander à l'utilisateur de renommer un processus
read -p "Entrez le numéro du processus que vous souhaitez renommer : " selected_pid

process_name=$(get_process_name "$selected_pid")
if [[ -n $process_name ]]; then
    rename_process "$process_name" "$selected_pid"
fi

# Mettre à jour le fichier config.yaml avec les process_names renommés
config_file="config.yaml"
temp_file="config_temp.yaml"

# Supprimer le fichier temporaire s'il existe
rm -f "$temp_file"

# Lire le fichier config.yaml ligne par ligne et écrire dans le fichier temporaire
while IFS= read -r line; do
    if [[ $line == "process_names:" ]]; then
        # Écrire les process_names renommés dans le fichier temporaire
        echo "$line" >> "$temp_file"
        
        for process_name in "${!process_names[@]}"; do
            rename="${process_names[$process_name]}"
            echo "  - name: \"$process_name\"" >> "$temp_file"
            echo "    rename: \"$rename\"" >> "$temp_file"
        done
    else
        # Écrire les autres lignes inchangées dans le fichier temporaire
        echo "$line" >> "$temp_file"
    fi
done < "$config_file"

# Remplacer le fichier config.yaml par le fichier temporaire
mv "$temp_file" "$config_file"

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
