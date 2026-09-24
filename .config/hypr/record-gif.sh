#!/usr/bin/env bash
set -euo pipefail

# Toggle Omarchy's native screen recorder. On stop, preserve the old workflow
# by converting the newest recording into a looping 2x GIF.

video_dir=${XDG_VIDEOS_DIR:-$HOME/Videos}
gif_speed=2

notify() {
  if command -v omarchy-notification-send >/dev/null 2>&1; then
    omarchy-notification-send "$@"
  else
    notify-send "$@"
  fi
}

if ! pgrep -f '^gpu-screen-recorder' >/dev/null; then
  exec omarchy capture screenrecording
fi

omarchy capture screenrecording --stop-recording

latest=$(
  find "$video_dir" -maxdepth 1 -type f -name 'screenrecording-*.mp4' \
    -printf '%T@ %p\n' 2>/dev/null | sort -nr | head -n 1 | cut -d' ' -f2-
)

if [[ -z "$latest" || ! -f "$latest" ]]; then
  notify -u critical "GIF conversion failed" "No Omarchy screen recording was found"
  exit 1
fi

gif_file=${latest%.mp4}.gif
speed_filter="setpts=$(awk -v speed="$gif_speed" 'BEGIN { printf "%.4f", 1 / speed }')*PTS"

if ffmpeg -y -i "$latest" \
  -vf "fps=10,scale=1080:-1:flags=lanczos,$speed_filter,split[s0][s1];[s0]palettegen[p];[s1][p]paletteuse" \
  -loop 0 "$gif_file" -loglevel error; then
  notify "GIF created" "$(basename "$gif_file") (${gif_speed}x)" --image "$gif_file"
else
  notify -u critical "GIF conversion failed" "$(basename "$latest")"
  exit 1
fi
