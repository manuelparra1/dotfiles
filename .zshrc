export BAT_THEME="Enki-Tokyo-Night"

eval $(gdircolors ~/.dir_colors)

alias ls='ls --color=tty'
#alias ls='ls --color=auto'

export CLICOLOR=true
#export TERM=xterm-kitty

export FZF_DEFAULT_COMMAND='fd --type f'
export FZF_DEFAULT_OPTS='--preview "bat --color=always {}"'

path+=('/Users/dusts/.bin/')
alias chatgpt3s='chatgpt.sh --model gpt-3.5-turbo-0125 --max-tokens 250'
alias chatgpt4s='chatgpt.sh --model gpt-4-0125-preview --max-tokens 250'
#alias fzfvim='nvim $(fzf --preview '\''bat --style=numbers --color=always {}'\'' --query="$1" --exit-0)'

alias fzfvim='nvim $(FZF_DEFAULT_COMMAND="fd --type f -e md -e lua -e txt -e sh -e py -e cpp -e json -e conf -e zshrc" FZF_DEFAULT_OPTS="--preview '\''bat --style=numbers --color=always {}'\''" fzf --query="$1" --exit-0)'

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
# Custom LLM ZSH Plugins
source ~/.config/zsh/plugins/zsh-llm-suggestions/zsh-llm-suggestions.zsh
bindkey '^o' zsh_llm_suggestions_openai # Ctrl + O to have OpenAI suggest a command given a English description
bindkey '^[^o' zsh_llm_suggestions_openai_explain # Ctrl + alt + O to have OpenAI explain a command

# Encryted API Key
gpg -d ~/.bin/openai_api_key.txt.gpg > /tmp/api_key
export OPENAI_KEY=$(cat /tmp/api_key)
export OPENAI_API_KEY=$OPENAI_KEY
rm /tmp/api_key

# Homebrew Settings
export CC=gcc
export CXX=g++
export LDFLAGS="-L/opt/homebrew/opt/readline/lib"
export CPPFLAGS="-I/opt/homebrew/opt/readline/include"
export SPACESHIP_PROMPT_ADD_NEWLINE=false

#  Settings
if [[ "$TERM" == "xterm-kitty" || "$TERM" == "xterm-256color" || "$TERM_PROGRAM" == "WarpTerminal" ]]; then
    export TERM=xterm-256color
    eval "$(starship init zsh)"
fi

# >>> conda initialize >>>
# !! Contents within this block are managed by 'conda init' !!
__conda_setup="$('/opt/homebrew/anaconda3/bin/conda' 'shell.zsh' 'hook' 2> /dev/null)"
if [ $? -eq 0 ]; then
    eval "$__conda_setup"
else
    if [ -f "/opt/homebrew/anaconda3/etc/profile.d/conda.sh" ]; then
        . "/opt/homebrew/anaconda3/etc/profile.d/conda.sh"
    else
        export PATH="/opt/homebrew/anaconda3/bin:$PATH"
    fi
fi
unset __conda_setup
# <<< conda initialize <<<

eval "$(zoxide init zsh)"
