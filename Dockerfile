# Dockerfile - Funktionierende Version mit allen Scripts inline
FROM debian:bullseye-slim

# Basis-Pakete installieren
RUN apt-get update && apt-get install -y \
    pulseaudio \
    pulseaudio-module-bluetooth \
    pulseaudio-utils \
    bluetooth \
    bluez \
    bluez-tools \
    dbus \
    alsa-utils \
    netcat-openbsd \
    expect \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/*

# PulseAudio Konfigurationsdateien erstellen
RUN mkdir -p /etc/pulse

# pulse-daemon.conf erstellen
COPY pulse-daemon.conf /etc/pulse/daemon.conf

# pulse-default.pa erstellen  
COPY pulse-default.pa /etc/pulse/default.pa

# Bluetooth Setup Script erstellen (inline, da COPY fehlschlägt wenn Datei nicht existiert)
RUN cat > /usr/local/bin/bluetooth-setup.sh << 'SCRIPT_END' && chmod +x /usr/local/bin/bluetooth-setup.sh
#!/bin/bash
set -e

echo "Bluetooth Speaker Setup wird gestartet..."

# D-Bus starten
service dbus start 2>/dev/null || true
sleep 1

# Bluetooth Service starten
service bluetooth start
sleep 2

# Bluetooth konfigurieren
bluetoothctl << EOF
power on
agent on
default-agent
discoverable on
pairable on
EOF

# Device Name setzen
DEVICE_NAME="${BT_DEVICE_NAME:-VBAN-Speaker}"
echo "Setze Bluetooth-Name auf: $DEVICE_NAME"
bluetoothctl system-alias "$DEVICE_NAME"

# Class auf Audio setzen
hciconfig hci0 class 0x200414 2>/dev/null || true

echo "Bluetooth Speaker ist bereit!"

# Halte Bluetooth aktiv
while true; do
    bluetoothctl discoverable on 2>/dev/null || true
    bluetoothctl pairable on 2>/dev/null || true
    
    # Zeige verbundene Geräte
    connected=$(bluetoothctl devices Connected 2>/dev/null | wc -l)
    if [ "$connected" -gt 0 ]; then
        echo "[$connected] Bluetooth-Gerät(e) verbunden"
    fi
    
    sleep 30
done
SCRIPT_END

# Start Script erstellen
RUN cat > /usr/local/bin/start.sh << 'SCRIPT_END' && chmod +x /usr/local/bin/start.sh
#!/bin/bash
set -e

echo "========================================="
echo "VBAN Bluetooth Audio Bridge"
echo "========================================="
echo "Target IP: ${VBAN_TARGET_IP:-192.168.1.100}"
echo "Port: ${VBAN_PORT:-6980}"
echo "BT Name: ${BT_DEVICE_NAME:-VBAN-Speaker}"
echo "========================================="

# Cleanup bei Beendigung
cleanup() {
    echo "Shutting down..."
    pkill -f pulseaudio || true
    pkill -f bluetoothd || true
    pkill -f netcat || true
    exit 0
}
trap cleanup SIGTERM SIGINT

# D-Bus starten
service dbus start
sleep 1

# PulseAudio starten
echo "Starting PulseAudio..."
pulseaudio --system --disallow-exit --disable-shm --exit-idle-time=-1 &
PULSE_PID=$!
sleep 3

# Prüfe ob PulseAudio läuft
if ! pulseaudio --check; then
    echo "ERROR: PulseAudio failed to start"
    exit 1
fi

# Erstelle VBAN Output Sink
pactl load-module module-null-sink sink_name=vban_out sink_properties=device.description="VBAN_Output" rate=44100 channels=2 format=s16le || true

# Bluetooth Setup im Hintergrund
/usr/local/bin/bluetooth-setup.sh &

# Audio-Streaming-Funktion
stream_audio() {
    local TARGET_IP="${VBAN_TARGET_IP:-192.168.1.100}"
    local PORT="${VBAN_PORT:-6980}"
    
    echo "Starting audio stream to $TARGET_IP:$PORT"
    
    # Warte bis vban_out verfügbar ist
    while ! pactl list short sinks | grep -q vban_out; do
        echo "Waiting for audio sink..."
        sleep 1
    done
    
    # Erstelle Loopbacks für Bluetooth-Verbindungen
    while true; do
        # Finde Bluetooth-Audio-Quellen und route sie zu vban_out
        pactl list short sources | grep bluez 2>/dev/null | while read -r line; do
            source_name=$(echo "$line" | awk '{print $2}')
            # Prüfe ob Loopback bereits existiert
            if ! pactl list short modules | grep -q "source=$source_name.*sink=vban_out"; then
                echo "Routing Bluetooth audio: $source_name -> vban_out"
                pactl load-module module-loopback source="$source_name" sink=vban_out latency_msec=50 || true
            fi
        done
        
        sleep 5
    done &
    
    # Starte Audio-Streaming mit parec und netcat
    while true; do
        echo "Streaming audio via UDP to $TARGET_IP:$PORT"
        parec --format=s16le --channels=2 --rate=44100 -d vban_out.monitor 2>/dev/null | \
            nc -u -w1 $TARGET_IP $PORT || {
            echo "Stream interrupted, restarting in 5 seconds..."
            sleep 5
        }
    done
}

# Starte Audio-Streaming
stream_audio &

echo "========================================="
echo "System ready!"
echo "Connect Bluetooth devices to: ${BT_DEVICE_NAME:-VBAN-Speaker}"
echo "Audio streams to: ${VBAN_TARGET_IP:-192.168.1.100}:${VBAN_PORT:-6980}"
echo "========================================="

# Halte Container am Laufen
wait
SCRIPT_END

# Setze Berechtigungen für alle Scripts
RUN chmod +x /usr/local/bin/*.sh

# Ports
EXPOSE 6980/udp

# Health Check
HEALTHCHECK --interval=30s --timeout=10s --start-period=60s --retries=3 \
    CMD pulseaudio --check && bluetoothctl show 2>/dev/null | grep -q "Powered: yes" || exit 1

# Start
CMD ["/usr/local/bin/start.sh"]
