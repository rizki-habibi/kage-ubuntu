FROM ubuntu:24.04

ENV DEBIAN_FRONTEND=noninteractive
ENV DISPLAY=:1
ENV HOME=/root
ENV TZ=Asia/Jakarta

RUN apt-get update && apt-get install -y --no-install-recommends \
    xfce4 xfce4-terminal dbus-x11 \
    xvfb x11vnc novnc websockify \
    firefox-esr sudo curl wget git ca-certificates \
    fonts-dejavu fonts-noto-core \
    supervisor procps iproute2 net-tools \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/*

RUN useradd -m -s /bin/bash ubuntu && \
    echo 'ubuntu ALL=(ALL) NOPASSWD:ALL' > /etc/sudoers.d/ubuntu && \
    chmod 0440 /etc/sudoers.d/ubuntu

COPY start.sh /usr/local/bin/max-ubuntu-start
RUN chmod +x /usr/local/bin/max-ubuntu-start

EXPOSE 8080
ENTRYPOINT ["/usr/local/bin/max-ubuntu-start"]
