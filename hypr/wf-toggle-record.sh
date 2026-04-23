#!/usr/bin/env bash

PID_FILE="/tmp/wf-recorder.pid"
OUT_DIR="$HOME/Videos"
GIF_SPEED=2 # 1 = normal speed, 2 = 2x speed, 0.5 = half speed

show_notification_with_actions() {
  local title="$1"
  local body="$2"
  local file_path="$3"

  # Send notification and capture selected action
  ACTION=$(notify-send \
    -a "Screen Recorder" \
    -i "image-x-generic" \
    -h string:x-canonical-private-synchronous:screen-recorder \
    -t 10000 \
    --action="folder=📁 Show in Folder" \
    "$title" \
    "$body")

  case "$ACTION" in
  folder)
    [ -f "$file_path" ] && thunar "$file_path"
    ;;
  esac
}

mkdir -p "$OUT_DIR"

# Если запись идёт → остановить и сделать GIF
if pgrep -x wf-recorder >/dev/null; then
  echo "Stopping recording..."
  notify-send \
    -a "Screen Recorder" \
    -i "media-playback-stop" \
    -h string:x-canonical-private-synchronous:screen-recorder \
    "⏹️ Recording Stopped" \
    "Processing video..."

  pkill -INT wf-recorder

  # дождаться завершения процесса
  while pgrep -x wf-recorder >/dev/null; do
    sleep 0.2
  done

  # найти последний записанный файл
  LAST_VIDEO=$(ls -t "$OUT_DIR"/record_*.mp4 2>/dev/null | head -n 1)

  if [ -n "$LAST_VIDEO" ]; then
    VIDEO_NAME=$(basename "$LAST_VIDEO")
    VIDEO_SIZE=$(du -h "$LAST_VIDEO" | cut -f1)

    notify-send \
      -a "Screen Recorder" \
      -i "video-x-generic" \
      -h string:x-canonical-private-synchronous:screen-recorder \
      "💾 Video Saved" \
      "$VIDEO_NAME\nSize: $VIDEO_SIZE\nCreating GIF at ${GIF_SPEED}x speed..."

    GIF_FILE="${LAST_VIDEO%.mp4}.gif"

    # Calculate PTS filter for speed adjustment
    # For 2x speed: setpts=0.5*PTS (half the time)
    # For 0.5x speed: setpts=2*PTS (double the time)
    SPEED_FILTER="setpts=$(echo "scale=4; 1/$GIF_SPEED" | bc)*PTS"

    echo "Creating GIF with ${GIF_SPEED}x speed..."
    ffmpeg -y -i "$LAST_VIDEO" \
      -vf "fps=10,scale=640:-1:flags=lanczos,$SPEED_FILTER,split[s0][s1];[s0]palettegen[p];[s1][p]paletteuse" \
      -loop 0 \
      "$GIF_FILE" 2>/dev/null

    if [ -f "$GIF_FILE" ]; then
      GIF_SIZE=$(du -h "$GIF_FILE" | cut -f1)

      # Show interactive notification with clickable actions
      show_notification_with_actions \
        "🎬 GIF Created" \
        "$(basename "$GIF_FILE")\nSize: $GIF_SIZE\nSpeed: ${GIF_SPEED}x\n\n✨ Click buttons below to open" \
        "$GIF_FILE"

    else
      notify-send \
        -a "Screen Recorder" \
        -i "dialog-error" \
        -h string:x-canonical-private-synchronous:screen-recorder \
        -u critical \
        "❌ GIF Creation Failed" \
        "Check if ffmpeg is installed"
    fi
  else
    notify-send \
      -a "Screen Recorder" \
      -i "dialog-warning" \
      -h string:x-canonical-private-synchronous:screen-recorder \
      "⚠️ No Video Found" \
      "No recording file was found to convert"
  fi

  exit 0
fi

# Если записи нет → старт (БЕЗ звука)
FILENAME="$OUT_DIR/record_$(date +%Y-%m-%d_%H-%M-%S).mp4"

# Check if slurp is available
if ! command -v slurp &>/dev/null; then
  notify-send \
    -a "Screen Recorder" \
    -i "dialog-error" \
    -u critical \
    "❌ Missing Dependency" \
    "slurp is not installed. Install with: sudo apt install slurp"
  exit 1
fi

# Check if wf-recorder is available
if ! command -v wf-recorder &>/dev/null; then
  notify-send \
    -a "Screen Recorder" \
    -i "dialog-error" \
    -u critical \
    "❌ Missing Dependency" \
    "wf-recorder is not installed. Install with: nix-env -iA nixos.wf-recorder"
  exit 1
fi

# Get selection area with beautiful UI
SELECTION=$(slurp -d -b "#00000080" -c "#00ff00ff" -s "#00000000" -w 2)
if [ -z "$SELECTION" ]; then
  notify-send \
    -a "Screen Recorder" \
    -i "dialog-info" \
    -h string:x-canonical-private-synchronous:screen-recorder \
    -t 2000 \
    "❌ Recording Cancelled" \
    "No area selected"
  exit 0
fi

# Start recording
notify-send \
  -a "Screen Recorder" \
  -i "media-playback-start" \
  -h string:x-canonical-private-synchronous:screen-recorder \
  -t 3000 \
  "🎥 Recording Started" \
  "Recording to: $(basename "$FILENAME")\nPress the same hotkey to stop"

wf-recorder \
  -g "$SELECTION" \
  -c libx264 \
  -f "$FILENAME" &

# Save PID
echo $! >"$PID_FILE"
