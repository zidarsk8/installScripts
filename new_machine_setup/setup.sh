#!/bin/bash

rm -f /etc/udev/rules.d/70-persistent-net.rules

sed -i "s/XYZ/${1}/g" ifcfg-eth1

cp ifcfg-eth0 /etc/sysconfig/network-scripts/
cp ifcfg-eth1 /etc/sysconfig/network-scripts/



chkconfig NetworkManager off
chkconfig network on
chkconfig sshd on

