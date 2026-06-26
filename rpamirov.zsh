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
[[ -r $HOME/repos/znap/znap.zsh ]] ||
	git clone --depth 1 -- https://github.com/marlonrichert/zsh-snap.git ~/repos/znap
source $HOME/repos/znap/znap.zsh
znap prompt sindresorhus/pure
znap source marlonrichert/zsh-autocomplete
znap source zsh-users/zsh-autosuggestions
znap eval iterm2 'curl -fsSL https://iterm2.com/shell_integration/zsh'
znap function _pyenv pyenv "znap eval pyenv 'pyenv init - --no-rehash'"
compctl -K    _pyenv pyenv
source $ZSH/oh-my-zsh.sh

# LazyVim
# ===============================================
export PATH="$PATH:/opt/nvim-linux-x86_64/bin"
export EDITOR=nvim
export TERM="screen-256color"

# Personal settings 
export PATH="$PATH:$HOME/.local/bin"
export PATH="$PATH:$HOME/.local/bin/:/home/user/.local/kitty.app/bin"
export DBUS_SESSION_BUS_ADDRESS="unix:path=/run/user/$UID/bus"
export FZF_DEFAULT_COMMAND="fdfind --type f --hidden --follow --exclude .git"
export FZF_DEFAULT_OPTS="--preview 'batcat --color=always {}'"
alias cat=batcat
alias vial=$HOME/app_images/Vial-v0.7.5-x86_64.AppImage
alias fixbt='systemctl --user restart pipewire pipewire-pulse wireplumber && sudo systemctl restart bluetooth'

function toggle-theme() {
	if [[ $1 == "light" ]];then
		kitty +kitten themes --reload-in=all Rosé Pine Dawn
	elif [[ $1 == "dark" ]]; then
		kitty +kitten themes --reload-in=all Rosé Pine
	fi
	}
