# Security Policy

## Supported Versions

Diese Versionen erhalten aktuelle Sicherheitsupdates:

| Version | Supported          |
| ------- | ------------------ |
| latest  | :white_check_mark: |
| v1.x.x  | :white_check_mark: |
| < v1.0  | :x:                |

## Reporting a Vulnerability

### Verantwortungsvolle Offenlegung

Wenn du eine Sicherheitslücke findest, melde sie bitte verantwortungsvoll:

1. **Sende eine E-Mail** an security@your-domain.com
2. **Verwende KEINE** öffentlichen Issues für Sicherheitsprobleme
3. **Beschreibe** das Problem so detailliert wie möglich
4. **Gib uns Zeit** für eine Antwort (normalerweise 48h)

### Was du erwarten kannst

- **Bestätigung** deines Reports innerhalb von 48 Stunden
- **Regelmäßige Updates** zum Fortschritt der Behebung
- **Credit** in der Danksagung (falls gewünscht)
- **Koordinierte Offenlegung** nach der Behebung

### Sicherheitsbest Practices

Beim Verwenden dieses Containers:

#### Container Security
- ✅ Verwende **spezifische Tags** statt `latest`
- ✅ Scanne Container regelmäßig auf Vulnerabilities
- ✅ Verwende **read-only** Filesysteme wo möglich
- ⚠️ **Privileged Mode** ist für Bluetooth/Audio erforderlich

#### Network Security  
- ✅ Beschränke **VBAN-Traffic** auf vertrauenswürdige Netzwerke
- ✅ Verwende **Firewall-Regeln** für Port 6980/UDP
- ✅ Überwache **Netzwerk-Traffic** auf Anomalien
- ⚠️ **Host-Network** Modus ist für Bluetooth erforderlich

#### Bluetooth Security
- ✅ Verwende **starke Bluetooth-PINs** (falls konfiguriert)
- ✅ Deaktiviere **Discovery-Mode** nach Setup
- ✅ Entferne **ungenutzte Pairings** regelmäßig
- ⚠️ **Auto-Accept** ist praktisch, aber weniger sicher

### Container Scanning

Unser Container wird automatisch gescannt mit:

- **Trivy** - Vulnerability Scanner
- **GitHub Security Advisories**
- **Base Image** Updates (Debian Security)

Du kannst den Container selbst scannen:

```bash
# Mit Trivy
docker run --rm -v /var/run/docker.sock:/var/run/docker.sock \
  aquasec/trivy image ghcr.io/USERNAME/REPOSITORY:latest

# Mit Snyk
snyk container test ghcr.io/USERNAME/REPOSITORY:latest
```

### Sichere Konfiguration

Empfohlene Sicherheits-Konfiguration:

```yaml
# docker-compose.yml - Security Hardened
services:
  vban-bluetooth-speaker:
    image: ghcr.io/USERNAME/REPOSITORY:v1.2.3  # Spezifische Version
    
    # Security Options
    security_opt:
      - no-new-privileges:true
    
    # Read-only Root (wo möglich)
    read_only: true
    tmpfs:
      - /tmp:noexec,nosuid,size=100m
      - /var/tmp:noexec,nosuid,size=50m
    
    # Capabilities (minimal erforderlich)
    cap_add:
      - NET_RAW          # Für Bluetooth
      - SYS_ADMIN        # Für Audio-Hardware
    cap_drop:
      - ALL
    
    # User Namespace (falls möglich)
    user: "1000:1000"
    
    # Resource Limits
    deploy:
      resources:
        limits:
          cpus: '1.0'
          memory: 512M
          pids: 100
    
    # Logging für Security Monitoring
    logging:
      driver: syslog
      options:
        syslog-address: "udp://syslog-server:514"
        tag: "vban-bluetooth-{{.ID}}"
```

### Known Security Considerations

#### Privileged Container
- **Erforderlich** für Hardware-Zugriff (Bluetooth/Audio)
- **Risiko**: Root-Zugriff auf Host-System
- **Mitigation**: Verwende auf isolierten Systemen (Raspberry Pi)

#### Host Networking
- **Erforderlich** für Bluetooth-Funktionalität
- **Risiko**: Vollständiger Netzwerk-Zugriff
- **Mitigation**: Firewall-Regeln und Netzwerk-Segmentierung

#### Auto Bluetooth Pairing
- **Praktisch** für Benutzerfreundlichkeit
- **Risiko**: Ungewollte Verbindungen möglich
- **Mitigation**: Regelmäßige Überprüfung der Pairings

### Security Monitoring

Überwache diese Logs für Security Events:

```bash
# Container Logs
docker logs vban-bluetooth-speaker | grep -E "(WARN|ERROR|SECURITY)"

# Bluetooth Connections
docker exec vban-bluetooth-speaker bluetoothctl devices Connected

# Network Connections
netstat -tulnp | grep 6980

# System Logs
journalctl -u docker -f | grep vban-bluetooth-speaker
```

### Contact

Für Sicherheitsfragen:
- 📧 **Security E-Mail**: security@your-domain.com
- 🔒 **GPG Key**: [Public Key Link]
- ⏱️ **Response Time**: < 48h
- 🌐 **Security Page**: https://your-website.com/security