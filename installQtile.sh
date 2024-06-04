sudo pacman -Syyu --needed xorg-server xorg-xinit qtile

echo "exec qtile start" > ~/.xinitrc
export DISPLAY=:0

sudo usermod -aG video,input $USER

confPath=~/.config/qtile/config.py

xkbInstall() {
	git clone https://aur.archlinux.org/xkb-switch.git
	cd xkb-switch
	makepkg -si
}

sed -i 's/from libqtile import bar, layout, qtile, widget/from libqtile import bar, layout, qtile, widget, hook/' $confPath

echo "import subprocess" >> $confPath
echo "@hook.subscribe.startup_once" >> $confPath
echo "def set_default_layout():" >> $confPath
echo "    subprocess.run([\"setxkbmap\", \"fr\"])" >> $confPath



sudo pacman -Syu lightdm lightdm-gtk-greeter
sudo systemctl enable lightdm
sudo systemctl start lightdm

