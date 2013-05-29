#!/bin/bash

set -e -u

sed -i 's/#\(en_US\.UTF-8\)/\1/' /etc/locale.gen
locale-gen

ln -sf /usr/share/zoneinfo/UTC /etc/localtime

usermod -s /bin/zsh root
cp -aT /etc/skel/ /root/

#useradd -m -p "" -g users -G "adm,audio,floppy,log,network,rfkill,scanner,storage,optical,power,wheel" -s /bin/zsh arch

chmod 750 /etc/sudoers.d
chmod 440 /etc/sudoers.d/g_wheel
chown root:root /etc/sudoers
chown -R root:root /etc/sudoers.d

sed -i "s/#Server/Server/g" /etc/pacman.d/mirrorlist

#sed 's#\(^ExecStart=-/sbin/agetty\)#\1 --autologin root#;
#     s#\(^Alias=getty.target.wants/\).\+#\1autologin@tty1.service#' \
#     /usr/lib/systemd/system/getty@.service > /etc/systemd/system/autologin@.service

#systemctl disable getty@tty1.service
#systemctl enable multi-user.target pacman-init.service autologin@.service dhcpcd.service
systemctl enable pacman-init.service
systemctl enable lightdm.service
systemctl enable adb.service

# Symlinks for mkfs
ln -sf /usr/bin/mkfs.btrfs /sbin/mkfs.btrfs
ln -sf /usr/bin/mkfs.ntfs /sbin/mkfs.ntfs

# Default to python2
rm -f /usr/bin/python
ln -sf /usr/bin/python2 /usr/bin/python

# Use current date as version string
echo $(date +"%Y%m%d") > /etc/bbqlinux-version
