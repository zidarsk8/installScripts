#!/bin/bash

rm /etc/udev/rules.d/70-persistent-net.rules

echo "

auto eth1
iface eth1 inet static
	address 10.0.1.${1}
	netmask 255.255.255.0
" >> /etc/network/interfaces

reboot 
