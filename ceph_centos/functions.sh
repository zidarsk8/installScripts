

function sync_ssh_keys { 

    if [ "$#" -lt 2 ]; then
        echo "this should only be run on the server node"
        echo "usage: sync_ssh_keys 'ceph_username' 'ssh_key_name'"
        return 1
    fi

    local ceph_username=$1
    local ceph_password=$2
    local ssh_key_name=$3
    local ssh_folder="/home/${ceph_username}/.ssh/"

    echo "syncronising public keys"        

    # copy public keys from all nodes and servers into ~/.ssh/node_keys and generate authorized keys file

    sudo -u ${ceph_username} -H mkdir -p ${ssh_folder}node_keys/
    sudo -u ${ceph_username} -H cp ${ssh_folder}{${ssh_key_name}.pub,node_keys/server_${ssh_key_name}.pub}

    
    # generate known_hosts file for all nodes and the server
    sudo -u ${ceph_username} bash -c "ssh-keyscan -H ${NODES[0-name]} > ${ssh_folder}known_hosts"
 

    
    for (( i=1; i<$NODE_COUNT; i++ )); do
        sudo -u ${ceph_username} bash -c "ssh-keyscan -H ${NODES[$i-name]} >> ${ssh_folder}known_hosts"
    done
     

    for (( i=1; i<$NODE_COUNT; i++ )); do
        sshpass -p "${ceph_password}" scp -o StrictHostKeyChecking=no ${NODES[$i-name]}:.ssh/${ssh_key_name}.pub ${ssh_folder}node_keys/node_${i}_${ssh_key_name}.pub
    done
    
    sudo -u ${ceph_username} -H bash -c "cat ${ssh_folder}node_keys/*.pub > ${ssh_folder}authorized_keys"
    sudo -u ${ceph_username} -H chmod 600 ${ssh_folder}authorized_keys


    for (( i=1; i<$NODE_COUNT; i++ )); do
        sshpass -p "${ceph_password}" scp -o StrictHostKeyChecking=no ${ssh_folder}authorized_keys ${NODES[$i-name]}:.ssh/
        sshpass -p "${ceph_password}" scp -o StrictHostKeyChecking=no ${ssh_folder}known_hosts ${NODES[$i-name]}:.ssh/
    done

} 


function add_ceph_user {
 
    if [ "$#" -lt 3 ]; then
        echo "usage: add_hosts_ssh_entry ip name ssh_key_file ssh_username [ssh_port]"
        return 1
    fi

    local ceph_username=$1
    local ceph_password=$2
    local ssh_key_name=$3

    if id -u ${ceph_username} >/dev/null 2>&1; then
        echo "WARNING: user \"${ceph_username}\" already exists"
        return 1  
    fi

    echo "generating new user: ${ceph_username}"
    #### create new user ####
    sudo useradd -d /home/${ceph_username} -m ${ceph_username} -k ${DIRNAME}/skel -s /bin/bash
    echo -e "${ceph_password}\n${ceph_password}" | (passwd --stdin ${ceph_username})
    echo "${ceph_username} ALL = (root) NOPASSWD:ALL" | tee /etc/sudoers.d/${ceph_username}
    chmod 0440 /etc/sudoers.d/${ceph_username}
    sed -i "s/Defaults\s*requiretty/# Defaults requiretty/g" /etc/sudoers

    echo "generating ssh key: $ssh_key_name"
    #### generate ssh keys and copy ssh config file for the new user ####
    sudo -u ${ceph_username} -H mkdir -p /home/${ceph_username}/.ssh
    sudo -u ${ceph_username} -H ssh-keygen -qf /home/${ceph_username}/.ssh/${ssh_key_name} -t rsa -N ''


    cp ~/.ssh/config /home/${ceph_username}/.ssh/
    chown ${ceph_username}:${ceph_username} -R /home/${ceph_username}/.ssh
    

}




function format_xfs_drive {

    label=cephxfs
    disk=$1

    rpm -Uvh $(dirname $0)/extra-rpm/xfsdump-3.0.4-3.el6.x86_64.rpm $(dirname $0)/rpm/xfsprogs-3.1.1-10.el6_4.1.x86_64.rpm

    echo "o
c
u
n
p
1


p
w
" | fdisk ${disk}

    mkfs.xfs "${disk}1"

    /usr/sbin/xfs_admin -L $label "${disk}1"

    mountpoint=$2

    mkdir -p ${mountpoint}

    echo "${disk}1   $mountpoint   xfs defaults   1 2" >> /etc/fstab
    mount "${disk}1" "$mountpoint"

}





function install_ceph_deploy_rpm {

    echo "intalling packages: ceph_deploy_rpm"

    #### import rpm keys to avoid key warnings ####

    for f in $(dirname $0)/keys/*.key; do 
      sudo rpm --import $f
    done

    #### install packages for basic ceph-deploy ####

    rpm -Uvh --replacepkgs $(dirname $0)/ceph-deploy-rpm/*.rpm
    
    mv /usr/lib/python2.6/site-packages/ceph_deploy/hosts/centos/install.py{,.orig}
    cp ${DIRNAME}/ceph-deploy-centos-install.py /usr/lib/python2.6/site-packages/ceph_deploy/hosts/centos/install.py
}

function install_ceph_rpm {

    echo "intalling packages: ceph_rpm"

    #### import rpm keys to avoid key warnings ####

    for f in $(dirname $0)/keys/*.key; do 
      sudo rpm --import $f
    done

    #### install packages for basic ceph-deploy ####

    rpm -Uvh --replacepkgs $(dirname $0)/ceph-rpm/*.rpm


}

function install_extra_rpm {

    echo "intalling packages: extra_rpm"

    #### install packages for basic ceph-deploy ####

    rpm -Uvh --replacepkgs $(dirname $0)/extra-rpm/*.rpm

}


function install_kernel_lt_rpm {

    echo "intalling packages: kernel_lt"

    #### install packages for basic ceph-deploy ####

    rpm -Uvh --replacepkgs $(dirname $0)/kernel-lt-rpm/*.rpm

    echo "updatign grub conf "
    sed -i 's/default=1/default=0/g' /boot/grub/grub.conf
}




function dissable_iptables {

    for  (( i=0; i<$NODE_COUNT; i++ )); do

        # should replace this with a valid iptables config
        sshpass -p "${NODES[$i-password]}" ssh -o StrictHostKeyChecking=no -t ${NODES[$i-username]}@${NODES[$i-ip]} "service iptables save"
        sshpass -p "${NODES[$i-password]}" ssh -o StrictHostKeyChecking=no -t ${NODES[$i-username]}@${NODES[$i-ip]} "service iptables stop"
        sshpass -p "${NODES[$i-password]}" ssh -o StrictHostKeyChecking=no -t ${NODES[$i-username]}@${NODES[$i-ip]} "chkconfig iptables off"

        sshpass -p "${NODES[$i-password]}" ssh -o StrictHostKeyChecking=no -t ${NODES[$i-username]}@${NODES[$i-ip]} "service ip6tables save"
        sshpass -p "${NODES[$i-password]}" ssh -o StrictHostKeyChecking=no -t ${NODES[$i-username]}@${NODES[$i-ip]} "service ip6tables stop"
        sshpass -p "${NODES[$i-password]}" ssh -o StrictHostKeyChecking=no -t ${NODES[$i-username]}@${NODES[$i-ip]} "chkconfig ip6tables off"

    done

}
