#!/bin/env bash

# Source partition script
source partitionDisk3Gpt.sh

# Set default console keyboard
loadkeys fr-latin1

# Function to set font size
set_font_size() {
    echo "--- FOR BIGGER FONT SIZE TYPE 'yes'"
    echo "--- OTHERWISE JUST PRESS 'RETURN'"
    read -r answer
    if [ "$answer" = "yes" ]; then
        setfont ter-124b
    else
        echo "No changes have been made"
    fi
}

# Start the script
set_font_size

# Update system clock
timedatectl

# Function to edit Pacman configuration
editPac() {
    local pFile=/etc/pacman.conf
    sed -i 's/#Color/Color/' $pFile
    sed -i 's/#ParallelDownloads = 5/ParallelDownloads = 10/' $pFile
    sed -i 's/#\[multilib\]/\[multilib\]/' $pFile
    sed -i '91s/#Include = \/etc\/pacman.d\/mirrorlist/Include = \/etc\/pacman.d\/mirrorlist/' $pFile
}

editPac

# Function for disk partitioning with gdisk
gdisk_partition() {
    gdisk /dev/$disk <<EOF
o
Y
n


+1G
ef00
c
BOOT
n




c
2
ROOT
w
Y
EOF
}

# Function for disk partitioning with fdisk
fdisk_partition() {
fdisk /dev/$disk <<EOF
g
n
1

+1G
t
1
n



x
n
1
BOOT
n
2
ROOT
r
w
EOF
}

# Show available disks and choose one
showChooseDisk() {
    echo "--- THESE ARE YOUR DISKS ---"
    fdisk -l | grep "Disk" | grep "/dev/"
    echo "--- ENTER THE LAST 3 CHARACTERS OF THE DISK YOU WANNA USE"
    read -r disk
}

# Partition function
partition() {
    echo
    echo "--- FOR > CUSTOM PARTITIONING TYPE 'c'"
    echo "--- FOR > AUTOMATED PARTITIONING TYPE 'a'"
    echo "--- FOR > SCRIPTED PARTITIONING TYPE 's'---"
    echo
    read -r partAnswer

    if [ "$partAnswer" = "a" ]; then
        showChooseDisk
        echo "--- TYPE 'g' TO USE gdisk"
        echo "OR"
        echo "--- TYPE 'f' TO USE fdisk"
        read -r gORf
        if [ "$gORf" = "g" ]; then
            gdisk_partition
        elif [ "$gORf" = "f" ]; then
            fdisk_partition
        else
            partition
        fi
    elif [ "$partAnswer" = "c" ]; then
        showChooseDisk
        echo "--- MANUAL PARTITIONING WITH cfdisk, gdisk, or fdisk (cf/g/f)"
        read -r custom
        case $custom in
            cf) cfdisk /dev/"$disk" ;;
            g) gdisk /dev/"$disk" ;;
            f) fdisk /dev/"$disk" ;;
            *) echo "--- WRONG ENTRY: TRY AGAIN"; partition ;;
        esac
    elif [ "$partAnswer" = "s" ]; then
        showDisk
    else
        echo "--- WRONG ENTRY: TRY AGAIN"
        partition
    fi
}

partition

# Format partitions
mkfs.vfat -F 32 -n BOOT /dev/"$disk"1
mkfs.btrfs -f -L ROOT /dev/"$disk"2

# Create btrfs subvolumes
mount /dev/"$disk"2 /mnt
cd /mnt
btrfs subvolume create @
btrfs subvolume create @home
cd
umount /mnt

# Mount subvolumes
mount -o rw,noatime,compress=zstd:3,ssd,discard=async,space_cache=v2,subvol=@ /dev/"$disk"2 /mnt
mkdir -p /mnt/{boot,home}
mount -o rw,noatime,compress=zstd:3,ssd,discard=async,space_cache=v2,subvol=@home /dev/"$disk"2 /mnt/home
mount /dev/"$disk"1 /mnt/boot

# Refresh package databases and install base system
reflector --country France,Germany --latest 5 --protocol https --sort rate --save /etc/pacman.d/mirrorlist
pacman -Syy
pacstrap -K /mnt base base-devel linux linux-firmware git nano neovim openssh reflector networkmanager iwd ufw rsync amd-ucode alacritty kitty zsh libvirt

# Generate fstab
genfstab -U /mnt >> /mnt/etc/fstab

# Get the PARTUUID of ROOT
diskid=$(blkid | grep "$disk"2 | grep -o 'PARTUUID="[^"]*"' | sed 's/PARTUUID="//;s/"//')

# Create new user
promptUser() {
    echo "-- ENTER NEW USER NAME --"
    read -r userName
    if [[ ! $userName =~ ^[a-zA-Z][a-zA-Z0-9_-]*$ || ${#userName} -gt 32 ]];then
        echo "-- NOT A VALID USER NAME --"
        echo "-- USER NAME MUST START WITH A LETTER AND CAN ONLY CONSIST OF: --"
        echo "-- LETTERS, DIGITS, HYPHENS '-' AND UNDERSCORES '_' AND --"
        echo "-- CAN BE UP TO 32 CHARACTERS --"
        promptUser
    else
        echo "-- VALID USER NAME: $userName --"
    fi
}
promptUser

# Prompt user for passwords outside the chroot environment
promptRootPasswd() {
echo "--- Enter password for root: "
read -s ROOTPASS
echo "--- Confirm password for root: "
read -s ROOTPASS_CONFIRM

if [ "$ROOTPASS" != "$ROOTPASS_CONFIRM" ]; then
    echo "Passwords do not match."
    promptRootPasswd
else
    echo "-- PASSWORD MATCH --"
fi
}
promptRootPasswd

promptUserPasswd() {
echo "--- Enter password for new user $userName: "
read -s USERPASS
echo "--- Confirm password for new user $userName: "
read -s USERPASS_CONFIRM

if [ "$USERPASS" != "$USERPASS_CONFIRM" ]; then
    echo "Passwords do not match."
    promptUserPasswd
else
    echo "-- PASSWORD MATCH --"
fi
}
promptUserPasswd

# Export passwords as environment variables
export ROOTPASS
export USERPASS



# Password prompt function
#promptPassword() {
#    local password1 password2
#    while true; do
#        read -s -r -p "--- Enter password for $1: " password1
#        echo
#        read -s -r -p "--- Confirm password for $1: " password2
#        echo
#        if [ "$password1" == "$password2" ]; then
#            echo "$password1"
#            return
#        else
#            echo "Passwords do not match. Please try again."
#        fi
#    done
#}

#userPass=$(promptPassword "$userName")
#rootPass=$(promptPassword "root")

#export USERPASS="$userPass"
#export ROOTPASS="$rootPass"

# Chroot and configure system
arch-chroot /mnt << EOF
ln -sf /usr/share/zoneinfo/Europe/Paris /etc/localtime
hwclock --systohc --localtime

reflector --country France,Germany --latest 5 --protocol https --sort rate --save /etc/pacman.d/mirrorlist
pacman -Syyu

sed -i 's/#Color/Color/' $pFile
sed -i 's/#ParallelDownloads = 5/ParallelDownloads = 8/' $pFile
sed -i 's/#\[multilib\]/\[multilib\]/' $pFile
sed -i '91s/#Include = \/etc\/pacman.d\/mirrorlist/Include = \/etc\/pacman.d\/mirrorlist/' $pFile

sed -i 's/#en_US.UTF-8 UTF-8/en_US.UTF-8 UTF-8/' /etc/locale.gen

locale-gen

echo LANG=en_US.UTF-8 > /etc/locale.conf
echo KEYMAP=fr-latin1 > /etc/vconsole.conf
echo arch > /etc/hostname

cat <<EOT >> /etc/hosts
127.0.0.1   localhost
::1         localhost
127.0.1.1   arch.localdomain arch
EOT

bootctl install

cat <<EOT >> /boot/loader/loader.conf
default arch-Hyprland.conf
timeout 3
console-mode max
editor 0
EOT

cat <<EOT >> /boot/loader/entries/arch-Hyprland.conf
title   Arch Linux Hyprland
linux   /vmlinuz-linux
initrd  /amd-ucode.img
initrd  /initramfs-linux.img
options root=PARTUUID=$diskid zswap.enabled=0 rootflags=subvol=@ rw rootfstype=btrfs
EOT

cat <<EOT >> /boot/loader/entries/arch-Hyprland-fallback.conf
title   Arch Linux Hyprland
linux   /vmlinuz-linux
initrd  /amd-ucode.img
initrd  /initramfs-linux-fallback.img
options root=PARTUUID=$diskid zswap.enabled=0 rootflags=subvol=@ rw rootfstype=btrfs
EOT

cat << 'EOT' > /etc/systemd/zram-generator.conf
[zram0]
zram-size = ram / 4
EOT

cat << 'EOT' > /etc/sysctl.d/99-vm-zram-parameters.conf
vm.swappiness = 180
vm.watermark_boost_factor = 0
vm.watermark_scale_factor = 125
vm.page-cluster = 0
EOT

groupadd nordvpn
groupadd libvirt

useradd -m -G nordvpn,libvirt,wheel $userName

echo "@includedir /etc/sudoers.d" >> /etc/sudoers
echo "$userName ALL=(ALL) ALL" >> /etc/sudoers.d/00_$userName
chmod 440 /etc/sudoers.d/*
echo "User $userName has been added to sudoers."

chpasswd <<EOT
$userName:$USERPASS
root:$ROOTPASS
EOT

gpasswd -a $userName nordvpn

systemctl enable NetworkManager.service
systemctl enable sshd.service
systemctl enable libvirtd.service

EOF
