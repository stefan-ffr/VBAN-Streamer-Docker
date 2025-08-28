# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

### Added
- Initial project setup
- Bluetooth A2DP sink functionality
- VBAN audio streaming support
- Multi-architecture container builds (ARM64, ARM/v7, AMD64)

### Changed

### Deprecated

### Removed

### Fixed

### Security

## [1.0.0] - 2025-01-XX

### Added
- 🎵 Bluetooth speaker functionality for Raspberry Pi
- 📡 VBAN streaming integration with Voicemeeter Banana
- 🔄 Automatic GitHub Actions builds for multi-architecture
- 🛡️ Security scanning with Trivy
- 📦 GitHub Container Registry integration
- 🚀 Quick setup script for easy installation
- 📋 Comprehensive documentation and setup guides
- 🐛 Issue templates for better bug reporting
- 🔒 Security policy and best practices
- ⚡ Automatic dependency updates with Dependabot

### Features
- **Bluetooth Audio Sink**: Raspberry Pi appears as "VBAN-Speaker"
- **Auto-Pairing**: Automatic Bluetooth pairing without PIN codes
- **VBAN Streaming**: Real-time audio forwarding to Voicemeeter
- **Multi-Device Support**: Works with phones, PCs, tablets, etc.
- **Audio Quality**: Configurable sample rates (44.1kHz, 48kHz)
- **Container Health Checks**: Automatic recovery on failures
- **Cross-Platform**: ARM64, ARM/v7, and AMD64 support

### Technical Details
- **Base Image**: Debian Bullseye Slim
- **Audio System**: PulseAudio with Bluetooth modules
- **Networking**: Host networking mode for Bluetooth compatibility
- **Privileges**: Privileged container for hardware access
- **Monitoring**: Health checks and logging integration

### Container Registry
- Available at `ghcr.io/USERNAME/REPOSITORY:latest`
- Multi-architecture manifests supported
- Automated builds on push and schedule
- Security attestation included

### Documentation
- Complete README with setup instructions
- Docker Compose configuration examples
- Troubleshooting guide included
- Security best practices documented

---

## Release Notes Template

When creating a new release, use this template:

```markdown
## [X.Y.Z] - YYYY-MM-DD

### 🎵 Audio Features
- New audio feature descriptions

### 📡 VBAN Improvements  
- VBAN-related changes

### 🔧 Configuration
- Configuration changes or new options

### 🐛 Bug Fixes
- Bug fix descriptions

### 🛡️ Security
- Security improvements or fixes

### 📦 Container Updates
- Container or build system changes

### 📚 Documentation
- Documentation improvements

### 🙏 Contributors
- Thanks to contributors (if any)

**Full Changelog**: https://github.com/USERNAME/REPOSITORY/compare/vX.Y.Z-1...vX.Y.Z
```