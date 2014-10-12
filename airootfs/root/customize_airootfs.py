import os
import commands
import sys


# configure lightdm
lightdmconfig = open("/etc/lightdm/lightdm.conf", "r")
newlightdmconfig = open("/etc/lightdm/lightdm.conf.new", "w")

for line in lightdmconfig:
    line = line.rstrip("\r\n")
    if(line.startswith("#greeter-session=")):
        newlightdmconfig.write("greeter-session=lightdm-gtk-greeter\n")
    elif(line.startswith("#user-session=")):
        newlightdmconfig.write("user-session=mate\n")
    elif(line.startswith("#autologin-user=")):
        newlightdmconfig.write("autologin-user=bbqlinux\n")
    elif(line.startswith("#autologin-user-timeout=0")):
        newlightdmconfig.write("autologin-user-timeout=0\n")
    else:
        newlightdmconfig.write("%s\n" % line)

lightdmconfig.close()
newlightdmconfig.close()

os.system("rm /etc/lightdm/lightdm.conf")
os.system("mv /etc/lightdm/lightdm.conf.new /etc/lightdm/lightdm.conf")


# configure pacman
pacmanconf = open("/etc/pacman.conf", "r")
newpacmanconf = open("/etc/pacman.conf.new", "w")

for line in pacmanconf:
    line = line.rstrip("\r\n")
    if(line.startswith("IgnorePkg")):
        newpacmanconf.write("#IgnorePkg   =\n")
    else:
        newpacmanconf.write("%s\n" % line)

pacmanconf.close()
newpacmanconf.close()

os.system("rm /etc/pacman.conf")
os.system("mv /etc/pacman.conf.new /etc/pacman.conf")


# configure cups
cupsconf = open("/etc/cups/cups-files.conf", "r")
newcupsconf = open("/etc/cups/cups-files.conf.new", "w")

for line in cupsconf:
    line = line.rstrip("\r\n")
    if(line.startswith("SystemGroup")):
        newcupsconf.write("SystemGroup sys root lpadmin\n")
    else:
        newcupsconf.write("%s\n" % line)

cupsconf.close()
newcupsconf.close()

os.system("rm /etc/cups/cups-files.conf")
os.system("mv /etc/cups/cups-files.conf.new /etc/cups/cups-files.conf")
