#!/bin/bash
# quick-setup.sh
# Schnelles Setup für VBAN Bluetooth Speaker

set -e

# Farben für bessere Ausgabe
RED='\033[0;31m'
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Banner anzeigen
echo -e "${BLUE}"
cat << 'EOF'
╔══════════════════════════════════════════════════════════╗
║                 VBAN Bluetooth Speaker                  ║
║            Raspberry Pi Setup Script                    ║
╚══════════════════════════════════════════════════════════╝
EOF
echo -e "${NC}"

# Systemcheck
echo -e "${YELLOW}🔍 Führe Systemprüfungen durch...${NC}"

# Raspberry Pi Check
if ! grep -q "Raspberry Pi" /proc/cpuinfo 2>/dev/null; then
    echo -e "${YELLOW}⚠️  Warning: Dieses Script ist für Raspberry Pi optimiert${NC}"
fi

# Docker Check
if ! command -v docker &> /dev/null; then
    echo -e "${RED}❌ Error: Docker ist nicht installiert!${NC}"
    echo -e "${BLUE}📥 Installiere Docker mit:${NC}"
    echo "   curl -fsSL https://get.docker.com -o get-docker.sh && sh get-docker.sh"
    echo "   sudo usermod -aG docker \$USER"
    echo "   sudo reboot"
    exit 1
fi

# Docker-Compose Check
if ! command -v docker-compose &> /dev/null; then
    echo -e "${YELLOW}⚠️  Docker Compose nicht gefunden, installiere...${NC}"
    sudo apt update && sudo apt install -y docker-compose
fi

# Bluetooth Check
if ! command -v bluetoothctl &> /dev/null; then
    echo -e "${YELLOW}⚠️  Bluetooth-Tools nicht gefunden, installiere...${NC}"
    sudo apt update && sudo apt install -y bluetooth bluez bluez-tools
fi

echo -e "${GREEN}✅ Systemprüfungen abgeschlossen${NC}"

# Konfiguration abfragen
echo -e "\n${BLUE}⚙️  Konfiguration${NC}"

# Standard Container Image
DEFAULT_IMAGE="ghcr.io/USERNAME/REPOSITORY:latest"
read -p "Container Image [$DEFAULT_IMAGE]: " CONTAINER_IMAGE
CONTAINER_IMAGE=${CONTAINER_IMAGE:-$DEFAULT_IMAGE}

# VBAN Target IP
while true; do
    read -p "IP-Adresse des Computers mit Voicemeeter Banana: " TARGET_IP
    if [[ $TARGET_IP =~ ^[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}$ ]]; then
        break
    else
        echo -e "${RED}❌ Ungültige IP-Adresse. Bitte versuche es erneut.${NC}"
    fi
done

# Bluetooth Gerätename
DEFAULT_BT_NAME="VBAN-Speaker"
read -p "Bluetooth-Gerätename [$DEFAULT_BT_NAME]: " BT_NAME
BT_NAME=${BT_NAME:-$DEFAULT_BT_NAME}

# Audio-Qualität
echo -e "\n${BLUE}🎵 Audio-Qualität:${NC}"
echo "1) Standard (44.1kHz, 1024 Buffer)"
echo "2) Hoch (48kHz, 512 Buffer)"
echo "3) Maximum (48kHz, 256 Buffer)"
read -p "Auswahl [1]: " QUALITY
QUALITY=${QUALITY:-1}

case $QUALITY in
    1)
        SAMPLE_RATE=44100
        BUFFER_SIZE=1024
        ;;
    2)
        SAMPLE_RATE=48000
        BUFFER_SIZE=512
        ;;
    3)
        SAMPLE_RATE=48000
        BUFFER_SIZE=256
        ;;
    *)
        SAMPLE_RATE=44100
        BUFFER_SIZE=1024
        ;;
esac

echo -e "\n${GREEN}📝 Konfiguration:${NC}"
echo "  Container: $CONTAINER_IMAGE"
echo "  Ziel-IP: $TARGET_IP"
echo "  BT-Name: $BT_NAME"
echo "  Audio: ${SAMPLE_RATE}Hz, Buffer: $BUFFER_SIZE"
echo ""

# Bestätigung
read -p "Installation starten? [y/N]: " CONFIRM
if [[ ! $CONFIRM =~ ^[Yy]$ ]]; then
    echo -e "${YELLOW}❌ Installation abgebrochen${NC}"
    exit 0
fi

# Container stoppen falls läuft
echo -e "\n${YELLOW}🛑 Stoppe eventuell laufende Container...${NC}"
docker stop vban-bluetooth-speaker 2>/dev/null || true
docker rm vban-bluetooth-speaker 2>/dev/null || true

# Container starten
echo -e "\n${BLUE}🚀 Starte VBAN Bluetooth Speaker Container...${NC}"
docker run -d \
  --name vban-bluetooth-speaker \
  --privileged \
  --network host \
  -e VBAN_TARGET_IP="$TARGET_IP" \
  -e BT_DEVICE_NAME="$BT_NAME" \
  -e SAMPLE_RATE="$SAMPLE_RATE" \
  -e BUFFER_SIZE="$BUFFER_SIZE" \
  -v /var/run/dbus:/var/run/dbus \
  -v /sys/fs/cgroup:/sys/fs/cgroup:rw \
  --restart unless-stopped \
  "$CONTAINER_IMAGE"

# Status prüfen
sleep 5
if docker ps | grep -q vban-bluetooth-speaker; then
    echo -e "\n${GREEN}🎉 Container erfolgreich gestartet!${NC}"
else
    echo -e "\n${RED}❌ Fehler beim Starten des Containers${NC}"
    echo -e "${YELLOW}📋 Container-Logs:${NC}"
    docker logs vban-bluetooth-speaker
    exit 1
fi

# Status-Informationen
echo -e "\n${GREEN}✅ Setup abgeschlossen!${NC}"
echo -e "\n${BLUE}📱 Bluetooth-Verbindung:${NC}"
echo "  1. Bluetooth-Scanner auf deinem Gerät öffnen"
echo "  2. '$BT_NAME' suchen und verbinden"
echo "  3. Audio abspielen - wird zu Voicemeeter weitergeleitet"

echo -e "\n${BLUE}🎛️  Voicemeeter Banana Setup:${NC}"
echo "  1. Menu → VBAN → Incoming Stream hinzufügen"
echo "  2. Name: RaspberryPi"
echo "  3. IP: $(hostname -I | awk '{print $1}')"
echo "  4. Port: 6980"
echo "  5. Quality: ${SAMPLE_RATE}Hz, 2 Channels"

echo -e "\n${BLUE}🔧 Nützliche Befehle:${NC}"
echo "  Status prüfen:    docker logs vban-bluetooth-speaker -f"
echo "  Container stoppen: docker stop vban-bluetooth-speaker"
echo "  Neustart:         docker restart vban-bluetooth-speaker"

echo -e "\n${BLUE}🌐 Container-Informationen:${NC}"
echo "  Image: $CONTAINER_IMAGE"
echo "  Status: $(docker inspect vban-bluetooth-speaker --format='{{.State.Status}}')"
echo "  Started: $(docker inspect vban-bluetooth-speaker --format='{{.State.StartedAt}}')"

# Optional: Logs anzeigen
read -p "Container-Logs anzeigen? [y/N]: " SHOW_LOGS
if [[ $SHOW_LOGS =~ ^[Yy]$ ]]; then
    echo -e "\n${BLUE}📋 Container-Logs (Ctrl+C zum Beenden):${NC}"
    docker logs vban-bluetooth-speaker -f
fi

echo -e "\n${GREEN}🎵 Happy Audio Streaming! 🎵${NC}"