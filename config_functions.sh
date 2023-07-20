#!/bin/bash

# Fonction pour construire le contenu de la section process_names du fichier config.yaml
build_process_names_yaml() {
    local process_names_ref=("$1")
    local process_names_yaml="process_names:\n"

    for pid in "${!process_names_ref[@]}"; do
        process_name=$(get_process_name "$pid")
        rename="${process_names_ref[$pid]}"
        process_names_yaml+="  - name: \"$process_name\"\n"
        process_names_yaml+="    rename: \"$rename\"\n"
    done

    echo -e "$process_names_yaml"
}

# Fonction pour créer le fichier config.yaml avec les informations personnalisées et les processus renommés
create_config_yaml() {
    local TOKEN="$1"
    local ORG="$2"
    local URL="$3"
    local BUCKET="$4"

    local config_yaml="token: \"$TOKEN\"\n"
    config_yaml+="org: \"$ORG\"\n"
    config_yaml+="url: \"$URL\"\n"
    config_yaml+="bucket: \"$BUCKET\"\n"

    # Construire la section process_names et l'ajouter au fichier config.yaml
    local process_names_section=$(build_process_names_yaml process_names)
    config_yaml+="$process_names_section"

    # Écrire le contenu du fichier config.yaml
    echo -e "$config_yaml" > config.yaml
}
