#!/bin/bash

set -e -u

sed -i 's/#\(en_US\.UTF-8\)/\1/' /etc/locale.gen
locale-gen

ln -sf /usr/share/zoneinfo/UTC /etc/localtime

usermod -s /bin/zsh root
cp -aT /etc/skel/ /root/

chmod 750 /etc/sudoers.d
chmod 440 /etc/sudoers.d/g_wheel
chown root:root /etc/sudoers
chown -R root:root /etc/sudoers.d

sed -i "s/#Server/Server/g" /etc/pacman.d/mirrorlist

# Enable services
systemctl enable pacman-init.service
systemctl enable choose-mirror.service
systemctl enable bluetooth.service
systemctl enable lightdm.service
systemctl enable adb.service

# Default to python2
rm -f /usr/bin/python
ln -sf /usr/bin/python2 /usr/bin/python

# Use current date as version string
echo $(date +"%Y%m%d") > /etc/bbqlinux-version
