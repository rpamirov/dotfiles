# Omarchy environment (OMARCHY_PATH + PATH), needed even for non-interactive shells
[[ -r /usr/share/omarchy/default/bash/env-bootstrap ]] && source /usr/share/omarchy/default/bash/env-bootstrap

# If not running interactively, don't do anything else (leave this above the rc source)
[[ $- != *i* ]] && return

# All the default Omarchy aliases and functions
# (don't mess with these directly, just overwrite them here!)
source "$OMARCHY_PATH/default/bash/rc"

# EvoCargo local environment
source ~/.evo_setup
export PATH="$QA_TOOLS_PATH/.venv/bin:$PATH"
source "$QA_TOOLS_PATH/configs/dotfiles/aliases.sh"

# LLM
export LLAMA=/home/rpamirov/Repos/llama.cpp
source ~/Repos/dotfiles/evo_llama.bash

# Qwen Code PATH block begin
export PATH='/home/rpamirov/.local/bin':$PATH
# Qwen Code PATH block end
