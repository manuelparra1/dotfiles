# Enable Powerlevel10k instant prompt. Should stay close to the top of ~/.zshrc.
# Initialization code that may require console input (password prompts, [y/n]
# confirmations, etc.) must go above this block; everything else may go below.
if [[ -r "${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-${(%):-%n}.zsh" ]]; then
  source "${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-${(%):-%n}.zsh"
fi

# Custom path & aliases
path+=('/home/dusts/.bin/')
alias nvim="nvim.appimage"
alias kitty="bigkitty.sh"
alias chatgpt3\+="chatgpt.sh --model gpt-3.5-turbo-1106 --max-tokens 4000"
alias chatgpt3="chatgpt.sh --model gpt-3.5-turbo-1106 --max-tokens 1000"
alias chatgpt3min="chatgpt.sh --model gpt-3.5-turbo-1106 --max-tokens 250"

alias chatgpt4="chatgpt.sh --model gpt-4-1106-preview --max-tokens 500"
alias chatgpt4+="chatgpt.sh --model gpt-4-1106-preview --max-tokens 4000"

alias fd="fdfind"
export LANG=en_US.UTF-8
export TERM='xterm-256color'
export PATH

# API Key Retrieval using pass
export OPENAI_API_KEY=$(pass openai/api_key)
export OPENAI_KEY=$OPENAI_API_KEY


source ~/.powerlevel10k/powerlevel10k.zsh-theme

# To customize prompt, run `p10k configure` or edit ~/.p10k.zsh.
[[ ! -f ~/.p10k.zsh ]] || source ~/.p10k.zsh

# >>> conda initialize >>>
# !! Contents within this block are managed by 'conda init' !!
__conda_setup="$('/home/dusts/anaconda3/bin/conda' 'shell.zsh' 'hook' 2> /dev/null)"
if [ $? -eq 0 ]; then
    eval "$__conda_setup"
else
    if [ -f "/home/dusts/anaconda3/etc/profile.d/conda.sh" ]; then
        . "/home/dusts/anaconda3/etc/profile.d/conda.sh"
    else
        export PATH="/home/dusts/anaconda3/bin:$PATH"
    fi
fi
unset __conda_setup
# <<< conda initialize <<<
