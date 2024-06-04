#!/bin/env bash

installAURpackages() {
    paru -S --needed $(cat ~/git/dotfiles/hyprPackages/foreignLatest.txt)
}

gitparu() {
    if pacman -Q paru &> /dev/null; then
        installAURpackages
    else
        git clone https://aur.archlinux.org/paru-bin.git ~/AUR/paru-bin
        cd ~/AUR/paru-bin
        makepkg -sicC 
        installAURpackages
    fi
}

installParu() {
    if [ -d ~/AUR ];then
        gitparu
    else
        mkdir ~/AUR
        gitparu
    fi
    
}

installPackages(){
    sudo pacman -Syu --needed $(cat ~/git/dotfiles/hyprPackages/nativeLatest.txt)
    installParu
}

sync() {
    sudo pacman -Syyu
    installPackages
}
sync

broot --install
