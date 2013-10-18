#!/bin/bash


#### prepair files ####

mkdir -p ~/.ssh
[ -a ~/.ssh/config ] || touch ~/.ssh/config



#### add hosts and ssh config entry for given IP and name ####

function add_node_entry {
  if ! grep -q $2 /etc/hosts; then
    echo "$1 $2" >> /etc/hosts
  fi
  
  if ! grep -q $2 ~/.ssh/config; then
    echo "Host $2
        Hostname $2
        IdentityFile ~/.ssh/${SSH_KEY_NAME}
        User ${CEPH_USERNAME}" >> ~/.ssh/config
  fi
}

# generate hosts and ssh config file entries for ceph admin and ceph nodes 

echo "generating hosts and ssh config entries"
add_node_entry "${NETWORK_IP_PREFIX}${NETWORK_START_IP}" "ceph_admin"
for (( CURRENT_NODE=1; CURRENT_NODE<=$NODE_COUNT; CURRENT_NODE++ )); do
  add_node_entry "${NETWORK_IP_PREFIX}$(($NETWORK_START_IP + $CURRENT_NODE))" "ceph_node_${CURRENT_NODE}" 
done



#set up internal network interface

echo "seting up internal network interface"
if [ -n "$NETWORK_INTERFACE" ]; then 
  sed -i "s/HOSTNAME=.*/HOSTNAME=${HOSTNAME}/g" /etc/sysconfig/network

  echo "DEVICE=${NETWORK_INTERFACE} 
BOOTPROTO=none 
NM_CONTROLLED="no"
ONBOOT=yes 
NAME='Ceph internal network'
NETWORK=${NETWORK_IP_PREFIX}0
NETMASK=255.255.255.0 
IPADDR=${NETWORK_IP}
GATEWAY=${NETWORK_GATEWAY}
USERCTL=no" > /etc/sysconfig/network-scripts/ifcfg-${NETWORK_INTERFACE}

  #chkconfig network on
  /etc/init.d/network restart

fi


