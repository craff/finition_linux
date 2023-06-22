#!/bin/bash

# Do not enter interactive config
export DEBIAN_FRONTEND=noninteractive

# eole proxy
PROXY=10.53.0.1
PROXY_PORT=3128
DOMAIN=lyclpg

# configuration of local ntlm with NoAuth matching eole exception that requires no authentication
NTML_CONF_URL=https://ent.lyclpg.itereva.pf/nextcloud/index.php/s/4XHCgPWpTeFqKLX/download
# example:
# NoProxy localhost,127.0.0.*,10.*,192.168.*,172.16.*
# NoAuth archive.canonical.com,archive.ubuntu.com,fr.archive.ubuntu.com,nperf.com,\
# packagecloud.io,packages.linuxmint.com,packages.microsoft.com,www.microsoft.com,\
# security.ubuntu.com,jupyter.numpf.xyz,studio.numpf.xyz,contest.numpf.xyz,\
# bash.numpf.xyz,d28dx6y1hfq314.cloudfront.net

ENT_HOST=lyclpg.itereva.pf

LDAP_HOST=172.18.0.3
LDAP_PORT=389

SAMBA_HOST=$LDAP_HOST

RUN_SCRIPT_HOST=10.53.23.101
RUN_SCRIPT_USER=run_script
RUN_SCRIPT_PASS=qZ3aA!x35
RUN_SCRIPT_DB=scripts

GLPI_HOST=10.53.23.90

######################
# END OF CONFIGURATION
######################

echo use proxy: $PROXY:$PROXY_PORT

# USE proxy: need to open the proxy while creating linux image
# All hosts we use during installation must be configured without authentication in eole

export http_proxy=http://$PROXY:$PROXY_PORT/
export https_proxy=http://$PROXY:$PROXY_PORT/
export wss_proxy=http://$PROXY:$PROXY_PORT/
export ftp_proxy=http://$PROXY:$PROXY_PORT/

# ====================
# grub : windows first
# ====================

echo grub installation
if [ -f /etc/grub.d/30_os-prober ]; then
    mv /etc/grub.d/30_os-prober /etc/grub.d/09_os-prober
fi

if [ -e /dev/sda3 ]; then
  cp grub/grub /etc/default/grub
else
  cp grub/grub-single /etc/default/grub
fi

update-grub

# ==========================================
# network: configuration via /etc interfaces
# ==========================================

# With latest update, network manager seems not to give
# issues. Let it enabled, so it reports network working
# to users.

echo configure network
systemctl stop network-manager
cp network/interfaces /etc/network/
systemctl restart networking
systemctl start network-manager
systemctl enable network-manager

# =====================================================
# lightdm login by typing username. Necessary with ldap
# =====================================================

echo install lightdm configuration file for ldap
if [ -d /etc/lightdm ]; then
    cp lightdm/lightdm.conf /etc/lightdm/
fi

# ================================
# upgrade and install all packages
# ================================

echo upgrading and installing packages

apt-get -y update
apt-get -y upgrade
apt-cache dumpavail | dpkg --merge-avail
dpkg --set-selections < apt/dpkg.txt
apt-get -y update
apt-get -y dselect-upgrade

# extra packages

#wget https://www.lernsoftware-filius.de/downloads/Setup/filius_1.14.2_all.deb
#wget https://github.com/jgraph/drawio-desktop/releases/download/v19.0.3/drawio-amd64-19.0.3.deb
#wget https://github.com/shiftkey/desktop/releases/download/release-2.9.3-linux3/GitHubDesktop-linux-2.9.3-linux3.deb
# TODO: find latest version of .deb below, we get the .deb because proxy is not working at install time
# another solution is to add exception to eole.

apt-get install -y ./debs/*.deb

# ==================
# ldap configuration
# ==================

# USE VARIABLES: LDAP_HOST LDAP_PORT
apt-get install -y libnss-ldap nslcd ldap-utils nslcd-utils libpam-ldapd libpam-fscrypt libpam-mount \
                   libpam-kwallet5

sed -e "s/{LDAP_HOST}/$LDAP_HOST/g" -e "s/{LDAP_PORT}/$LDAP_PORT/g" ldap/ldap.conf > /etc/ldap.conf
sed -e "s/{LDAP_HOST}/$LDAP_HOST/g" -e "s/{LDAP_PORT}/$LDAP_PORT/g" ldap/nslcd.conf > /etc/nslcd.conf
cp ldap/nsswitch.conf /etc/

# =================
# user's dirs mount
# =================

sed -e "s/{SAMBA_HOST}/$SAMBA_HOST/g" pam_mount/pam_mount.conf.xml > /etc/security/pam_mount.conf.xml
cp pam_mount/user-dirs.defaults /etc/xdg/

# ====================================
# cntlm installation and configuration
# ====================================

# To use authenticated proxy, we install a cntlm proxy on the machine that
# will authentify the user against the eole proxy (which is cntlm too)

# pam_script also copies /etc/skel in the user's home at login
# allows fixing problem without the user doing anything by just
# updating /etc/skel/profile

apt-get install -y libpam-script cntlm

# cntlm need not tu be started at boot. It is started at login time by pam_script
systemctl stop cntlm
systemctl disable cntlm

# default  file installation
sed -e "s/{ENT_HOST}/$ENT_HOST/g" NTLM/environment > /etc/environment

sed -e "s/{PROXY}/$PROXY/g" -e "s/{PROXY_PORT}/$PROXY_PORT/g" \
    -e "s/{NTML_CONF_URL}/$NTLM_CONF_URL/g" \
    NTLM/pam_script_auth > /usr/share/libpam-script/pam_script_auth

cp NTLM/pam_script_ses_open /usr/share/libpam-script/
cp NTLM/pam_script_ses_close /usr/share/libpam-script/

chmod a+x /usr/share/libpam-script/pam_script_auth
chmod a+x /usr/share/libpam-script/pam_script_ses_open
chmod a+x /usr/share/libpam-script/pam_script_ses_close

# log dir to diagnose NTLM issues
if [ ! -d /var/log/cntlm ]; then
    mkdir /var/log/cntlm
fi

# ================
# update pam files
# ================

echo install pam files
cp pam/* /etc/pam.d/

# ============
# run script
# ============

# install the runscript python script that will query a data base server
# for script to run periodically

apt-get install -y mariadb-client python3-mysql.connector
sed -e "s/{RUN_SCRIPT_HOST}/$RUN_SCRIPT_HOST/g" -e "s/{RUN_SCRIPT_USER}/$RUN_SCRIPT_USER/g" \
    -e "s/{RUN_SCRIPT_PASS}/$RUN_SCRIPT_PASS/g" -e "s/{RUN_SCRIPT_DB}/$RUN_SCRIPT_DB/g" \
    scripts/run_scripts.py > /usr/local/bin/run_scripts.py

chmod 0700 /usr/local/bin/run_scripts.py
if [ ! -d /var/lib/run_scripts ]; then
    mkdir /var/lib/run_scripts
fi

cp scripts/run_scripts.service /etc/systemd/system/
cp scripts/run_scripts.timer /etc/systemd/system/
systemctl enable run_scripts
systemctl start run_scripts

# ====================
# mintupdate
# ====================
# automatic update

sudo apt-get install -y mintupdate

cp scripts/mintupdate.service /etc/systemd/system/
cp scripts/mintupdate.timer /etc/systemd/system/

# ====================
# fusioninventory glpi
# ====================

apt-get install -y fusioninventory-agent
cp Glpi/fusioninventory-agent.service /etc/systemd/system
sed -e "s/{GLPI_HOST/$GLPI_HOST/g" Glpi/agent.cfg > /etc/fusioninventory/agent.cfg
systemctl enable fusioninventory-agent

# ================
# numlock
# ================

# start with numlock on

apt-get install -y numlockx

# ===============
# username applet
# ===============

cp -r user-name@cinnamon.org /usr/share/cinnamon/applets/

# =============
#  user profile
# =============

# fix for jupyter notebook + disallow user switching
# recall that pam_script copie /etc/skel at login.

cp skel/profile /etc/skel/.profile

# ========================================================
# firefox default page is ent and configure chromium proxy
# ========================================================

cp browser/syspref.js /etc/firefox/
cp browser/chromium-browser.desktop /usr/share/applications/

# ================
# various
# ================

echo disable wpa_supplicant: no wifi
systemctl disable wpa_supplicant

# ========
# cleaning
# ========

echo cleaning
apt-get -y autoremove

echo register MAC and run scripts
/usr/local/bin/run_scripts.py || true # fails if interface is not yet eth0

# final message
echo Installation complète: reboot

reboot
