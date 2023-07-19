#!/bin/bash

# Installer les dépendances
sudo pip install -r requirements.txt

# Ouvrir config.yaml avec Nano
nano config.yaml

# Vérifier si Python est disponible
if command -v python &> /dev/null; then
    # Exécuter main.py en arrière-plan
    nohup python main.py > /dev/null 2>&1 &
elif command -v python3 &> /dev/null; then
    # Exécuter main.py avec Python 3 en arrière-plan
    nohup python3 main.py > /dev/null 2>&1 &
else
    echo "Erreur : Python n'est pas installé sur ce système."
fi

