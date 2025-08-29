# Dockerfile mit nativer PulseAudio Netzwerk-Audio Unterstützung
FROM debian:bullseye-slim

# Installiere nur das Nötigste - PulseAudio hat alles eingebaut!
RUN apt-get update && apt-get install -y \
    pulseaudio \
    pulseaudio-module-bluetooth \
    pulseaudio-module-zeroconf \
    pulseaudio-module-native-protocol-tcp \
    bluetooth \
    bluez \
    bluez-tools \
    dbus \
    avahi-daemon \
    alsa-utils \
    netcat \
    && rm -rf /var/lib/apt/lists/*

# PulseAudio Konfiguration
RUN mkdir -p /etc/pulse
COPY pulse-daemon.conf /etc/pulse/daemon.conf
COPY pulse-default.pa /etc/pulse/default.pa

# Scripts kopieren
COPY bluetooth-setup.sh /usr/local/bin/
COPY start.sh /usr/local/bin/
RUN chmod +x /usr/local/bin/*.sh

# PulseAudio TCP/UDP Module Config
RUN echo "load-module module-native-protocol-tcp auth-ip-acl=127.0.0.1;192.168.0.0/16;10.0.0.0/8" >> /etc/pulse/system.pa
RUN echo "load-module module-rtp-send destination_ip=${VBAN_TARGET_IP:-192.168.1.100} port=6980 loop=1" >> /etc/pulse/system.pa

EXPOSE 6980/udp
EXPOSE 4713/tcp

CMD ["/usr/local/bin/start.sh"]
