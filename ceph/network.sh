#!/bin/bash


#### prepair files ####


# add hosts and ssh config entry for given IP and name ####

function add_hosts_ssh_entry {
    
    if [ "$#" -lt 1 ]; then
        echo "usage: add_hosts_ssh_entry ip name ssh_key_file ssh_username [ssh_port]"
        return 1
    fi

    local ip=$1
    local name=$2
    local ssh_key=$3
    local ssh_username=$4
    local ssh_port=""
    [ -n "$5" ] || local ssh_port="Port $5"

    mkdir -p ~/.ssh
    [ -a ~/.ssh/config ] || touch ~/.ssh/config

    if ! grep -q $name /etc/hosts; then
        echo "$ip $name" >> /etc/hosts
    fi

    if ! grep -q $name ~/.ssh/config; then
        echo "Host $name
        Hostname $name
        IdentityFile ~/.ssh/${ssh_key}
        User ${ssh_username}
        ${ssh_port}" >> ~/.ssh/config
    fi
}

# generate hosts and ssh config file entries for ceph admin and ceph nodes 

echo "generating hosts and ssh config entries"
add_node_entry "${NETWORK_IP_PREFIX}${NETWORK_START_IP}" "ceph_admin"
for (( CURRENT_NODE=1; CURRENT_NODE<=$NODE_COUNT; CURRENT_NODE++ )); do
    add_node_entry "${NETWORK_IP_PREFIX}$(($NETWORK_START_IP + $CURRENT_NODE))" "ceph_node_${CURRENT_NODE}" 
done



#set up internal network interface

function set_hostname {
    if [ "$#" -lt 1 ]; then
        echo "usage: set_hostname hostname"
        return 1
    fi
    sed -i "s/HOSTNAME=.*/HOSTNAME=${HOSTNAME}/g" /etc/sysconfig/network
}

function config_interface {

    local interface=$1
    local network=$2
    local netmask=$3
    local ip=$4
    local gateway=$5
    echo "seting up internal network interface: $interface"
    if [ -n "$interface" ]; then 

        echo "DEVICE=${interface} 
BOOTPROTO=none 
NM_CONTROLLED="no"
ONBOOT=yes 
NAME='Ceph internal network'
NETWORK=${network}0
NETMASK=${netmask}
IPADDR=${ip}
GATEWAY=${gateway}
USERCTL=no" > /etc/sysconfig/network-scripts/ifcfg-${interface}

        #chkconfig network on
        /etc/init.d/network restart

    fi
}

