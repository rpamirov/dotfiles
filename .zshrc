
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
	export WLR_RENDERER=gles2
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

# opencode
export PATH=/home/rpamirov/.opencode/bin:$PATH
