#!/bin/bash
# start.sh
# Haupt-Start-Script für VBAN Bluetooth Audio Container

set -e

echo "========================================="
echo "VBAN Bluetooth Audio Bridge wird gestartet"
echo "========================================="

# Umgebungsvariablen setzen
export PULSE_SERVER="unix:/tmp/pulse-socket"
export PULSE_RUNTIME_PATH="/tmp"

# Signal Handler für sauberes Herunterfahren
cleanup() {
    echo "Container wird heruntergefahren..."
    pkill -f pulseaudio || true
    pkill -f bluetoothd || true
    pkill -f vban || true
    exit 0
}
trap cleanup SIGTERM SIGINT

# DBus für Bluetooth starten
echo "Starte D-Bus..."
service dbus start
sleep 1

# PulseAudio als System-Service starten
echo "Starte PulseAudio..."
pulseaudio --system --disallow-exit --disable-shm --exit-idle-time=-1 &
sleep 3

# Prüfe ob PulseAudio läuft
if ! pulseaudio --check; then
    echo "Fehler: PulseAudio konnte nicht gestartet werden"
    exit 1
fi

# Bluetooth Setup starten
echo "Starte Bluetooth Setup..."
/usr/local/bin/bluetooth-setup.sh &
sleep 2

# VBAN Bridge starten
echo "Starte VBAN Bridge..."
/usr/local/bin/vban-bridge.sh &

echo "========================================="
echo "Alle Services gestartet!"
echo "Container ist bereit für Bluetooth-Pairing"
echo "VBAN Stream wird an ${VBAN_TARGET_IP:-'Standard-IP'} gesendet"
echo "========================================="

# Status-Monitoring
monitor_services() {
    while true; do
        # Service Status prüfen
        if ! pulseaudio --check; then
            echo "WARNUNG: PulseAudio ist gestoppt"
        fi
        
        if ! pgrep bluetoothd > /dev/null; then
            echo "WARNUNG: Bluetooth Service ist gestoppt"
        fi
        
        # Bluetooth Geräte anzeigen
        connected_devices=$(bluetoothctl devices Connected 2>/dev/null | wc -l)
        if [ "$connected_devices" -gt 0 ]; then
            echo "INFO: $connected_devices Bluetooth-Gerät(e) verbunden"
            bluetoothctl devices Connected
        fi
        
        sleep 30
    done
}

# Monitoring in Background starten
monitor_services &

# Warte auf Signale (Container läuft bis SIGTERM)
wait