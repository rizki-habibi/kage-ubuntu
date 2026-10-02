FROM ubuntu:24.04

ENV DEBIAN_FRONTEND=noninteractive
ENV DISPLAY=:1
ENV HOME=/root
ENV TZ=Asia/Jakarta

RUN apt-get update && apt-get install -y --no-install-recommends \
    ubuntu-desktop-minimal gnome-shell ubuntu-session gnome-terminal nautilus \
    dbus-x11 xvfb x11vnc novnc websockify x11-utils \
    sudo curl wget git ca-certificates tar xz-utils \
    fonts-dejavu fonts-noto-core \
    procps iproute2 net-tools \
    && mkdir -p /opt/firefox \
    && wget -qO /tmp/firefox.tar.xz "https://download.mozilla.org/?product=firefox-latest&os=linux64&lang=en-US" \
    && tar -xJf /tmp/firefox.tar.xz -C /opt/firefox --strip-components=1 \
    && test -x /opt/firefox/firefox \
    && ln -sf /opt/firefox/firefox /usr/local/bin/firefox \
    && rm -f /tmp/firefox.tar.xz \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/*

RUN if id -u ubuntu >/dev/null 2>&1; then \
      echo "ubuntu user already exists"; \
    else \
      useradd -m -s /bin/bash ubuntu; \
    fi && \
    echo 'ubuntu ALL=(ALL) NOPASSWD:ALL' > /etc/sudoers.d/ubuntu && \
    chmod 0440 /etc/sudoers.d/ubuntu && \
    mkdir -p /tmp/runtime-ubuntu && \
    chown ubuntu:ubuntu /tmp/runtime-ubuntu

COPY start.sh /usr/local/bin/max-ubuntu-start
RUN chmod +x /usr/local/bin/max-ubuntu-start

EXPOSE 8080
ENTRYPOINT ["/usr/local/bin/max-ubuntu-start"]