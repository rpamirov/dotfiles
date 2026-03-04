#!/usr/bin/env bash

PID_FILE="/tmp/wf-recorder.pid"
OUT_DIR="$HOME/Videos"

# Если запись идёт → остановить и сделать GIF
if pgrep -x wf-recorder >/dev/null; then
  echo "Stopping recording..."

  pkill -INT wf-recorder

  # дождаться завершения процесса
  while pgrep -x wf-recorder >/dev/null; do
    sleep 0.2
  done

  # найти последний записанный файл
  LAST_VIDEO=$(ls -t "$OUT_DIR"/record_*.mp4 2>/dev/null | head -n 1)

  if [ -n "$LAST_VIDEO" ]; then
    GIF_FILE="${LAST_VIDEO%.mp4}.gif"

    echo "Creating GIF..."
    ffmpeg -y -i "$LAST_VIDEO" \
      -vf "fps=15,scale=1280:-1:flags=lanczos" \
      "$GIF_FILE"
  fi

  exit 0
fi

# Если записи нет → старт (БЕЗ звука)
FILENAME="$OUT_DIR/record_$(date +%Y-%m-%d_%H-%M-%S).mp4"

wf-recorder \
  -g "$(slurp)" \
  -c libx264 \
  -f "$FILENAME"
