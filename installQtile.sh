sudo pacman -Syu xorg-server xorg-xinit qtile

echo "exec qtile start" > ~/.xinitrc
export DISPLAY=:0
startx

sudo usermod -aG video,input $USER

#sudo pacman -Syu lightdm lightdm-gtk-greeter
#sudo systemctl enable lightdm
#sudo systemctl start lightdm

