#!/bin/bash
set -e

export DISPLAY=:1
export XDG_RUNTIME_DIR=/tmp/runtime-root
mkdir -p "$XDG_RUNTIME_DIR"
chmod 700 "$XDG_RUNTIME_DIR"

PORT="${PORT:-8080}"
RESOLUTION="${MAX_UBUNTU_RESOLUTION:-1280x720x24}"

rm -f /tmp/.X1-lock /tmp/.X11-unix/X1 || true

echo "[max-ubuntu] starting Xvfb on $RESOLUTION"
Xvfb :1 -screen 0 "$RESOLUTION" -ac +extension GLX +render -noreset &
XVFB_PID=$!

for i in $(seq 1 30); do
  if xdpyinfo -display :1 >/dev/null 2>&1; then break; fi
  sleep 1
done

echo "[max-ubuntu] starting XFCE"
dbus-launch --exit-with-session startxfce4 >/tmp/xfce.log 2>&1 &
XFCE_PID=$!

sleep 3

echo "[max-ubuntu] starting x11vnc"
x11vnc -display :1 -forever -shared -rfbport 5900 -localhost -nopw -noxdamage -repeat -wait 5 >/tmp/x11vnc.log 2>&1 &
VNC_PID=$!

echo "[max-ubuntu] starting noVNC on 0.0.0.0:$PORT"
websockify --web=/usr/share/novnc 0.0.0.0:"$PORT" 127.0.0.1:5900 >/tmp/novnc.log 2>&1 &
NOVNC_PID=$!

for i in $(seq 1 60); do
  if (echo >/dev/tcp/127.0.0.1/"$PORT") >/dev/null 2>&1; then
    echo "[max-ubuntu] ready on 0.0.0.0:$PORT"
    break
  fi
  sleep 1
done

if ! kill -0 "$NOVNC_PID" 2>/dev/null; then
  echo "[max-ubuntu] noVNC failed"
  cat /tmp/novnc.log || true
  exit 1
fi

wait "$NOVNC_PID"
