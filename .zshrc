export BAT_THEME="Catppuccin Mocha"
export HYPRSHOT_DIR="$HOME/Pictures/Screenshots/"
eval $(dircolors ~/.dir_colors)

# export QT_QPA_PLATFORM=xcb vlc
alias ls='eza -1rs oldest'
alias ll='eza -lhs newest'

alias dictionary='~/Scripts/dictionary.py'

export CLICOLOR=true

# Add ~/.local/bin to PATH for custom scripts
export PATH="$HOME/.local/bin:$PATH"

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
    
    # Set the initial command to only show readable files
    FZF_DEFAULT_COMMAND="fd -H --type f -e md -e lua -e txt -e sh -e py -e cpp -e json -e conf -e zshrc -e js -e ts -e html -e css -e yml -e yaml -e xml -e toml -e ini -e cfg -e log -e sql -e rs -e go -e java -e c -e h -e rb -e php -e pl -e vim -e rc" \
    fzf --phony --query '' \
        --bind "change:reload:sh -c '
          query=\"\$1\"
          if [ -z \"\$query\" ]; then
            # Empty query: list all readable files
            fd -H --type f -e md -e lua -e txt -e sh -e py -e cpp -e json -e conf -e zshrc -e js -e ts -e html -e css -e yml -e yaml -e xml -e toml -e ini -e cfg -e log -e sql -e rs -e go -e java -e c -e h -e rb -e php -e pl -e vim -e rc
          else
            # Get readable files first, then search within them
            fd -H --type f -e md -e lua -e txt -e sh -e py -e cpp -e json -e conf -e zshrc -e js -e ts -e html -e css -e yml -e yaml -e xml -e toml -e ini -e cfg -e log -e sql -e rs -e go -e java -e c -e h -e rb -e php -e pl -e vim -e rc -0 | xargs -0 rg -l \"\$query\" 2>/dev/null || true
          fi
        ' _ {q} || true" \
        --delimiter ':' \
        --preview 'file={1}; last_word=$(echo {q} | awk "{print \$NF}"); if [ -n "$last_word" ]; then line=$(rg --line-number --no-heading --smart-case "$last_word" "$file" 2>/dev/null | head -n1 | cut -d: -f1); if [ -n "$line" ]; then start_line=$((line - 5)); if [ $start_line -lt 1 ]; then start_line=1; fi; end_line=$((line + 45)); bat --style=numbers --color=always --highlight-line "$line" --line-range "$start_line:$end_line" "$file" 2>/dev/null; else bat --style=numbers --color=always "$file" 2>/dev/null; fi; else bat --style=numbers --color=always "$file" 2>/dev/null; fi' \
        --preview-window 'right:50%:wrap' \
        --bind 'enter:execute:last_word=$(echo {q} | awk "{print \$NF}"); if [ -n "$last_word" ]; then line=$(rg --line-number --no-heading --smart-case "$last_word" {1} 2>/dev/null | head -n1 | cut -d: -f1); nvim "+${line:-1}" {1}; else nvim {1}; fi'
}

# livegrep() {
#     local search_dir="${1:-.}"
#
#     # Start fzf with an initial query or empty and configure it to call rg upon query change
#     FZF_DEFAULT_COMMAND="rg --column --line-number --no-heading --color=always --smart-case '' $search_dir" \
#     fzf --ansi \
#         --bind "change:reload:rg --column --line-number --no-heading --color=always --smart-case {q} $search_dir" \
#         --delimiter ':' \
#         --preview 'bat --style=numbers --color=always --highlight-line {2} --line-range {2}: {1}' \
#         --preview-window 'right:50%:wrap' \
#         --phony \
#         --query='' \
#         | while IFS=: read -r file line _; do
#             nvim "+normal! ${line}G" "$file"
#         done
# }

# =================================================================================================
# ZenSH
# =================================================================================================

# Plugin Settings

# fzf-tab
autoload -Uz compinit && compinit

# Plugins
source ~/.config/zsh/plugins/zsh-syntax-highlighting/Themes/catppuccin_mocha-zsh-syntax-highlighting.zsh

# ZSH Plugins
source ~/.config/zsh/plugins/fzf-tab/fzf-tab.plugin.zsh
source ~/.config/zsh/plugins/zsh-syntax-highlighting/zsh-syntax-highlighting.plugin.zsh
source ~/.config/zsh/plugins/zsh-autosuggestions/zsh-autosuggestions.plugin.zsh
source ~/.config/zsh/plugins/zsh-completions/zsh-completions.plugin.zsh
source ~/.config/zsh/plugins/zsh-groq-llm/zsh-llm-suggestions.zsh

# Plugin Keybindings
bindkey '^o' zsh_llm_suggestions_groq # Ctrl + O to have Groq suggest a command

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
# eval "$(fzf --zsh)"
eval "$(zoxide init --cmd cd zsh)"

# =================================================================================================
# ZenSH
# =================================================================================================

#  Settings
if [[ "$TERM" == "xterm-kitty" || "$TERM" == "xterm-256color" || "$TERM_PROGRAM" == "WarpTerminal" ]]; then
# if [[ "$TERM" == "xterm-kitty" || "$TERM" == "tmux-256color" || "$TERM_PROGRAM" == "WarpTerminal" ]]; then
    # export TERM=xterm-256color
    eval "$(starship init zsh)"
fi

#eval "$(zoxide init zsh)"

# 1) Plain function for loading conda
function conda_on_demand_function() {
    echo "Activated default Anaconda environment"
    eval "$(/home/dusts/.miniconda3/bin/conda shell.zsh hook 2>/dev/null)"
    # Optionally: automatically activate a specific env here
    # conda activate myenv
}

# 2) ZLE widget that calls the function, then resets prompt
function conda_on_demand_widget() {
    conda_on_demand_function
    zle reset-prompt
}

# Declare the widget and bind Alt+c to it
zle -N conda_on_demand_widget
bindkey '^[c' conda_on_demand_widget
