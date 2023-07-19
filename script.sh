#!/bin/bash

# Installer les dépendances
sudo pip install -r requirements.txt

# Ouvrir config.yaml avec Nano
nano config.yaml

# Vérifier si Python est disponible
if command -v python &> /dev/null; then
    # Exécuter main.py
    python main.py
elif command -v python3 &> /dev/null; then
    # Exécuter main.py avec Python 3
    python3 main.py &
else
    echo "Erreur : Python n'est pas installé sur ce système."
fi
