# Dockerfile für VBAN Bluetooth Audio Bridge (Bluetooth Speaker Mode)
FROM debian:bullseye-slim

# Pakete installieren für Bluetooth Speaker Funktionalität
RUN apt-get update && apt-get install -y \
    pulseaudio \
    pulseaudio-module-bluetooth \
    bluetooth \
    bluez \
    bluez-tools \
    alsa-utils \
    wget \
    unzip \
    dbus \
    expect \
    gstreamer1.0-plugins-base \
    gstreamer1.0-plugins-good \
    gstreamer1.0-plugins-ugly \
    gstreamer1.0-pulseaudio \
    && rm -rf /var/lib/apt/lists/*

# VBAN Tools herunterladen (Linux Version)
WORKDIR /opt
RUN wget -O vban.zip https://vb-audio.com/Voicemeeter/VBANCmdline_Linux.zip && \
    unzip vban.zip && \
    chmod +x vban_* && \
    rm vban.zip

# PulseAudio Konfiguration
RUN mkdir -p /etc/pulse
COPY pulse-daemon.conf /etc/pulse/daemon.conf
COPY pulse-default.pa /etc/pulse/default.pa

# Bluetooth Setup Script
COPY bluetooth-setup.sh /usr/local/bin/
RUN chmod +x /usr/local/bin/bluetooth-setup.sh

# VBAN Bridge Script
COPY vban-bridge.sh /usr/local/bin/
RUN chmod +x /usr/local/bin/vban-bridge.sh

# Start Script
COPY start.sh /usr/local/bin/
RUN chmod +x /usr/local/bin/start.sh

EXPOSE 6980/udp

CMD ["/usr/local/bin/start.sh"]