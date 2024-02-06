# ThinkPad X220 Linux Guide

## Bootable USB

macOS Terminal

```bash
diskutil list
diskutil unmountDisk /dev/disk4

sudo dd if=Zorin-OS-16.3-Lite-64-bit.iso of=/dev/rdisk4 bs=1m
```

### Starter Pack

```bash
git kitty zsh fd ripgrep bat fzf curl vim go rust
```

### ZSH

```bash
chsh -s $(which zsh)
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

### PowerLevel10K

```bash
git clone --depth=1 https://github.com/romkatv/powerlevel10k.git ~/powerlevel10k
echo 'source ~/powerlevel10k/powerlevel10k.zsh-theme' >>~/.zshrc

```



### Neovim

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

