# VBAN Bluetooth Audio Bridge

[![Build and Publish](https://github.com/USERNAME/REPOSITORY/actions/workflows/build-and-publish.yml/badge.svg)](https://github.com/USERNAME/REPOSITORY/actions/workflows/build-and-publish.yml)
[![Docker Pulls](https://img.shields.io/docker/pulls/ghcr.io/USERNAME/REPOSITORY)](https://github.com/USERNAME/REPOSITORY/pkgs/container/REPOSITORY)
[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)

Ein Docker-Container, der einen Raspberry Pi in einen Bluetooth-Lautsprecher verwandelt und empfangenes Audio über VBAN an Voicemeeter Banana weiterleitet.

## 🎯 Features

- **Bluetooth-Lautsprecher**: Der Raspberry Pi wird als "VBAN-Speaker" sichtbar
- **Automatisches Pairing**: Geräte verbinden sich automatisch ohne PIN
- **VBAN-Streaming**: Audio wird in Echtzeit über Netzwerk übertragen  
- **Multi-Architecture**: Läuft auf ARM64, ARM/v7 und AMD64
- **Auto-Recovery**: Automatische Wiederherstellung bei Verbindungsabbrüchen
- **Plug & Play**: Minimale Konfiguration erforderlich

## 🚀 Schnellstart

### Mit Docker Run (Empfohlen)

```bash
docker run -d \
  --name vban-bluetooth-speaker \
  --privileged \
  --network host \
  -e VBAN_TARGET_IP="192.168.1.100" \
  -e BT_DEVICE_NAME="VBAN-Speaker" \
  -v /var/run/dbus:/var/run/dbus \
  --restart unless-stopped \
  ghcr.io/stefan-ffr/vban-streamer-docker:latest
```

### Mit Docker Compose

1. **Repository klonen oder docker-compose.yml herunterladen**
   ```bash
   curl -O https://raw.githubusercontent.com/stefan-ffr/vban-streamer-docker/main/docker-compose.yml
   ```

2. **Konfiguration anpassen**
   ```bash
   # Setze die IP-Adresse deines Windows-Computers
   sed -i 's/VBAN_TARGET_IP=.*/VBAN_TARGET_IP=192.168.1.100/' docker-compose.yml
   sed -i 's/ghcr.io\/BENUTZERNAME\/REPOSITORY-NAME/ghcr.io\/USERNAME\/REPOSITORY/' docker-compose.yml
   ```

3. **Container starten**
   ```bash
   docker-compose up -d
   ```

## 🔧 Konfiguration

### Umgebungsvariablen

| Variable | Standard | Beschreibung |
|----------|----------|--------------|
| `VBAN_TARGET_IP` | `192.168.1.100` | IP-Adresse des Voicemeeter-Computers |
| `VBAN_PORT` | `6980` | VBAN-Port für Audio-Streaming |
| `VBAN_STREAM_NAME` | `RaspberryPi` | Name des VBAN-Streams |
| `BT_DEVICE_NAME` | `VBAN-Speaker` | Bluetooth-Gerätename |
| `SAMPLE_RATE` | `44100` | Audio-Sample-Rate (Hz) |
| `BUFFER_SIZE` | `1024` | Audio-Puffer-Größe |
| `AUDIO_BITRATE` | `320` | Audio-Bitrate (kbps) |
| `BT_AUTO_ACCEPT` | `true` | Automatisches Bluetooth-Pairing |

### Voicemeeter Banana Setup

1. **VBAN konfigurieren**:
   - Menü → VBAN → Incoming Stream hinzufügen
   - **Name**: `RaspberryPi`
   - **IP**: IP-Adresse des Raspberry Pi
   - **Port**: `6980` (oder deine Konfiguration)
   - **Quality**: `44100Hz, 2 Channels`

2. **Audio-Routing einrichten**:
   - VBAN-Input einem Voicemeeter-Kanal zuweisen
   - Audio zu gewünschten Ausgängen routen

## 📱 Bluetooth-Verbindung

1. **Bluetooth-Scanner öffnen** auf deinem Handy/Computer
2. **"VBAN-Speaker" suchen** und verbinden
3. **Audio abspielen** - wird automatisch an Voicemeeter weitergeleitet

### Unterstützte Geräte
- 📱 Smartphones (Android/iOS)
- 💻 Laptops/PCs mit Bluetooth
- 🎧 Bluetooth-Audio-Quellen
- 🎮 Gaming-Konsolen mit Bluetooth-Audio

## 🖥️ Systemanforderungen

### Raspberry Pi
- **Raspberry Pi 4** (empfohlen) oder Pi 3B+
- **2GB RAM** minimum, 4GB empfohlen
- **Raspberry Pi OS** (Bullseye/Bookworm)
- **Bluetooth-Adapter** (integriert oder USB)
- **Stabile Netzwerkverbindung**

### Windows Computer
- **Voicemeeter Banana** installiert
- **Netzwerk-Verbindung** zum Raspberry Pi
- **Port 6980/UDP** offen (Windows Firewall)

## 🔍 Überwachung & Debugging

### Container-Status prüfen
```bash
# Logs anzeigen
docker logs vban-bluetooth-speaker -f

# Container-Status
docker ps
docker inspect vban-bluetooth-speaker
```

### Audio-System debugging
```bash
# In Container einloggen
docker exec -it vban-bluetooth-speaker bash

# PulseAudio-Status
pulseaudio --check
pactl list short sinks
pactl list short sources

# Bluetooth-Status
bluetoothctl devices
bluetoothctl devices Connected
hciconfig
```

### Netzwerk-Tests
```bash
# VBAN-Verbindung testen
ping 192.168.1.100
nc -u 192.168.1.100 6980

# Port-Status prüfen
netstat -ulnp | grep 6980
```

## 🐛 Problemlösung

### Audio ruckelt oder bricht ab
```bash
# Puffer-Größe erhöhen
docker run ... -e BUFFER_SIZE=2048 ...

# Sample-Rate anpassen
docker run ... -e SAMPLE_RATE=48000 ...
```

### Bluetooth verbindet nicht
```bash
# Container neu starten
docker restart vban-bluetooth-speaker

# Bluetooth-Hardware prüfen
hciconfig hci0 up
systemctl status bluetooth
```

### VBAN erreicht Voicemeeter nicht
```bash
# Windows Firewall prüfen
# Port 6980/UDP öffnen

# IP-Adresse verifizieren  
ipconfig /all

# VBAN-Konfiguration in Voicemeeter prüfen
```

## 🏗️ Entwicklung

### Container lokal bauen
```bash
git clone https://github.com/USERNAME/REPOSITORY.git
cd REPOSITORY
docker build -t vban-bluetooth-speaker .
```

### Multi-Architecture Build
```bash
docker buildx create --use
docker buildx build --platform linux/amd64,linux/arm64,linux/arm/v7 -t vban-bluetooth-speaker .
```

## 🤝 Beitragen

1. **Fork** das Repository
2. **Feature Branch** erstellen (`git checkout -b feature/AmazingFeature`)
3. **Commit** Changes (`git commit -m 'Add some AmazingFeature'`)
4. **Push** to Branch (`git push origin feature/AmazingFeature`)
5. **Pull Request** öffnen

## 📦 GitHub Actions

Automatisches Container-Building:
- ✅ **Multi-Architecture** Support (AMD64, ARM64, ARM/v7)
- ✅ **GitHub Container Registry** Integration  
- ✅ **Sicherheits-Scans** mit Trivy
- ✅ **Automatische Releases** mit Tags
- ✅ **Container-Attestation** für Supply Chain Security

## 📋 Roadmap

- [ ] **Web-Interface** für Container-Management
- [ ] **Codec-Unterstützung** (AAC, aptX, LDAC)
- [ ] **Multi-Client** VBAN-Streaming
- [ ] **Audio-Effekte** Integration
- [ ] **Prometheus-Metriken** Export
- [ ] **Home Assistant** Integration

## 📄 Lizenz

Dieses Projekt ist unter der MIT-Lizenz lizenziert - siehe [LICENSE](LICENSE) Datei für Details.

## 🙏 Danksagungen

- **VB-Audio Software** für VBAN-Protokoll
- **PulseAudio/BlueZ** Communities  
- **Docker/GitHub Actions** für Automatisierung
- **Raspberry Pi Foundation** für großartige Hardware

## 📞 Support

- 🐛 **Issues**: [GitHub Issues](https://github.com/USERNAME/REPOSITORY/issues)
- 💬 **Discussions**: [GitHub Discussions](https://github.com/USERNAME/REPOSITORY/discussions)  
- 📧 **Email**: your-email@domain.com
- 🌐 **Website**: https://your-website.com

---

**⭐ Star dieses Repository, wenn es dir geholfen hat!**
