# Fresh Install Guide

# OS

## Arch

## Starter Pack

**Debian-Based**

```bash
sudo apt install git zsh bat fd-find ripgrep fzf jq
```

**Arch-Based**

```bash
sudo pacman -S git zsh bat fd ripgrep fzf jq
```

## Shell

### ZSH

```bash
chsh -s $(which zsh)

git clone https://github.com/manuelparra1/dotfiles
cp dotfiles/.zshrc ~/.zshrc
```

### Kitty

```bash
~/.config/kitty/kitty.conf

include themes/frappe.conf
term=xterm-256color
map cmd+f toggle_fullscreen

font_family      MesloLGS NF
font_size 28.0
```

### Starship

```bash
curl -sS https://starship.rs/install.sh | bash

echo 'eval "$(starship init zsh)"' >> ~/.zshrc
starship preset pastel-powerline -o ~/.config/starship.toml
conda config --set changeps1 False
```

### ChatGPT

```bash
curl -sS https://raw.githubusercontent.com/0xacx/chatGPT-shell-cli/main/install.sh | sudo -E bash
```

## Anaconda

## Desktop Environment

### Mount APFS

```bash
sudo apt install fuse build-essential libfuse3-dev libattr1-dev bzip2 libbz2-dev cmake g++ git zlib1g-dev
```

### Mount HFS+

```bash
sudo apt-get update
sudo apt-get install hfsprogs
sudo mount -t hfsplus /dev/sdb2 '/mnt/Seagate 4TB #1'
sudo mount /dev/sdb2 '/mnt/Seagate 4TB #1'
```
