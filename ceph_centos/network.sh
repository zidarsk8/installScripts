#!/bin/bash


function add_hosts_ssh_entry {
    
    if [ "$#" -lt 4 ]; then
        echo "usage: add_hosts_ssh_entry ip name ssh_key_file ssh_username [ssh_port]"
        return 1
    fi

    local ip=$1
    local name=$2
    local ssh_key=$3
    local ssh_username=$4
    local ssh_port=""
    [ -n "$5" ] && local ssh_port="Port $5"

    echo "adding '$name' to ssh config and hosts"

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


function add_hosts_ssh_entries {

    for (( i=0; i<$NODE_COUNT; i++ )); do
        add_hosts_ssh_entry ${NODES[$i-ip]} ${NODES[$i-name]} $SSH_KEY_FILE $CEPH_USERNAME
    done

}


function set_hostname {
    if [ "$#" -lt 1 ]; then
        echo "usage: set_hostname hostname"
        return 1
    fi
    local hostname=$1
    hostname $hostname
    sed -i "s/HOSTNAME=.*/HOSTNAME=${hostname}/g" /etc/sysconfig/network
}



function config_interface {

    if [ "$#" -lt 4 ]; then
        echo "usage: config_interface 'interface' 'network' 'netmask' 'ip' 'gateway'"
        return 1
    fi
    

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

