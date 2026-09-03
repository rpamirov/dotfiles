#!/usr/bin/env bash
set -euo pipefail

# Install the latest stable Neovim release for the current user.
# The active binary is exposed through ~/.local/bin, which is already before
# /opt in the host shell PATH.

readonly INSTALL_ROOT="${NVIM_INSTALL_ROOT:-${HOME}/.local/opt/nvim}"
readonly BIN_DIR="${NVIM_BIN_DIR:-${HOME}/.local/bin}"
readonly API_URL="https://api.github.com/repos/neovim/neovim/releases/latest"

case "$(uname -m)" in
  x86_64)
    archive="nvim-linux-x86_64.tar.gz"
    package_dir="nvim-linux-x86_64"
    ;;
  aarch64|arm64)
    archive="nvim-linux-arm64.tar.gz"
    package_dir="nvim-linux-arm64"
    ;;
  *)
    printf 'Unsupported architecture: %s\n' "$(uname -m)" >&2
    exit 1
    ;;
esac

command -v curl >/dev/null || { printf 'curl is required\n' >&2; exit 1; }
command -v tar >/dev/null || { printf 'tar is required\n' >&2; exit 1; }

release_tag="$(curl --fail --silent --show-error --location "$API_URL" \
  | sed -n 's/.*"tag_name": *"\([^"]*\)".*/\1/p' | head -n 1)"

if [[ ! "$release_tag" =~ ^v[0-9]+\.[0-9]+\.[0-9]+$ ]]; then
  printf 'Could not determine a stable Neovim release tag\n' >&2
  exit 1
fi

version_dir="$INSTALL_ROOT/$release_tag"
link_path="$BIN_DIR/nvim"
download_url="https://github.com/neovim/neovim/releases/download/${release_tag}/${archive}"

mkdir -p "$INSTALL_ROOT" "$BIN_DIR"

if [[ ! -x "$version_dir/bin/nvim" ]]; then
  temp_dir="$(mktemp -d "$INSTALL_ROOT/.update.XXXXXX")"
  trap 'rm -rf "$temp_dir"' EXIT

  printf '[INFO] Downloading Neovim %s\n' "$release_tag"
  curl --fail --location --progress-bar "$download_url" -o "$temp_dir/$archive"
  tar -xzf "$temp_dir/$archive" -C "$temp_dir"

  if [[ ! -x "$temp_dir/$package_dir/bin/nvim" ]]; then
    printf 'Downloaded archive does not contain a Neovim binary\n' >&2
    exit 1
  fi

  mv "$temp_dir/$package_dir" "$version_dir"
fi

ln -sfn "$version_dir/bin/nvim" "$link_path"

printf '[OK] Neovim %s is active at %s\n' "$release_tag" "$link_path"
"$link_path" --version | head -n 2
