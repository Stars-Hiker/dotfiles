#!/bin/env bash

installAURpackages() {
    paru -S --needed $(cat ~/Backup/Packages/packagesForeign1.txt)
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
    sudo pacman -Syu --needed $(cat ~/Backup/Packages/packagesNative1.txt)
    installParu
}

sync() {
    sudo pacman -Syyu
    installPackages
}
sync


