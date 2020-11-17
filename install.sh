#!/bin/bash

USER_PASSWORD=""
until [ -n "$USER_PASSWORD" ]
do
  read -s -p "Enter the password for tom: " firstpassword </dev/tty
  echo ""
  read -s -p "Again: " secondpassword </dev/tty
  echo ""

  if [ -n "$firstpassword" ]; then
    if [ $firstpassword == $secondpassword ]; then
      USER_PASSWORD=$firstpassword
    else
      echo -e "Those passwords don't match."
    fi
  else
    echo "You must enter a password."
  fi
done

timedatectl set-ntp true

## New drive only
#parted -s /dev/sda mklabel gpt
#parted -s /dev/sda mkpart ESP fat32 1MiB 512MiB
#parted -s /dev/sda mkpart root ext4 512MiB 100%
#parted -s /dev/sda set 1 esp on
#mkfs.fat -n ESP -F32 /dev/sda1
#mkfs.ext4 /dev/sda2

# Existing drive only
mkfs.fat -n ESP -F32 /dev/sda1
mkfs.ext4 -F /dev/sda2

mount /dev/sda2 /mnt
mkdir /mnt/boot
mount /dev/sda1 /mnt/boot

# Chicago-area mirrors
echo 'Server = http://mirrors.gigenet.com/archlinux/$repo/os/$arch' >> /etc/pacman.d/mirrorlist
echo 'Server = http://mirrors.liquidweb.com/archlinux/$repo/os/$arch' >> /etc/pacman.d/mirrorlist
echo 'Server = http://repo.miserver.it.umich.edu/archlinux/$repo/os/$arch' > /etc/pacman.d/mirrorlist
echo 'Server = http://ftp.osuosl.org/pub/archlinux/$repo/os/$arch' >> /etc/pacman.d/mirrorlist

pacstrap /mnt \
base \
base-devel \
linux \
linux-firmware

genfstab -U /mnt >> /mnt/etc/fstab

arch-chroot /mnt ln -s -f /usr/share/zoneinfo/America/Chicago /etc/localtime
arch-chroot /mnt hwclock --systohc

sed -i "s/#en_US.UTF-8 UTF-8/en_US.UTF-8 UTF-8/" /mnt/etc/locale.gen

arch-chroot /mnt locale-gen

echo -e "LANG=en_US.UTF-8" >> /mnt/etc/locale.conf
echo -e "LANGUAGE=en_US:en" >> /mnt/etc/locale.conf

echo 'pc' > /mnt/etc/hostname

arch-chroot /mnt pacman --sync --refresh --noconfirm \
intel-ucode \
grub \
  dosfstools \
  efibootmgr \
curl \
gnupg \
openssh \
git \
neovim \
pulseaudio \
hunspell \
  hunspell-en_US \
mesa \
libnotify \
cups \
  colord \
  logrotate \
  xdg-utils \
cups-pdf \
man-db \
man-pages \
baobab \
eog \
evince \
file-roller \
  lrzip \
  p7zip \
  squashfs-tools \
  unace \
  unrar \
gdm \
gedit \
gnome-backgrounds \
gnome-calculator \
gnome-clocks \
gnome-color-manager \
gnome-control-center \
  system-config-printer \
gnome-disk-utility \
gnome-keyring \
gnome-screenshot \
gnome-session \
gnome-settings-daemon \
gnome-shell \
gnome-system-monitor \
gnome-terminal \
gnome-themes-extra \
gnome-weather \
mutter \
nautilus \
networkmanager \
sushi \
totem \
  gst-libav \
  gst-plugins-base \
  gst-plugins-good \
  gst-plugins-bad \
  gst-plugins-ugly \
xdg-user-dirs-gtk \
gnome-tweaks \
firefox \
noto-fonts \
noto-fonts-cjk \
noto-fonts-emoji \
noto-fonts-extra

arch-chroot /mnt useradd -m -G wheel,storage -s /bin/bash tom
printf "$USER_PASSWORD\n$USER_PASSWORD" | arch-chroot /mnt passwd
printf "$USER_PASSWORD\n$USER_PASSWORD" | arch-chroot /mnt passwd tom

arch-chroot /mnt sed -i 's/# %wheel ALL=(ALL) ALL/%wheel ALL=(ALL) ALL/' /etc/sudoers

arch-chroot /mnt grub-install --target=x86_64-efi --bootloader-id=grub --efi-directory=/boot
arch-chroot /mnt grub-mkconfig -o "/boot/grub/grub.cfg"

arch-chroot /mnt systemctl enable gdm.service
arch-chroot /mnt systemctl enable NetworkManager.service
arch-chroot /mnt systemctl enable org.cups.cupsd.socket
