import os
import commands
import sys
import argparse

parser = argparse.ArgumentParser()
parser.add_argument('--desktop_env', help='Desktop Environment: cinnamon gnome mate plasma xfce')
args = parser.parse_args()

if not args.desktop_env or (args.desktop_env == ""):
	desktop_env = "mate"
else:
	if args.desktop_env == "xfce4":
		desktop_env = "xfce"
	else:
		desktop_env = args.desktop_env

print "Desktop Environment: %s" % desktop_env

# configure lightdm
lightdmconfig = open("/etc/lightdm/lightdm.conf", "r")
newlightdmconfig = open("/etc/lightdm/lightdm.conf.new", "w")

for line in lightdmconfig:
    line = line.rstrip("\r\n")

    if(line.startswith("#greeter-user=lightdm")):
        newlightdmconfig.write("greeter-user=lightdm\n")
    elif(line.startswith("#pam-service=lightdm")):
        newlightdmconfig.write("pam-service=lightdm\n")
    elif(line.startswith("#pam-autologin-service=lightdm-autologin")):
        newlightdmconfig.write("pam-autologin-service=lightdm-autologin\n")
    elif(line.startswith("#pam-greeter-service=lightdm-greeter")):
        newlightdmconfig.write("pam-greeter-service=lightdm-greeter\n")
    elif(line.startswith("#greeter-session=")):
        newlightdmconfig.write("greeter-session=lightdm-gtk-greeter\n")
    elif(line.startswith("#user-session=")):
        newlightdmconfig.write("user-session=%s\n" % desktop_env)
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
