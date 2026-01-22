#!/usr/bin/env bash

set -euo pipefail

if [[ -z "${1:-}" ]]; then
  exit 1
fi

FILE="$1"

if [[ ! -f "$FILE" ]]; then
  exit 1
fi

if command -v wl-copy >/dev/null 2>&1; then
  cat "$FILE" | wl-copy

elif command -v xclip >/dev/null 2>&1; then
  cat "$FILE" | xclip -selection clipboard

else
  exit 1
fi
