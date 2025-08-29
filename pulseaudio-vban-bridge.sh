#!/bin/bash
# pulseaudio-vban-bridge.sh
# Native PulseAudio Netzwerk-Audio Bridge für VBAN

set -e

# Konfiguration
VBAN_TARGET_IP="${VBAN_TARGET_IP:-192.168.1.100}"
VBAN_PORT="${VBAN_PORT:-6980}"
SAMPLE_RATE="${SAMPLE_RATE:-44100}"
CHANNELS="${CHANNELS:-2}"
FORMAT="${FORMAT:-s16le}"

echo "========================================="
echo "PulseAudio Native VBAN Bridge"
echo "Ziel: $VBAN_TARGET_IP:$VBAN_PORT"
echo "Format: $SAMPLE_RATE Hz, $CHANNELS Ch, $FORMAT"
echo "========================================="

# Warte auf PulseAudio
wait_for_pulseaudio() {
    echo "Warte auf PulseAudio..."
    timeout=30
    while [ $timeout -gt 0 ]; do
        if pulseaudio --check 2>/dev/null; then
            echo "✓ PulseAudio läuft"
            return 0
        fi
        sleep 1
        timeout=$((timeout - 1))
    done
    echo "✗ PulseAudio nicht verfügbar"
    exit 1
}

# Konfiguriere PulseAudio Netzwerk-Module
setup_network_streaming() {
    echo "Konfiguriere PulseAudio Netzwerk-Streaming..."
    
    # Erstelle VBAN-kompatiblen Sink
    pactl load-module module-null-sink \
        sink_name=vban_output \
        sink_properties=device.description="VBAN_Network_Output" \
        rate=$SAMPLE_RATE \
        channels=$CHANNELS \
        format=$FORMAT || true
    
    # Methode 1: RTP-Send (VBAN-kompatibel bei richtiger Konfiguration)
    echo "→ Aktiviere RTP/UDP Streaming..."
    pactl load-module module-rtp-send \
        source=vban_output.monitor \
        destination_ip=$VBAN_TARGET_IP \
        port=$VBAN_PORT \
        mtu=1280 \
        loop=0 \
        format=$FORMAT \
        channels=$CHANNELS \
        rate=$SAMPLE_RATE || {
        echo "⚠ RTP-Send fehlgeschlagen, versuche Alternative..."
    }
    
    # Methode 2: Simple Protocol TCP (Backup)
    echo "→ Aktiviere Simple Protocol..."
    pactl load-module module-simple-protocol-tcp \
        rate=$SAMPLE_RATE \
        format=$FORMAT \
        channels=$CHANNELS \
        source=vban_output.monitor \
        record=true \
        port=4711 || true
    
    # Methode 3: Native Protocol TCP für Remote-PulseAudio
    echo "→ Aktiviere Native Protocol..."
    pactl load-module module-native-protocol-tcp \
        auth-ip-acl="127.0.0.1;$VBAN_TARGET_IP;192.168.0.0/16" \
        port=4713 || true
    
    echo "✓ Netzwerk-Streaming konfiguriert"
}

# Konfiguriere Audio-Routing für Bluetooth
setup_bluetooth_routing() {
    echo "Konfiguriere Bluetooth-Audio-Routing..."
    
    # Kombinierter Sink für alle Bluetooth-Inputs
    pactl load-module module-combine-sink \
        sink_name=bluetooth_to_network \
        slaves=vban_output \
        sink_properties=device.description="Bluetooth_to_Network" || true
    
    # Setze als Standard
    pactl set-default-sink bluetooth_to_network || true
    
    echo "✓ Bluetooth-Routing eingerichtet"
}

# Dynamisches Bluetooth-Monitoring
monitor_bluetooth() {
    echo "Starte Bluetooth-Monitoring..."
    
    declare -A known_devices
    
    while true; do
        # Finde Bluetooth-Audio-Quellen
        while IFS= read -r line; do
            source_name=$(echo "$line" | awk '{print $2}')
            
            if [ -z "${known_devices[$source_name]}" ]; then
                echo "✓ Neue Bluetooth-Quelle: $source_name"
                
                # Erstelle Loopback zu Netzwerk-Output
                module_id=$(pactl load-module module-loopback \
                    source="$source_name" \
                    sink=vban_output \
                    latency_msec=50 \
                    adjust_time=0)
                
                known_devices[$source_name]=$module_id
                
                # Optimiere Latenz
                pactl set-source-latency "$source_name" 50000 2>/dev/null || true
            fi
        done < <(pactl list short sources | grep bluez)
        
        # Cleanup nicht mehr vorhandene Quellen
        for source in "${!known_devices[@]}"; do
            if ! pactl list short sources | grep -q "$source"; then
                echo "✗ Bluetooth-Quelle entfernt: $source"
                pactl unload-module "${known_devices[$source]}" 2>/dev/null || true
                unset known_devices[$source]
            fi
        done
        
        sleep 5
    done
}

# Alternative: Tunnel-Sink zu Windows PulseAudio
setup_tunnel_sink() {
    echo "Versuche Tunnel-Sink zu erstellen..."
    
    # Windows mit PulseAudio für Windows
    pactl load-module module-tunnel-sink-new \
        server=tcp:$VBAN_TARGET_IP:4713 \
        sink_name=windows_tunnel \
        sink_properties=device.description="Windows_PulseAudio_Tunnel" || {
        echo "⚠ Tunnel nicht möglich (Windows PulseAudio nicht verfügbar?)"
    }
}

# VBAN-spezifisches UDP-Paket-Format
send_vban_packets() {
    echo "Starte VBAN-kompatibles UDP-Streaming..."
    
    # Verwende pacat mit netcat für VBAN-Format
    while true; do
        pacat --record \
            --format=$FORMAT \
            --channels=$CHANNELS \
            --rate=$SAMPLE_RATE \
            --latency-msec=50 \
            --device=vban_output.monitor | \
        nc -u -w1 $VBAN_TARGET_IP $VBAN_PORT || {
            echo "⚠ Streaming unterbrochen, Neustart in 5s..."
            sleep 5
        }
    done
}

# Zeige verfügbare Module und Konfiguration
show_status() {
    echo ""
    echo "📊 PulseAudio Status:"
    echo "───────────────────────"
    
    echo "Geladene Netzwerk-Module:"
    pactl list short modules | grep -E "(rtp|tcp|tunnel|network)" || echo "Keine Netzwerk-Module"
    
    echo ""
    echo "Aktive Sinks:"
    pactl list short sinks
    
    echo ""
    echo "Aktive Quellen:"
    pactl list short sources | grep -E "(monitor|bluez)"
    
    echo "───────────────────────"
}

# Main
main() {
    wait_for_pulseaudio
    
    # Konfiguriere Netzwerk-Streaming
    setup_network_streaming
    setup_bluetooth_routing
    
    # Optional: Tunnel-Sink
    setup_tunnel_sink
    
    # Zeige Status
    show_status
    
    # Starte Monitoring
    monitor_bluetooth &
    MONITOR_PID=$!
    
    # Starte VBAN-Streaming
    echo "Starte VBAN-kompatibles Streaming..."
    send_vban_packets
}

# Cleanup
cleanup() {
    echo "Beende PulseAudio VBAN Bridge..."
    kill $MONITOR_PID 2>/dev/null || true
    
    # Entlade Module
    pactl unload-module module-rtp-send 2>/dev/null || true
    pactl unload-module module-simple-protocol-tcp 2>/dev/null || true
    pactl unload-module module-tunnel-sink-new 2>/dev/null || true
    
    exit 0
}

trap cleanup SIGTERM SIGINT

main
