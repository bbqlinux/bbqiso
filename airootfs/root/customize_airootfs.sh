#!/bin/bash

set -e -u

sed -i 's/#\(en_US\.UTF-8\)/\1/' /etc/locale.gen
locale-gen

usermod -s /usr/bin/zsh root
cp -aT /etc/skel/ /root/

chown -R root:root /etc
chown -R root:root /root
chmod 700 /root

sed -i 's/#\(PermitRootLogin \).\+/\1yes/' /etc/ssh/sshd_config
sed -i "s/#Server/Server/g" /etc/pacman.d/mirrorlist
sed -i 's/#\(Storage=\)auto/\1volatile/' /etc/systemd/journald.conf

sed -i 's/#\(HandleSuspendKey=\)suspend/\1ignore/' /etc/systemd/logind.conf
sed -i 's/#\(HandleHibernateKey=\)hibernate/\1ignore/' /etc/systemd/logind.conf
sed -i 's/#\(HandleLidSwitch=\)suspend/\1ignore/' /etc/systemd/logind.conf

# Enable services
systemctl enable pacman-init.service
systemctl enable choose-mirror.service
systemctl enable lightdm.service
systemctl enable ntpd.service
systemctl enable adb.service
systemctl enable cups.socket
systemctl enable haveged

# Network configuration
systemctl enable dhcpcd.service
systemctl enable NetworkManager.service
systemctl enable systemd-resolved.service
systemctl enable ModemManager.service

# Use current date as version string
echo $(date +"%Y%m%d") > /etc/bbqlinux-version
