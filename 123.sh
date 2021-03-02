#!/bin/bash

#/dev/sda1 - /boot
#/dev/sda2 - / 
#/dev/sda3 - swap
#/dev/sda4 - /home


# Ставим быстрые репы

> /etc/pacman.d/mirrorlist
cat <<EOF >>/etc/pacman.d/mirrorlist

##
## Arch Linux repository mirrorlist
## Generated on 2020-01-02
##

## Russia
Server = http://mirror.rol.ru/archlinux/\$repo/os/\$arch
Server = https://mirror.rol.ru/archlinux/\$repo/os/\$arch
Server = http://mirror.truenetwork.ru/archlinux/\$repo/os/\$arch  
Server = http://mirror.yandex.ru/archlinux/\$repo/os/\$arch
Server = https://mirror.yandex.ru/archlinux/\$repo/os/\$arch
Server = http://archlinux.zepto.cloud/\$repo/os/\$arch

EOF

# Активируем новые репы
pacman-key --init
pacman-key --populate archlinux
pacman -Sy


#Форматируем в ext 4 наш диск
cfdisk

mkfs.ext2  /dev/sda1 -L boot

mkfs.ext4 /dev/sda2 -L root


# Монтируем диск к папке

mount /dev/sda2 /mnt

mkdir -p /mnt/boot

mount /dev/sda1 /mnt/boot


#Устанавливаем based  и linux ядро + софт который нам нужен сразу
pacstrap /mnt base base-devel linux linux-headers vim bash-completion grub # parted

# прописываем fstab
genfstab -pU /mnt >> /mnt/etc/fstab

#Прокидываем правильные быстрые репы внутрь
cp /etc/pacman.d/mirrorlist /mnt/etc/pacman.d/mirrorlist


# Делаем скрипт пост инстала:
cat <<EOF  >> /mnt/opt/install.sh
#!/bin/bash



echo "en_US.UTF-8 UTF-8" > /etc/locale.gen
echo "ru_RU.UTF-8 UTF-8" >> /etc/locale.gen
echo 'Обновим текущую локаль системы'
locale-gen
echo 'Указываем язык системы'
echo 'LANG="ru_RU.UTF-8"' > /etc/locale.conf

echo 'Вписываем KEYMAP=ru FONT=cyr-sun16'
echo 'KEYMAP=ru' >> /etc/vconsole.conf
echo 'FONT=cyr-sun16' >> /etc/vconsole.conf


sleep 1
ln -sf /usr/share/zoneinfo/Europe/Moscow /etc/localtime
echo "/dev/sda /    ext4 defaults 0 1" > /etc/fstab
grub-install /dev/sda
grub-mkconfig -o /boot/grub/grub.cfg
pacman-key --init
pacman-key --populate archlinux
pacman  -Sy xorg xorg-server lxdm networkmanager network-manager-applet chromium nano i3-gaps i3status dmenu terminator gparted vim --noconfirm
pacman  -Sy xfce4 xfce4-goodies

pacman -S git glibc lib32-glibc --noconfirm
git clone https://aur.archlinux.org/yay.git
cd yay
makepkg -si

pacman -S xdg-user-dirs --noconfirm
xdg-user-dirs-update

echo 'Установка базовых программ и пакетов'
pacman -S reflector firefox firefox-i18n-ru ufw f2fs-tools dosfstools ntfs-3g alsa-lib alsa-utils file-roller p7zip unrar gvfs aspell-ru pulseaudio pavucontrol --noconfirm

pacman -S recoll chromium flameshot obs-studio veracrypt vlc freemind filezilla gimp libreoffice libreoffice-fresh-ru kdenlive neofetch qbittorrent galculator telegram-desktop viewnior --noconfirm
yay -Syy
yay -S xflux sublime-text-dev hunspell-ru pamac-aur-git megasync-nopdfium trello xorg-xkill ttf-symbola ttf-clear-sans --noconfirm
sudo pacman -S  i3-wm dmenu pcmanfm ttf-font-awesome feh gvfs udiskie xorg-xbacklight ristretto tumbler compton jq --noconfirm
yay -S polybar ttf-weather-icons ttf-clear-sans --noconfirm
git clone https://github.com/dima42866-lang/i3wm
rm -rf ~/.config/i3/*
rm -rf ~/.config/polybar/*
tar -xzf config_i3wm.tar.gz -C ~/

grep -r -l '#greeter-session=example-gtk-gnome' /etc/lightdm/lightdm.conf | xargs sed -i 's/\#greeter-session\=example-gtk-gnome/greeter-session\=lightdm-deepin-greeter/g'
#stemctl start lightdm.service
systemctl enable lxdm.service
systemctl enable NetworkManager.service
sleep 1
echo "password for root user:"
passwd
echo "add new user"
useradd -m -g users -s /bin/bash z
echo "paaswd for new user"
passwd z

usermod --append --groups wheel z

echo 'Устанавливаем SUDO'
echo '%wheel ALL=(ALL) ALL' >> /etc/sudoers


umount -R /mnt

exit


EOF

arch-chroot /mnt /bin/bash  /opt/install.sh

#reboot
