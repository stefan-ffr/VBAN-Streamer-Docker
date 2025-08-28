#!/bin/bash
# vban-bridge.sh
# Audio Bridge zwischen PulseAudio und VBAN

set -e

# Konfiguration
VBAN_TARGET_IP="${VBAN_TARGET_IP:-192.168.1.100}"  # IP des Computers mit Voicemeeter
VBAN_PORT="${VBAN_PORT:-6980}"
VBAN_STREAM_NAME="${VBAN_STREAM_NAME:-RaspberryPi}"
SAMPLE_RATE="${SAMPLE_RATE:-44100}"
BUFFER_SIZE="${BUFFER_SIZE:-1024}"

echo "VBAN Bridge wird gestartet..."
echo "Ziel-IP: $VBAN_TARGET_IP"
echo "Port: $VBAN_PORT"
echo "Stream Name: $VBAN_STREAM_NAME"

# Warte bis PulseAudio bereit ist
wait_for_pulseaudio() {
    echo "Warte auf PulseAudio..."
    timeout=30
    while [ $timeout -gt 0 ]; do
        if pulseaudio --check; then
            echo "PulseAudio ist bereit"
            return 0
        fi
        sleep 1
        timeout=$((timeout - 1))
    done
    echo "Fehler: PulseAudio konnte nicht gestartet werden"
    exit 1
}

# Audio-Routing einrichten
setup_audio_routing() {
    echo "Richte Audio-Routing ein..."
    
    # Warte auf Bluetooth-Verbindungen
    sleep 5
    
    # Alle Bluetooth Audio-Inputs zu VBAN weiterleiten
    pactl list short sources | grep bluez | while read -r line; do
        source_name=$(echo "$line" | awk '{print $2}')
        echo "Verbinde Bluetooth Source: $source_name -> vban_out"
        pactl load-module module-loopback source="$source_name" sink="vban_out" || true
    done
    
    # Standard Input zu VBAN weiterleiten
    pactl load-module module-loopback source="auto_null.monitor" sink="vban_out" || true
    
    echo "Audio-Routing eingerichtet"
}

# VBAN Sender starten
start_vban_sender() {
    echo "Starte VBAN Sender..."
    
    # Monitor des vban_out Sinks verwenden
    SOURCE="vban_out.monitor"
    
    # VBAN Sender mit kontinuierlichem Neustart
    while true; do
        echo "Starte VBAN Stream: $SOURCE -> $VBAN_TARGET_IP:$VBAN_PORT"
        
        # VBAN Command (angepasst für Linux Version)
        /opt/vban_emitter -i "$SOURCE" -p "$VBAN_PORT" -r "$SAMPLE_RATE" -c 2 -f 1 -b "$BUFFER_SIZE" -n "$VBAN_STREAM_NAME" "$VBAN_TARGET_IP" || {
            echo "VBAN Sender gestoppt, starte in 5 Sekunden neu..."
            sleep 5
        }
    done
}

# Alternative: GStreamer VBAN Pipeline (falls VBAN Tools nicht verfügbar)
start_gstreamer_vban() {
    echo "Starte GStreamer VBAN Pipeline..."
    
    gst-launch-1.0 -v \
        pulsesrc device="vban_out.monitor" ! \
        audioconvert ! \
        audioresample ! \
        audio/x-raw,format=S16LE,channels=2,rate="$SAMPLE_RATE" ! \
        udpsink host="$VBAN_TARGET_IP" port="$VBAN_PORT"
}

# Main Function
main() {
    wait_for_pulseaudio
    
    # Audio-Routing in Background einrichten
    setup_audio_routing &
    
    # VBAN Sender starten
    if command -v /opt/vban_emitter > /dev/null 2>&1; then
        start_vban_sender
    else
        echo "VBAN Tools nicht gefunden, verwende GStreamer..."
        start_gstreamer_vban
    fi
}

# Signal Handler für sauberes Herunterfahren
cleanup() {
    echo "Beende VBAN Bridge..."
    pkill -f vban_emitter || true
    pkill -f gst-launch || true
    exit 0
}

trap cleanup SIGTERM SIGINT

# Starte Bridge
main