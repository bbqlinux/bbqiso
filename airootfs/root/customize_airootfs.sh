#!/bin/bash

set -e -u

sed -i 's/#\(en_US\.UTF-8\)/\1/' /etc/locale.gen
locale-gen

usermod -s /usr/bin/zsh root
cp -aT /etc/skel/ /root/
chmod 700 /root

chmod 750 /etc/sudoers.d
chmod 440 /etc/sudoers.d/g_wheel
chown root:root /etc/sudoers
chown -R root:root /etc/sudoers.d

sed -i "s/#Server/Server/g" /etc/pacman.d/mirrorlist
sed -i 's/#\(Storage=\)auto/\1volatile/' /etc/systemd/journald.conf

# Enable services
systemctl enable pacman-init.service
systemctl enable choose-mirror.service
systemctl enable lightdm.service
systemctl enable ntpd.service
systemctl enable adb.service
systemctl enable org.cups.cupsd.service

# Network configuration
systemctl enable dhcpcd.service
systemctl enable NetworkManager.service
systemctl enable systemd-resolved.service
systemctl enable ModemManager.service

# Default to python2
rm -f /usr/bin/python
ln -sf /usr/bin/python2 /usr/bin/python

# Use current date as version string
echo $(date +"%Y%m%d") > /etc/bbqlinux-version
