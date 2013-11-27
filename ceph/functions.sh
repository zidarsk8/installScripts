

function sync_ssh_keys { 

    install_sshpass 

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
    

    if [ $(lsb_release -si) == "CentOS" ]; then
        echo -e "${ceph_password}\n${ceph_password}" | (passwd --stdin ${ceph_username})
    else
        echo -e "${ceph_password}\n${ceph_password}" | passwd  ${ceph_username}
    fi


    echo "${ceph_username} ALL = (root) NOPASSWD:ALL" | tee /etc/sudoers.d/${ceph_username}
    chmod 0440 /etc/sudoers.d/${ceph_username}
    sed -i "s/Defaults\s*requiretty/# Defaults requiretty/g" /etc/sudoers

    echo "generating ssh key: $ssh_key_name"
    #### generate ssh keys and copy ssh config file for the new user ####
    sudo -u ${ceph_username} -H mkdir -p /home/${ceph_username}/.ssh
    sudo -u ${ceph_username} -H ssh-keygen -qf /home/${ceph_username}/.ssh/${ssh_key_name} -t rsa -N ''


    add_hosts_ssh_entries ${ceph_username} 

}






function reboot_all {

    for  (( i=1; i<$NODE_COUNT; i++ )); do
        sleep 1
        sshpass -p "${NODES[$i-password]}" ssh -o StrictHostKeyChecking=no -t ${NODES[$i-username]}@${NODES[$i-ip]} "reboot"
    done

    sleep 1
    reboot

}


function setup_single_node {
    
    if [ -z "$NODE_NUMBER" ] && [ "$NODE_NUMBER" -lt "$NODE_COUNT" ] && [ "$NODE_NUMBER" -ge 0 ]; then
        echo "setup single node error: missing global var 'NODE_NUMBER'"
        return 1
    fi
    
    set_hostname ${NODES[${NODE_NUMBER}-name]}
    
    
    
    add_ceph_user $CEPH_USERNAME $CEPH_PASSWORD $SSH_KEY_FILE
    
    $FORMAT_DRIVE && format_xfs_drive ${NODES[${NODE_NUMBER}-disk]}  $MOUNTPOINT
    
    
    [ $(lsb_release -si) == "CentOS" ] && add_iptables_rules ${NODES[${NODE_NUMBER}-ip]} ${NODES[${NODE_NUMBER}-netmask]}

    [ $(lsb_release -si) == "CentOS" ] && import_rpm_keys

}


function push_to_single_node {

    if [ "$#" -lt 1 ]; then
        echo "usage: push_to_single_node 'node-number'"
        return 1
    fi

    local node=$1

    install_sshpass

    echo "######## installing node: ${node} (${NODES[${node}-ip]}) #######"
    sshpass -p "${NODES[${node}-password]}" scp -o StrictHostKeyChecking=no -r ${DIRNAME} "${NODES[${node}-username]}@${NODES[${node}-ip]}:"
    sshpass -p "${NODES[${node}-password]}" ssh -o StrictHostKeyChecking=no -t ${NODES[${node}-username]}@${NODES[${node}-ip]} "${DIRNAME}/ceph -n ${node} $FORMAT_DRIVE_ARG $QUIET "
}


function push_to_nodes {

    for  (( i=1; i<$NODE_COUNT; i++ )); do
        push_to_single_node $i
    done

    sync_ssh_keys $CEPH_USERNAME $CEPH_PASSWORD $SSH_KEY_FILE

    reboot_all

}

function sync_all_ssh_keys {

    add_hosts_ssh_entries $CEPH_USERNAME 
    
    if [ "$SYNC_ALL" == "all" ]; then

        install_sshpass
        for  (( node=1; node<$NODE_COUNT; node++ )); do
            sshpass -p "${NODES[${node}-password]}" scp -o StrictHostKeyChecking=no -r ${DIRNAME} "${NODES[${node}-username]}@${NODES[${node}-ip]}:"
            sshpass -p "${NODES[${node}-password]}" ssh -o StrictHostKeyChecking=no -t ${NODES[${node}-username]}@${NODES[${node}-ip]} "${DIRNAME}/ceph -s single"
           
        done

        sync_ssh_keys $CEPH_USERNAME $CEPH_PASSWORD $SSH_KEY_FILE
    fi
    
}

function format_xfs_drive {

    if [ "$#" -lt 2 ]; then
        echo "usage: format_xfs_drive disk mountpoint"
        return 1
    fi

    install_xfsprogs

    label=cephxfs
    disk=$1

    
    echo "o
c
u
n
p
1


p
w
" | fdisk ${disk}

    sleep 1
    
    mkfs.xfs "${disk}1"

    /usr/sbin/xfs_admin -L $label "${disk}1"

    mountpoint=$2

    mkdir -p ${mountpoint}

    echo "${disk}1   $mountpoint   xfs defaults   1 2" >> /etc/fstab
    mount "${disk}1" "$mountpoint"

}



