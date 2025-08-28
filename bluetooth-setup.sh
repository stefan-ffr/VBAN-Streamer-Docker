#!/bin/bash
# bluetooth-setup.sh
# Bluetooth Konfiguration als Audio Sink (Lautsprecher-Modus)

set -e

echo "Bluetooth Speaker Setup wird gestartet..."

# D-Bus starten (falls noch nicht aktiv)
service dbus start 2>/dev/null || true
sleep 1

# Bluetooth Service starten
service bluetooth start
sleep 2

# Bluetooth Konfiguration für A2DP Sink
setup_bluetooth_speaker() {
    echo "Konfiguriere Bluetooth als Audio-Sink..."
    
    # Bluetooth Controller einschalten
    bluetoothctl << EOF
power on
agent on
default-agent
discoverable on
pairable on
EOF
    
    sleep 2
    
    # Device Name setzen
    DEVICE_NAME="${BT_DEVICE_NAME:-VBAN-Speaker}"
    echo "Setze Bluetooth-Name auf: $DEVICE_NAME"
    bluetoothctl system-alias "$DEVICE_NAME"
    
    # Class of Device auf Audio setzen (Lautsprecher)
    hciconfig hci0 class 0x200414
}

# Automatisches Pairing und Verbindungsmanagement
setup_auto_pairing() {
    echo "Starte automatisches Pairing..."
    
    # Bluetooth Agent mit automatischem Accept
    expect -c '
    set timeout -1
    spawn bluetoothctl
    expect "Agent registered"
    
    # Auto-Accept für alle Pairing-Requests
    expect {
        "Confirm passkey*" { send "yes\r"; exp_continue }
        "Accept pairing*" { send "yes\r"; exp_continue }
        "Authorize service*" { send "yes\r"; exp_continue }
        "Request PIN code*" { send "0000\r"; exp_continue }
        "*#*" { exp_continue }
        eof
    }
    ' &
    
    AGENT_PID=$!
    echo "Bluetooth Agent gestartet (PID: $AGENT_PID)"
}

# Überwachung neuer Bluetooth-Verbindungen
monitor_connections() {
    echo "Starte Verbindungsüberwachung..."
    
    while true; do
        # Prüfe auf verbundene Audio-Geräte
        connected_devices=$(bluetoothctl devices Connected 2>/dev/null | wc -l)
        
        if [ "$connected_devices" -gt 0 ]; then
            echo "INFO: $connected_devices Bluetooth-Gerät(e) verbunden"
            
            # Auto-Trust für alle verbundenen Geräte
            bluetoothctl devices Connected | while read -r line; do
                mac=$(echo "$line" | awk '{print $2}')
                if [ ! -z "$mac" ]; then
                    bluetoothctl trust "$mac" 2>/dev/null || true
                    echo "Gerät $mac wurde als vertrauenswürdig markiert"
                fi
            done
        fi
        
        # Sicherstellen, dass der Pi sichtbar bleibt
        bluetoothctl discoverable on 2>/dev/null || true
        bluetoothctl pairable on 2>/dev/null || true
        
        sleep 10
    done
}

# A2DP Profile aktivieren
enable_a2dp_sink() {
    echo "Aktiviere A2DP Sink Profile..."
    
    # Stelle sicher, dass A2DP Sink verfügbar ist
    pactl load-module module-bluetooth-discover || true
    
    # Warte auf Bluetooth-Module
    sleep 3
    
    echo "A2DP Sink ist bereit"
}

# Hauptfunktion
main() {
    setup_bluetooth_speaker
    enable_a2dp_sink
    setup_auto_pairing
    
    echo "========================================="
    echo "Bluetooth Speaker ist bereit!"
    echo "Name: ${BT_DEVICE_NAME:-VBAN-Speaker}"
    echo "Geräte können sich jetzt verbinden"
    echo "========================================="
    
    # Überwachung starten
    monitor_connections
}

# Signal Handler
cleanup() {
    echo "Beende Bluetooth Speaker Setup..."
    pkill -f expect || true
    pkill -f bluetoothctl || true
    exit 0
}
trap cleanup SIGTERM SIGINT

# Starte Setup
main