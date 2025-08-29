#!/bin/bash
# vban-bridge.sh
# Audio Bridge zwischen PulseAudio und VBAN

set -e

# Konfiguration
VBAN_TARGET_IP="${VBAN_TARGET_IP:-192.168.1.100}"
VBAN_PORT="${VBAN_PORT:-6980}"
VBAN_STREAM_NAME="${VBAN_STREAM_NAME:-RaspberryPi}"
SAMPLE_RATE="${SAMPLE_RATE:-44100}"
BUFFER_SIZE="${BUFFER_SIZE:-1024}"
CHANNELS="${VBAN_CHANNELS:-2}"

echo "VBAN Bridge wird gestartet..."
echo "Ziel-IP: $VBAN_TARGET_IP"
echo "Port: $VBAN_PORT"
echo "Stream Name: $VBAN_STREAM_NAME"
echo "Sample Rate: $SAMPLE_RATE Hz"

# Warte bis PulseAudio bereit ist
wait_for_pulseaudio() {
    echo "Warte auf PulseAudio..."
    timeout=30
    while [ $timeout -gt 0 ]; do
        if pulseaudio --check 2>/dev/null; then
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
    
    # Warte bis vban_out sink existiert
    timeout=10
    while [ $timeout -gt 0 ]; do
        if pactl list short sinks | grep -q vban_out; then
            break
        fi
        sleep 1
        timeout=$((timeout - 1))
    done
    
    # Alle Bluetooth Audio-Inputs zu VBAN weiterleiten
    pactl list short sources | grep bluez 2>/dev/null | while read -r line; do
        source_name=$(echo "$line" | awk '{print $2}')
        echo "Verbinde Bluetooth Source: $source_name -> vban_out"
        pactl load-module module-loopback source="$source_name" sink="vban_out" latency_msec=50 || true
    done
    
    echo "Audio-Routing eingerichtet"
}

# VBAN Sender starten mit korrekten Parametern
start_vban_sender() {
    echo "Starte VBAN Sender..."
    
    # Erstelle PulseAudio Monitor für VBAN output
    SOURCE="vban_out.monitor"
    
    # Warte bis Monitor verfügbar ist
    timeout=10
    while [ $timeout -gt 0 ]; do
        if pactl list short sources | grep -q "$SOURCE"; then
            break
        fi
        sleep 1
        timeout=$((timeout - 1))
    done
    
    # VBAN Sender mit kontinuierlichem Neustart
    while true; do
        echo "Starte VBAN Stream: $SOURCE -> $VBAN_TARGET_IP:$VBAN_PORT"
        
        # Verwende parec mit vban_emitter für Audio-Streaming
        parec --format=s16le --channels=$CHANNELS --rate=$SAMPLE_RATE --latency-msec=50 -d "$SOURCE" | \
            vban_emitter -i - -p "$VBAN_PORT" -s "$VBAN_STREAM_NAME" -r "$SAMPLE_RATE" -n $CHANNELS -c 1 "$VBAN_TARGET_IP" || {
            echo "VBAN Sender gestoppt, starte in 5 Sekunden neu..."
            sleep 5
        }
    done
}

# Alternative: Direkte PulseAudio zu UDP Streaming (VBAN-kompatibel)
start_direct_streaming() {
    echo "Starte direktes Audio-Streaming..."
    
    while true; do
        # Verwende gstreamer für VBAN-kompatibles Streaming
        gst-launch-1.0 -v \
            pulsesrc device="vban_out.monitor" ! \
            audioconvert ! \
            audioresample ! \
            audio/x-raw,format=S16LE,channels=$CHANNELS,rate=$SAMPLE_RATE ! \
            udpsink host="$VBAN_TARGET_IP" port="$VBAN_PORT" sync=false || {
            echo "Streaming gestoppt, starte in 5 Sekunden neu..."
            sleep 5
        }
    done
}

# Bluetooth-Verbindungen überwachen und dynamisch routen
monitor_bluetooth_connections() {
    echo "Starte Bluetooth-Monitoring..."
    
    while true; do
        # Prüfe auf neue Bluetooth-Verbindungen
        pactl list short sources | grep bluez 2>/dev/null | while read -r line; do
            source_name=$(echo "$line" | awk '{print $2}')
            
            # Prüfe ob bereits eine Loopback für diese Source existiert
            if ! pactl list short modules | grep -q "source=$source_name.*sink=vban_out"; then
                echo "Neue Bluetooth-Verbindung gefunden: $source_name"
                pactl load-module module-loopback source="$source_name" sink="vban_out" latency_msec=50 || true
            fi
        done
        
        sleep 5
    done
}

# Main Function
main() {
    wait_for_pulseaudio
    
    # Audio-Routing initial einrichten
    setup_audio_routing
    
    # Bluetooth-Monitoring in Background starten
    monitor_bluetooth_connections &
    MONITOR_PID=$!
    
    # VBAN Sender starten
    if command -v vban_emitter > /dev/null 2>&1; then
        start_vban_sender
    elif command -v gst-launch-1.0 > /dev/null 2>&1; then
        echo "VBAN Tools nicht gefunden, verwende GStreamer..."
        start_direct_streaming
    else
        echo "Fehler: Weder VBAN Tools noch GStreamer gefunden!"
        exit 1
    fi
}

# Signal Handler für sauberes Herunterfahren
cleanup() {
    echo "Beende VBAN Bridge..."
    kill $MONITOR_PID 2>/dev/null || true
    pkill -f vban_emitter || true
    pkill -f gst-launch || true
    pkill -f parec || true
    exit 0
}

trap cleanup SIGTERM SIGINT

# Starte Bridge
main
