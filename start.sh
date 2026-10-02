#!/bin/bash
set -Eeuo pipefail

export DISPLAY=:1
export XDG_RUNTIME_DIR=/tmp/runtime-root
mkdir -p "$XDG_RUNTIME_DIR"
chmod 700 "$XDG_RUNTIME_DIR"

PORT="${PORT:-8080}"
RESOLUTION="${MAX_UBUNTU_RESOLUTION:-1280x720x24}"

rm -f /tmp/.X1-lock /tmp/.X11-unix/X1 || true
mkdir -p /tmp/.X11-unix

echo "[max-ubuntu] starting Xvfb on $RESOLUTION"
Xvfb :1 -screen 0 "$RESOLUTION" -ac +extension GLX +render -noreset >/tmp/xvfb.log 2>&1 &
XVFB_PID=$!

for i in $(seq 1 30); do
  if xdpyinfo -display :1 >/dev/null 2>&1; then break; fi
  sleep 1
done

if ! xdpyinfo -display :1 >/dev/null 2>&1; then
  echo "[max-ubuntu] Xvfb failed to start"
  cat /tmp/xvfb.log || true
  exit 1
fi

echo "[max-ubuntu] starting Ubuntu GNOME desktop"
rm -rf /tmp/runtime-ubuntu
mkdir -p /tmp/runtime-ubuntu
chown ubuntu:ubuntu /tmp/runtime-ubuntu
chmod 700 /tmp/runtime-ubuntu

su - ubuntu -c 'export DISPLAY=:1 XDG_RUNTIME_DIR=/tmp/runtime-ubuntu DBUS_SESSION_BUS_ADDRESS=; dbus-run-session -- gnome-session --session=ubuntu' >/tmp/gnome.log 2>&1 &
DESKTOP_PID=$!

sleep 5
if ! kill -0 "$DESKTOP_PID" 2>/dev/null; then
  echo "[max-ubuntu] GNOME process exited"
  cat /tmp/gnome.log || true
  exit 1
fi

echo "[max-ubuntu] starting x11vnc"
x11vnc -display :1 -forever -shared -rfbport 5900 -localhost -nopw -noxdamage -repeat -wait 5 >/tmp/x11vnc.log 2>&1 &
VNC_PID=$!

sleep 2
if ! kill -0 "$VNC_PID" 2>/dev/null; then
  echo "[max-ubuntu] x11vnc failed"
  cat /tmp/x11vnc.log || true
  exit 1
fi

echo "[max-ubuntu] starting noVNC on 0.0.0.0:$PORT"
websockify --web=/usr/share/novnc 0.0.0.0:"$PORT" 127.0.0.1:5900 >/tmp/novnc.log 2>&1 &
NOVNC_PID=$!

for i in $(seq 1 60); do
  if curl -fsS --max-time 2 "http://127.0.0.1:$PORT/vnc.html" >/dev/null 2>&1; then
    echo "[max-ubuntu] ready on 0.0.0.0:$PORT"
    break
  fi
  sleep 1
done

if ! curl -fsS --max-time 2 "http://127.0.0.1:$PORT/vnc.html" >/dev/null 2>&1; then
  echo "[max-ubuntu] noVNC health check failed"
  cat /tmp/novnc.log || true
  exit 1
fi

trap 'kill "$NOVNC_PID" "$VNC_PID" "$DESKTOP_PID" "$XVFB_PID" 2>/dev/null || true' EXIT INT TERM
wait "$NOVNC_PID"
