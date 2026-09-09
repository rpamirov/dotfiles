
source $HOME/repos/dotfiles/rpamirov.zsh
# EVO STUFF
source $HOME/.work_setup
source $HOME/repos/dotfiles/evo_llama.zsh
# Keep Qwen's llama.cpp credentials scoped to qwen_server; do not redirect
# OpenCode's OpenAI/ChatGPT provider through the local Qwen endpoint.
unset OPENAI_API_KEY OPENAI_BASE_URL

# OpenCode's ChatGPT OAuth provider must not inherit Qwen/llama.cpp's local
# OpenAI-compatible endpoint, even when this shell was started by an older
# session that still had those variables exported.
function opencode() {
  env -u OPENAI_API_KEY -u OPENAI_BASE_URL command opencode "$@"
}

export PATH=/usr/local/cuda-12.6/bin${PATH:+:${PATH}}
export LD_LIBRARY_PATH=/usr/local/cuda-12.6/lib64\${LD_LIBRARY_PATH:+:${LD_LIBRARY_PATH}}

function start_wayvnc() {
	local -x XDG_RUNTIME_DIR="${XDG_RUNTIME_DIR:-/run/user/$(id -u)}"
	local -x WAYLAND_DISPLAY="${WAYLAND_DISPLAY:-}"
	local -x WLR_RENDERER=gles2
	if [[ -z "$WAYLAND_DISPLAY" ]]; then
		local socket
		local -a displays=()
		for socket in "$XDG_RUNTIME_DIR"/wayland-*(N); do
			[[ -S "$socket" ]] && displays+=("${socket:t}")
		done
		if (( ${#displays} == 0 )); then
			print -u2 -- "start_wayvnc: no Wayland display found in $XDG_RUNTIME_DIR. Is your desktop running?"
			return 1
		elif (( ${#displays} > 1 )); then
			print -u2 -- "start_wayvnc: multiple Wayland displays found: ${displays[*]}. Run WAYLAND_DISPLAY=<display> start_wayvnc."
			return 1
		fi
		WAYLAND_DISPLAY="${displays[1]}"
	fi
	systemctl --user restart xdg-desktop-portal-wlr
	pkill -f "^/usr/bin/waybar"
	wayvnc 0.0.0.0 5900
}

. "$HOME/.local/share/../bin/env"
[ -f ~/.fzf.zsh ] && source ~/.fzf.zsh
[ -f ~/etc/profile.d/go ] && source /etc/profile.d/golang_path.sh
eval "$(zoxide init zsh)"

# Pi
export PATH="$HOME/.local/bin:$PATH"
export PATH="$HOME/.npm-global/bin:$PATH"

# opencode
export PATH=/home/rpamirov/.opencode/bin:$PATH

# Load SSH key for GitHub (used by Neovim lazy.nvim and other tools)
if [ -z "$SSH_AUTH_SOCK" ]; then
    eval "$(ssh-agent -s)" 2>/dev/null
    ssh-add ~/.ssh/id_ed25519 2>/dev/null
fi
