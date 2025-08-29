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
    git \
    build-essential \
    libasound2-dev \
    && rm -rf /var/lib/apt/lists/*

# VBAN Tools kompilieren (offizieller Linux-Support existiert nicht, nutze Alternative)
WORKDIR /opt
RUN git clone https://github.com/quiniouben/vban.git && \
    cd vban && \
    make && \
    cp src/vban_emitter /usr/local/bin/ && \
    cp src/vban_receptor /usr/local/bin/ && \
    chmod +x /usr/local/bin/vban_* && \
    cd .. && rm -rf vban

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
