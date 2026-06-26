
source $HOME/repos/dotfiles/rpamirov.zsh
# EVO STUFF
source $HOME/.work_setup
source $HOME/repos/dotfiles/evo_llama.zsh

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
