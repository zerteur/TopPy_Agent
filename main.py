import platform
import psutil
import yaml
import socket
import time
from influxdb_client import InfluxDBClient, Point, WritePrecision
from influxdb_client.client.write_api import SYNCHRONOUS

# Chargement des informations de configuration depuis le fichier conf.yaml
with open('./config.yaml', 'r') as file:
    config = yaml.safe_load(file)

# Extraction des informations de configuration
token = config['token']
org = config['org']
url = config['url']
bucket = config['bucket']
processes = config['process_names']

# Récupération de l'adresse IP de l'hôte
host_ip = socket.gethostbyname(socket.gethostname())

# Fonction pour envoyer un message d'erreur dans le terminal
def print_error_message(error_message):
    print(f"Erreur : {error_message}")
    print("Réessayer dans 5 secondes...")
    time.sleep(5)

connected = False
while not connected:
    try:
        # Initialisation du client InfluxDB
        write_client = InfluxDBClient(url=url, token=token, org=org)
        write_api = write_client.write_api(write_options=SYNCHRONOUS)

        connected = True  # La connexion est établie
        print("Connexion au serveur InfluxDB établie !")
    except Exception as e:
        print_error_message(str(e))

while True:
    for process in processes:
        process_name = process['name']
        rename = process.get('rename', process_name)  # Utilisation du nom par défaut si aucun renommage n'est spécifié

        if platform.system() == "Windows" and process_name.lower().endswith(".exe"):
            is_running = any(process_name.lower() == p.name().lower() for p in psutil.process_iter(attrs=['name']))
        elif platform.system() == "Mac" and process_name.lower().endswith(".dmg"):
            is_running = any(process_name.lower() == p.name().lower() for p in psutil.process_iter(attrs=['name']))
        elif platform.system() == "Linux" and not any(process_name.lower().endswith(ext) for ext in [".exe", ".dmg"]):
            is_running = any(process_name.lower() == p.name().lower() for p in psutil.process_iter(attrs=['name']))
        else:
            is_running = False

        status = "✅" if is_running else "⚡"
        timestamp = time.strftime("%Y-%m-%d %H:%M:%S")

        point = (
            Point("measurement1")
            .tag("program", rename)
            .tag("host", host_ip)
            .field("status", status)
            .field("timestamp", timestamp)
        )

        try:
            write_api.write(bucket=bucket, org=org, record=point)
        except Exception as e:
            print_error_message(str(e))
            continue

    time.sleep(1)  # Attendre une seconde avant la prochaine itération
