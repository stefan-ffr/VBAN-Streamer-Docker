# VBAN Bluetooth Audio Bridge Setup

Diese Anleitung erklärt, wie Sie Bluetooth-Audio auf einem Raspberry Pi empfangen und über VBAN an Voicemeeter Banana weiterleiten.

## Systemanforderungen

### Raspberry Pi
- Raspberry Pi 4 (empfohlen) oder Pi 3B+
- Raspberry Pi OS (Bullseye oder neuer)
- Bluetooth-Adapter (integriert oder USB)
- Docker und Docker Compose installiert
- Mindestens 2GB RAM

### Windows Computer
- Voicemeeter Banana installiert
- Netzwerkverbindung zum Raspberry Pi

## Installation

### 1. Raspberry Pi vorbereiten

```bash
# System aktualisieren
sudo apt update && sudo apt upgrade -y

# Docker installieren
curl -fsSL https://get.docker.com -o get-docker.sh
sh get-docker.sh
sudo usermod -aG docker $USER

# Docker Compose installieren
sudo apt install docker-compose -y

# Bluetooth-Tools installieren (für Host-System)
sudo apt install bluetooth bluez bluez-tools -y

# Neustart
sudo reboot
```

### 2. Projekt Setup

```bash
# Projektverzeichnis erstellen
mkdir vban-bluetooth-bridge
cd vban-bluetooth-bridge

# Alle Dateien erstellen (siehe Artifacts)
# - Dockerfile
# - docker-compose.yml
# - pulse-daemon.conf
# - pulse-default.pa
# - bluetooth-setup.sh
# - vban-bridge.sh
# - start.sh
```

### 3. Konfiguration anpassen

Bearbeiten Sie die `docker-compose.yml` und setzen Sie die IP-Adresse Ihres Windows-Computers:

```yaml
environment:
  - VBAN_TARGET_IP=192.168.1.100  # Ihre Windows-Computer IP
```

### 4. Container erstellen und starten

```bash
# Container builden
docker-compose build

# Container starten
docker-compose up -d

# Logs verfolgen
docker-compose logs -f
```

## Voicemeeter Banana Setup

### 1. VBAN konfigurieren

1. Öffnen Sie Voicemeeter Banana
2. Gehen Sie zu "Menu" → "VBAN"
3. Fügen Sie einen neuen Incoming Stream hinzu:
   - **Name**: RaspberryPi
   - **IP**: IP-Adresse Ihres Raspberry Pi
   - **Port**: 6980
   - **Quality**: 44100Hz, 2 Channels

### 2. Audio-Routing einrichten

1. Weisen Sie den VBAN-Input einem Voicemeeter-Eingang zu
2. Routen Sie diesen zu Ihren gewünschten Ausgängen
3. Konfigurieren Sie weitere Routing-Regeln nach Bedarf

## Bluetooth-Geräte verbinden

### 1. Automatisches Pairing

Der Container ist für automatisches Pairing konfiguriert:

1. Setzen Sie Ihr Audio-Gerät in Pairing-Modus
2. Der Raspberry Pi sollte automatisch verbinden
3. Prüfen Sie die Container-Logs für Verbindungsdetails

### 2. Manuelles Pairing

```bash
# In den Container einloggen
docker exec -it vban-bluetooth-bridge bash

# Bluetooth-Kommandos
bluetoothctl
scan on
pair [MAC-ADDRESS]
trust [MAC-ADDRESS]
connect [MAC-ADDRESS]
```

## Fehlerbehebung

### Container-Status prüfen
```bash
docker-compose ps
docker-compose logs vban-audio-bridge
```

### Audio-System debugging
```bash
# In Container einloggen
docker exec -it vban-bluetooth-bridge bash

# PulseAudio Status
pulseaudio --check
pactl list short sinks
pactl list short sources

# Bluetooth Status
bluetoothctl devices
bluetoothctl devices Connected
```

### Netzwerk-Connectivity testen
```bash
# Vom Raspberry Pi zum Windows-Computer
ping [WINDOWS-IP]

# VBAN-Port testen (vom Windows-Computer)
telnet [RASPBERRY-PI-IP] 6980
```

### Häufige Probleme

**Audio ruckelt oder bricht ab:**
- Erhöhen Sie `BUFFER_SIZE` in docker-compose.yml
- Prüfen Sie die Netzwerk-Latenz
- Reduzieren Sie andere Netzwerk-Traffic

**Bluetooth verbindet nicht:**
- Starten Sie den Container neu: `docker-compose restart`
- Prüfen Sie Bluetooth-Hardware: `hciconfig`
- Überprüfen Sie die Container-Logs

**VBAN Stream erreicht Voicemeeter nicht:**
- Prüfen Sie die IP-Konfiguration
- Stellen Sie sicher, dass Port 6980/UDP offen ist
- Testen Sie die Verbindung mit anderen VBAN-Tools

## Erweiterte Konfiguration

### Audio-Qualität anpassen

```yaml
environment:
  - SAMPLE_RATE=48000  # Höhere Qualität
  - BUFFER_SIZE=512    # Niedrigere Latenz
```

### Mehrere VBAN-Streams

Für mehrere Ziele können Sie zusätzliche Container oder mehrere vban_emitter-Prozesse konfigurieren.

### Performance-Optimierung

- Verwenden Sie eine kabelgebundene Netzwerkverbindung
- Optimieren Sie den Raspberry Pi für Audio-Performance
- Verwenden Sie QoS für Audio-Pakete im Netzwerk

## Automatischer Start

Der Container startet automatisch mit `restart: unless-stopped`. Für System-Boot-Autostart:

```bash
# Docker beim Boot starten
sudo systemctl enable docker

# Container automatisch starten
docker-compose up -d
```

## Lizenz und Credits

- VBAN: © VB-Audio Software
- Diese Konfiguration: Open Source / MIT Lizenz

Bei Problemen oder Fragen erstellen Sie ein Issue im entsprechenden Repository.