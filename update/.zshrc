export BAT_THEME="Enki-Tokyo-Night"
eval $(dircolors ~/.bliss_dircolors)
# eval $(dircolors ~/.dracula_dircolors)

# alias ls='ls --color=tty'
alias ls='ls --color=auto'

export CLICOLOR=true

path+=('/home/dusts/.bin/')
path+=("/mnt/c/bin/")
alias chatgpt4o-mini='chatgpt.sh -i "respond in a simple and concise manner" --model gpt-4o-mini --max-tokens 500'
alias chatgpt4o='chatgpt.sh -i "respond in a simple and concise manner" --model chatgpt-4o-latest --max-tokens 250'
# BlueBirdBack/groq
alias groq='python ~/.bin/groq/scripts/run_groq.py short'

#alias fzfvim='nvim $(fzf --preview '\''bat --style=numbers --color=always {}'\'' --query="$1" --exit-0)'
#alias fzfvim='nvim "$(FZF_DEFAULT_COMMAND="fd --type f -e md -e lua -e txt -e sh -e py -e cpp -e json -e conf -e zshrc" FZF_DEFAULT_OPTS="--preview '\''bat --style=numbers --color=always {}'\''" fzf --query="$1" --exit-0)"'

fzfvim() {
    local query="${1:-}"
    
    FZF_DEFAULT_COMMAND="fd -H --type f -e md -e lua -e txt -e sh -e py -e cpp -e json -e conf -e zshrc" \
    FZF_DEFAULT_OPTS="--preview 'bat --style=numbers --color=always {}' --bind 'change:reload:fd -H --type f -e md -e lua -e txt -e sh -e py -e cpp -e json -e conf -e zshrc {q} || true'" \
    fzf --ansi --phony --query="$query" --exit-0 | while IFS= read -r file; do
        nvim "$file"
    done
}

livegrep() {
    local search_dir="${1:-.}"

    # Start fzf with an initial query or empty and configure it to call rg upon query change
    FZF_DEFAULT_COMMAND="rg --column --line-number --no-heading --color=always --smart-case '' $search_dir" \
    fzf --ansi \
        --bind "change:reload:rg --column --line-number --no-heading --color=always --smart-case {q} $search_dir" \
        --delimiter ':' \
        --preview 'bat --style=numbers --color=always --highlight-line {2} --line-range {2}: {1}' \
        --preview-window 'right:50%:wrap' \
        --phony \
        --query='' \
        | while IFS=: read -r file line _; do
            nvim "+normal! ${line}G" "$file"
        done
}

export GROQ_API_KEY="insert_here"
export OPENAI_KEY="insert_here"
export OPENAI_API_KEY=$OPENAI_KEY


# =================================================================================================
# ZenSH
# =================================================================================================

# Plugin Settings

# fzf-tab
autoload -Uz compinit && compinit

# ZSH Plugins
source ~/.config/zsh/plugins/fzf-tab/fzf-tab.plugin.zsh
source ~/.config/zsh/plugins/zsh-llm-suggestions/zsh-llm-suggestions.zsh
source ~/.config/zsh/plugins/zsh-syntax-highlighting/zsh-syntax-highlighting.plugin.zsh
source ~/.config/zsh/plugins/zsh-autosuggestions/zsh-autosuggestions.plugin.zsh
source ~/.config/zsh/plugins/zsh-completions/zsh-completions.plugin.zsh

# Plugin Keybindings
bindkey '^o' zsh_llm_suggestions_openai # Ctrl + O to have OpenAI suggest a command given a English description
bindkey '^[^o' zsh_llm_suggestions_openai_explain # Ctrl + alt + O to have OpenAI explain a command

# Plugin Settings
# zsh-completions - Load completions
fpath=(~/.config/zsh/plugins/zsh-completions/src $fpath)

# Keybindings
bindkey -e
bindkey '^p' history-search-backward
bindkey '^n' history-search-forward
bindkey '^[w' kill-region

# History
HISTSIZE=5000
HISTFILE=~/.zsh_history
SAVEHIST=$HISTSIZE
HISTDUP=erase
setopt appendhistory
setopt sharehistory
setopt hist_ignore_space
setopt hist_ignore_all_dups
setopt hist_save_no_dups
setopt hist_ignore_dups
setopt hist_find_no_dups

# Completion styling
zstyle ':completion:*' matcher-list 'm:{a-z}={A-Za-z}'
zstyle ':completion:*' list-colors "${(s.:.)LS_COLORS}"
zstyle ':completion:*' menu no
zstyle ':fzf-tab:complete:cd:*' fzf-preview 'ls --color $realpath'
zstyle ':fzf-tab:complete:__zoxide_z:*' fzf-preview 'ls --color $realpath'

# Shell integrations
eval "$(fzf --zsh)"
eval "$(zoxide init --cmd cd zsh)"
# =================================================================================================
# ZenSH
# =================================================================================================

#  Settings
if [[ "$TERM" == "xterm-kitty" || "$TERM" == "xterm-256color" || "$TERM_PROGRAM" == "WarpTerminal" ]]; then
    export TERM=xterm-256color
    eval "$(starship init zsh)"
fi

eval "$(zoxide init zsh)"

# >>> conda initialize >>>
# !! Contents within this block are managed by 'conda init' !!
__conda_setup="$('/home/dusts/.anaconda3/bin/conda' 'shell.zsh' 'hook' 2> /dev/null)"
if [ $? -eq 0 ]; then
    eval "$__conda_setup"
else
    if [ -f "/home/dusts/.anaconda3/etc/profile.d/conda.sh" ]; then
        . "/home/dusts/.anaconda3/etc/profile.d/conda.sh"
    else
        export PATH="/home/dusts/.anaconda3/bin:$PATH"
    fi
fi
unset __conda_setup
# <<< conda initialize <<<

