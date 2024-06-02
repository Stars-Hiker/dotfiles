#!/bin/env bash

# Set default console keyboard
loadkeys fr-latin1

# Set font size
set_font_size() {
    read -r answer
    if [ "$answer" = "yes" ]; then
        setfont ter-124b
    else
        echo "No changes has been made"
    fi
}

# Where everything begin
echo "If you would prefer a biger font size type yes"
echo "Otherwise type no"
set_font_size

# Update system clock
timedatectl

# Edit Pacman
vim /etc/pacman.conf

pacman -Syy
sleep 1s

# Partition the disks

gdisk_partition() {
    gdisk /dev/$disk<<EOF
g
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

fdisk_partition() {
fdisk /dev/$disk<<EOF
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




partition() {
    echo ""
    echo "---THOOSE ARE YOUR DISKS---"
    echo "---Choose the disk you want to partition for the new install---"
    echo ""
    fdisk -l | grep "Disk" | grep "/dev/"
    echo ""
    echo "Type the last 3 characters of the disk you want to choose"
    echo "Example for /dev/sda type sda"
    echo "Or, for     /dev/vdb type vdb"
    read -r disk

    echo "For a custom partitioning type c"
    echo "For a automated partitioning type a"

    read -r partAnswer
    if [ "$partAnswer" = "a" ];then
        echo "Type g then return to use gdisk"
        echo "Or"
        echo "Type f then return to use fdisk"

        read -r gORf
        if [ "$gORf" = "g" ];then
            gdisk_partition
        elif [ "$gORf" = "f" ];then
            fdisk_partition
        else
            #echo "Please enter g for gdisk or f for fdisk then press return"
            partition
        fi
    elif [ "$partAnswer" = "c" ];then
        echo "You can manualy patition the disk with cfdisk; gdisik or fdisk"
        echo "Enter cf for cfdisk; g for gdisk or f for fdisk"
        read -r custom
        if [ "$custom" = "cf" ];then
            cfdisk /dev/$disk
        elif [ "$custom" = "g" ];then
            gdisk /dev/$disk
        elif [ "$custom" = "f" ];then
            fdisk /dev/$disk
        else
            echo "wrong entry: Try again"
        fi
    else
        echo "Please enter c or a "
        partition
    fi
}


partition

#-------------------------------------------------------------------
# Foramt partition

mkfs.vfat -F 32 -n BOOT /dev/"$disk"1
mkfs.btrfs -f -L ROOT /dev/"$disk"2

#-------------------------------------------------------------------
# Make zramSwap

cat << 'EOF' > /etc/systemd/zram-generator.conf
[zram0]
zram-size = ram / 4
EOF

cat << 'EOF' > /etc/sysctl.d/99-vm-zram-parameters.conf
vm.swappiness = 180
vm.watermark_boost_factor = 0
vm.watermark_scale_factor = 125
vm.page-cluster = 0
EOF

#----------------------------------------------------------------
# Make btrfs subvolumes

mount /dev/vda2 /mnt
cd /mnt
btrfs su cr @
btrfs su cr @home
#btrfs su cr @snapshots
cd
umount /mnt

mount -o rw,noatime,compress=zstd:3,ssd,discard=async,space_cache=v2,subvol=@ /dev/vda2 /mnt

mkdir -p /mnt/{boot,home}

mount -o rw,noatime,compress=zstd:3,ssd,discard=async,space_cache=v2,subvol=@home /dev/vda2 /mnt/home

mount  /dev/vda1 /mnt/boot

pacman -Syy

sleep 2s

pacstrap -K /mnt base base-devel linux linux-firmware git nano neovim openssh reflector networkmanager iwd ufw rsync amd-ucode systemd-sysvcompat

genfstab -U /mnt >> /mnt/etc/fstab

arch-chroot /mnt << EOF

pacman -Syyu
sleep 1s

ln -sf /usr/share/zoneinfo/Europe/Paris /etc/localtime

hwclock --systohc --localtime

reflector --country France,Germany --latest 5 --sort rate --save /etc/pacman.d/mirrorlist

pacman -Syy

nvim /etc/locale.gen

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
default arch.conf
timeout 3
console-mode max
editor 0
EOT


cat <<EOT >> /boot/loader/entries/arch.conf
title   Arch Linux
linux   /vmlinuz-linux
initrd  /initramfs-linux.img
options root=PARTUUID= zswap.enabled=0 rootflags=subvol=@ rw rootfstype=btrfs
EOT

sleep 3s

cat <<EOT >> /boot/loader/entries/arch-fallback.conf
title   Arch Linux
linux   /vmlinuz-linux
initrd  /initramfs-linux-fallback.img
options root=PARTUUID= zswap.enabled=0 rootflags=subvol=@ rw rootfstype=btrfs
EOT


cat /boot/loader/entries/arch.conf
sleep 3s
bootctl list

systemctl enable NetworkManager.service
systemctl enable sshd.service
EOF
