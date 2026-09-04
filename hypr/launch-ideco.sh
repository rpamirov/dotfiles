#!/usr/bin/env bash

set -euo pipefail

agent_root=/usr/local/Ideco/Agent
launcher=$(find "$agent_root" -mindepth 2 -maxdepth 2 -type f -name IdecoClient.sh -print \
    | sort -V \
    | tail -n 1)

if [[ -z "$launcher" ]]; then
    printf 'Ideco launcher not found below %s\n' "$agent_root" >&2
    exit 1
fi

exec env QT_QPA_PLATFORM=xcb "$launcher" --show
