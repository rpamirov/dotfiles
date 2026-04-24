# ZSH OPTIONS
# ===============================================
setopt HIST_EXPIRE_DUPS_FIRST
setopt HIST_IGNORE_DUPS
setopt HIST_IGNORE_ALL_DUPS
setopt HIST_IGNORE_SPACE
setopt HIST_FIND_NO_DUPS
setopt HIST_SAVE_NO_DUPS
ZSH_THEME="robbyrussell"
export ZSH="$HOME/.oh-my-zsh"
plugins=(git)
[[ -r ~/repos/znap/znap.zsh ]] ||
	git clone --depth 1 -- https://github.com/marlonrichert/zsh-snap.git ~/repos/znap
source ~/repos/znap/znap.zsh
znap prompt sindresorhus/pure
znap source marlonrichert/zsh-autocomplete
znap source zsh-users/zsh-autosuggestions
znap eval iterm2 'curl -fsSL https://iterm2.com/shell_integration/zsh'
znap function _pyenv pyenv "znap eval pyenv 'pyenv init - --no-rehash'"
compctl -K    _pyenv pyenv
source $ZSH/oh-my-zsh.sh

# Personal settings 
export PATH="$PATH:$HOME/.local/bin"
export PATH="$PATH:/home/rpamirov/.local/bin/:/home/user/.local/kitty.app/bin"
export PATH=/usr/local/cuda-12.6/bin${PATH:+:${PATH}}
export LD_LIBRARY_PATH=/usr/local/cuda-12.6/lib64\${LD_LIBRARY_PATH:+:${LD_LIBRARY_PATH}}
export DBUS_SESSION_BUS_ADDRESS="unix:path=/run/user/$UID/bus"
export FZF_DEFAULT_COMMAND="fdfind --type f --hidden --follow --exclude .git"
export FZF_DEFAULT_OPTS="--preview 'batcat --color=always {}'"
alias cat=batcat
alias vial=/home/rpamirov/app_images/Vial-v0.7.5-x86_64.AppImage
alias fixbt='systemctl --user restart pipewire pipewire-pulse wireplumber && sudo systemctl restart bluetooth'

# Personal functions
function toggle-theme() {
	if [[ $1 == "light" ]];then
		kitty +kitten themes --reload-in=all Rosé Pine Dawn
	elif [[ $1 == "dark" ]]; then
		kitty +kitten themes --reload-in=all Rosé Pine
	fi
	}
function start_wayvnc() {
	export WLR_RENDERER=gles2
	systemctl --user restart xdg-desktop-portal-wlr
	pkill -f "^/usr/bin/waybar"
	wayvnc 0.0.0.0 5900
	}

# Local LLMs
export PATH="$PATH:/home/rpamirov/repos/llama.cpp/build/bin"
export OPENAI_API_KEY="sk-no-key-required"
export OPENAI_BASE_URL="http://localhost:8080/v1"

function llama_update() {
	cd $HOME/repos/llama.cpp/
	# rm -rf llama.cpp/build/
	cmake -B build
	cmake --build build --config Release -j 8
}

function qwen_planner() {
    cd $HOME/repos/llama.cpp/build/bin/
		./llama-server \
			--model $HOME/models/qwen3.6-35b/Qwen3.6-35B-A3B-UD-Q3_K_XL.gguf \
			--mmproj $HOME/models/qwen3.6-35b/mmproj-F16.gguf \
			--port 8001 \
			--host 0.0.0.0 \
			--ctx-size 262144 \
			--flash-attn on \
			--temp 1.0 \
			--top-p 0.95 \
			--top-k 20 \
			--min-p 0.0 \
			--presence_penalty 1.5
	}

function qwen_coder() {
    cd $HOME/repos/llama.cpp/build/bin/
    ./llama-server \
        --model $HOME/models/qwen3-next/Q3_K_M.gguf \
        --alias "qwen3-coder-next" \
        --fit on \
			  --ctx-size 145000 \
			  --flash-attn on \
        --cache-reuse 256 \
        --port 8080 \
        --host 0.0.0.0 \
        --jinja \
        --temp 1.0 \
        --top-p 0.95 \
        --top-k 40 \
        --min-p 0.01 \
        --repeat-penalty 1.0
}

# LazyVim
# ===============================================
export PATH="$PATH:/opt/nvim-linux-x86_64/bin"
export EDITOR=nvim
export TERM="screen-256color"
export NVM_DIR="$HOME/.config/nvm"
[ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"  # This loads nvm
[ -s "$NVM_DIR/bash_completion" ] && \. "$NVM_DIR/bash_completion"  # This loads nvm bash_completion

# EVO STUFF
source $HOME/.work_setup
# ===============================================

[ -f ~/.fzf.zsh ] && source ~/.fzf.zsh
eval "$(zoxide init zsh)"
. "$HOME/.local/share/../bin/env"
source /etc/profile.d/golang_path.sh
