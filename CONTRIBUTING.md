# Contributing to VBAN Bluetooth Speaker

Vielen Dank für Ihr Interesse an diesem Projekt! Wir freuen uns über jede Art von Beitrag.

## 🤝 Arten von Beiträgen

Wir begrüßen verschiedene Arten von Beiträgen:

- 🐛 **Bug Reports** - Melden Sie Probleme oder Fehler
- 💡 **Feature Requests** - Schlagen Sie neue Funktionen vor
- 📖 **Documentation** - Verbessern Sie die Dokumentation
- 🔧 **Code Contributions** - Beheben Sie Bugs oder implementieren Sie Features
- 🧪 **Testing** - Testen Sie auf verschiedenen Plattformen
- 📝 **Examples** - Erstellen Sie Beispiele oder Tutorials

## 🚀 Getting Started

### Development Setup

1. **Repository forken und klonen**
   ```bash
   git clone https://github.com/IHR-USERNAME/vban-bluetooth-speaker.git
   cd vban-bluetooth-speaker
   ```

2. **Development Environment einrichten**
   ```bash
   # Docker für lokale Tests
   docker build -t vban-dev .
   
   # Test-Container starten
   docker run --rm -it --privileged vban-dev bash
   ```

3. **Branch für Feature erstellen**
   ```bash
   git checkout -b feature/amazing-feature
   ```

## 📋 Development Guidelines

### Code Style

- **Shell Scripts**: Folgen Sie der [Google Shell Style Guide](https://google.github.io/styleguide/shellguide.html)
- **Docker**: Multi-stage builds verwenden wo möglich
- **YAML**: 2-space indentation, keine Tabs
- **Markdown**: Verwenden Sie klare Struktur mit Headers

### Testing

Vor dem Einreichen von Changes:

```bash
# Container-Build testen
docker build -t test-build .

# Multi-Architecture Build testen (falls Buildx verfügbar)
docker buildx build --platform linux/amd64,linux/arm64 .

# Grundfunktionalität testen
docker run --rm test-build pulseaudio --version
docker run --rm test-build bluetoothctl --version
```

### Commit Messages

Verwenden Sie aussagekräftige Commit-Messages:

```bash
# Gut ✅
git commit -m "🐛 Fix Bluetooth auto-pairing timeout issue"
git commit -m "✨ Add support for custom audio codecs"
git commit -m "📚 Update README with troubleshooting section"

# Nicht so gut ❌
git commit -m "fix bug"
git commit -m "update stuff"
```

**Commit-Präfixe:**
- 🎵 `:musical_note:` - Audio-related changes
- 📡 `:satellite:` - VBAN/Network changes  
- 🐛 `:bug:` - Bug fixes
- ✨ `:sparkles:` - New features
- 📚 `:books:` - Documentation
- 🔧 `:wrench:` - Configuration changes
- 🚀 `:rocket:` - Performance improvements
- 🛡️ `:shield:` - Security improvements

## 🐛 Bug Reports

Beim Melden von Bugs verwenden Sie bitte die [Bug Report Template](.github/ISSUE_TEMPLATE/bug_report.yml) und geben Sie folgende Informationen an:

### Mindest-Informationen
- **Plattform** (Raspberry Pi Model, OS Version)
- **Container Version** (Tag oder Commit-Hash)
- **Schritte zur Reproduktion**
- **Erwartetes vs. aktuelles Verhalten**
- **Container-Logs** (`docker logs vban-bluetooth-speaker`)

### Hilfreiche Zusatz-Informationen
```bash
# System-Informationen sammeln
uname -a
docker version
docker info
hciconfig
pulseaudio --version

# Bluetooth-Status
bluetoothctl devices
bluetoothctl show

# Netzwerk-Connectivity
ping [VOICEMEETER-IP]
netstat -ulnp | grep 6980
```

## 💡 Feature Requests

Für neue Features verwenden Sie bitte die [Feature Request Template](.github/ISSUE_TEMPLATE/feature_request.yml).

### Beliebte Feature-Kategorien

- **Audio-Codecs**: AAC, aptX, LDAC Unterstützung
- **Web-Interface**: Container-Management via Browser
- **Multi-Client**: Mehrere VBAN-Ziele gleichzeitig
- **Audio-Effekte**: EQ, Kompressor, etc.
- **Integration**: Home Assistant, MQTT, etc.

## 🔧 Code Contributions

### Pull Request Process

1. **Issue erstellen** (außer für kleine Fixes)
2. **Fork** das Repository
3. **Feature Branch** erstellen
4. **Changes implementieren** mit Tests
5. **Dokumentation aktualisieren** falls nötig
6. **Pull Request** erstellen

### PR Requirements

- [ ] **Build erfolgreich** (GitHub Actions müssen grün sein)
- [ ] **Funktionalität getestet** auf mindestens einer Plattform
- [ ] **Dokumentation aktualisiert** (README, CHANGELOG)
- [ ] **Breaking Changes** klar dokumentiert
- [ ] **Security Implications** berücksichtigt

### Review Process

1. **Automated Checks**: GitHub Actions Builds müssen erfolgreich sein
2. **Manual Review**: Code-Review durch Maintainer
3. **Testing**: Funktionalitätstests (falls erforderlich)
4. **Documentation Review**: Dokumentations-Updates prüfen

## 🧪 Testing

### Test-Umgebungen

**Empfohlene Test-Setups:**
- **Raspberry Pi 4** (primäre Zielplattform)
- **Raspberry Pi 3B+** (Kompatibilitätstests)
- **Docker auf x86_64** (Development/Debugging)

### Test-Szenarien

**Bluetooth-Tests:**
- Pairing mit verschiedenen Gerätetypen (Android, iOS, Windows)
- Auto-Reconnect nach Verbindungsabbruch
- Mehrere Geräte nacheinander

**VBAN-Tests:**
- Audio-Qualität bei verschiedenen Sample-Rates
- Netzwerk-Latenz und Jitter
- Verbindungsabbruch-Recovery

**Container-Tests:**
- Health-Checks funktionieren korrekt
- Resource-Limits werden respektiert
- Logs sind aussagekräftig

## 📚 Documentation

### Dokumentations-Standards

- **README.md**: Hauptdokumentation aktuell halten
- **Inline-Kommentare**: Komplexe Skript-Abschnitte erklären
- **Examples**: Praktische Anwendungsbeispiele hinzufügen
- **Troubleshooting**: Häufige Probleme und Lösungen dokumentieren

### Dokumentation beitragen

```bash
# Dokumentation lokal testen
# (Verwenden Sie einen Markdown-Viewer oder GitHub Preview)

# Rechtschreibung prüfen
aspell check README.md

# Markdown-Linting (falls verfügbar)
markdownlint *.md
```

## 🛡️ Security Considerations

### Security Review

Bei Security-relevanten Changes:

1. **Threat Model** überdenken
2. **Privileged Container** Auswirkungen bewerten
3. **Network Exposure** minimieren
4. **Input Validation** sicherstellen

### Reporting Security Issues

**NIEMALS** Security-Issues in öffentlichen Issues melden!

- 📧 **Senden Sie eine E-Mail** an security@your-domain.com
- 🔒 **Verwenden Sie GPG** falls verfügbar
- ⏰ **Geben Sie uns 48h** für eine erste Antwort

## 📞 Community & Support

### Kommunikation

- 🐛 **GitHub Issues**: Bug Reports, Feature Requests
- 💬 **GitHub Discussions**: Fragen, Ideen, Show & Tell
- 📧 **Email**: Direkte Kommunikation mit Maintainern

### Code of Conduct

Wir folgen dem [Contributor Covenant](https://www.contributor-covenant.org/). Bitte behandeln Sie alle Community-Mitglieder mit Respekt.

## 🎯 Roadmap

### Kurze Termine (nächste 3 Monate)
- [ ] Web-Interface für Container-Management
- [ ] Erweiterte Audio-Codec-Unterstützung
- [ ] Performance-Optimierungen

### Lange Termine (6+ Monate)  
- [ ] Multi-Client VBAN-Streaming
- [ ] Home Assistant Integration
- [ ] Audio-Effekt-Pipeline

## 🙏 Recognition

Alle Beiträge werden in der [Contributors](https://github.com/USERNAME/REPOSITORY/graphs/contributors) Sektion anerkannt.

**Besonders wertvolle Beiträge können erwähnt werden in:**
- CHANGELOG.md
- Release Notes
- README.md Credits-Sektion

---

**Vielen Dank für Ihren Beitrag! 🎵**