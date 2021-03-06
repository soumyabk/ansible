#!/bin/bash
ETH=`sudo dmesg | grep -Po '\K\b[[:alnum:]]+\b: renamed from eth' | cut -d ':' -f 1`
if [ ! -z "$ETH" ]; then
    ETHIP=`sudo ip addr list $ETH |grep 'inet ' |cut -d' ' -f6|cut -d/ -f1|cut -d'.' -f1-3`
else
    ETHIP=`sudo ip addr list eth0 |grep 'inet ' |cut -d' ' -f6|cut -d/ -f1|cut -d'.' -f1-3`
fi
if [ -f /etc/exports ]; then
    RES='Exchanging IP addresses for NFS Service with IP range '$ETHIP
    sudo sed -i -e 's/\([0-9]\{1,3\}\.\)\{2\}[0-9]\{1,3\}\./'${ETHIP}'\./' /etc/exports
else
    RES='No NFS exports file found, doing nothing.'
fi
sudo touch /var/log/firstboot.log
sudo echo ${RES} >> /var/log/firstboot.log

if [ -f /etc/dhcpcd.conf ] && [ ! -z "$ETH" ]; then
    RES='Exchanging Network device name in dhcpcd config file '$ETH
    sudo sed -i -e 's/eth_replace/'${ETH}'/' /etc/dhcpcd.conf 
else
    RES='Network device name did not have to be changed.'
fi
sudo echo ${RES} >> /var/log/firstboot.log

if [ -f /etc/monit/monitrc ]; then
    RES='Exchanging Network range in monitrc config file '$ETHIP
    sudo sed -i -e 's/allow \([0-9]\{1,3\}\.\)\{2\}[0-9]\{1,3\}\./allow '${ETHIP}'\./' /etc/monit/monitrc 
else
    RES='No changes for monit because config file does not exist.'
fi
sudo echo ${RES} >> /var/log/firstboot.log

if [ -e /dev/snd/controlC0 ]; then
    SOUNDCARD=`amixer scontrols | cut -d "'" -f 2`
    RES='Changing volume for sound card '$SOUNDCARD
    amixer sset $SOUNDCARD 95%    
else
    RES='No soundcard found.'
fi    
sudo echo ${RES} >> /var/log/firstboot.log

if [ -f /etc/ssh/ssh_host_dsa_key ]; then
    RES='Deleting existing SSH host keys.'
    rm /etc/ssh/ssh_host_*
    #rm /root/.ssh/authorized_keys
fi
sudo echo ${RES} >> /var/log/firstboot.log
sudo /usr/bin/ssh-keygen -t dsa -N "" -f /etc/ssh/ssh_host_dsa_key
sudo /usr/bin/ssh-keygen -t rsa -N "" -f /etc/ssh/ssh_host_rsa_key
sudo /usr/bin/ssh-keygen -t ecdsa -N "" -f /etc/ssh/ssh_host_ecdsa_key
sudo /usr/bin/ssh-keygen -t ed25519 -N "" -f /etc/ssh/ssh_host_ed25519_key
sudo ln -s /etc/ssh/ssh_host_rsa_key.pub /root/.ssh/authorized_keys
RES='Created new SSH host keys. Copy /etc/ssh/ssh_host_rsa_key to your client and connect as smarthome or root!'
sudo echo ${RES} >> /var/log/firstboot.log

sudo systemctl disable firstboot.service
