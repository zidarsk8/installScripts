

function sync_ssh_keys { 

    if [ "$#" -lt 2 ]; then
        echo "this should only be run on the server node"
        echo "usage: sync_ssh_keys 'ceph_username' 'ssh_key_name'"
        return 1
    fi

    local ceph_username=$1
    local ssh_key_name=$1
    local ssh_folder="/home/${ceph_username}/.ssh/"

    echo "syncronising public keys"        

    # copy public keys from all nodes and servers into ~/.ssh/node_keys and generate authorized keys file

    sudo -u ${ceph_username} -H mkdir -p ${ssh_folder}node_keys/
    sudo -u ${ceph_username} -H scp ${ssh_folder}{${ssh_key_name}.pub,node_keys/server_${ssh_key_name}.pub}

    
    # generate known_hosts file for all nodes and the server
    sudo -u ${ceph_username} bash -c "ssh-keyscan -H ceph_admin > ${ssh_folder}known_hosts"
 

    
    for (( i=1; i<$NODE_COUNT; i++ )); do
        sudo -u ${ceph_username} bash -c "ssh-keyscan -H ${NODES[$i-name]} >> ${ssh_folder}known_hosts"
        sudo -u ${ceph_username} bash -c "ssh-keyscan -H ${NODES[$i-ip]} >> ${ssh_folder}known_hosts"
    done
     

    for (( i=1; i<$NODE_COUNT; i++ )); do
        sshpass -p "${NODES[$i-password]}" scp ${NODES[$i-name]}:.ssh/${ssh_key_name}.pub ${ssh_folder}node_keys/node_${i}_${ssh_key_name}.pub
    done
    
    sudo -u ${ceph_username} -H bash -c "cat ${ssh_folder}node_keys/*.pub > ${ssh_folder}authorized_keys"
    sudo -u ${ceph_username} -H chmod 600 ${ssh_folder}authorized_keys


    for (( i=1; i<$NODE_COUNT; i++ )); do
        sshpass -p "${ceph_password}" scp ${ssh_folder}authorized_keys ${NODES[$i-name]}:.ssh/
        sshpass -p "${ceph_password}" scp ${ssh_folder}known_hosts ${NODES[$i-name]}:.ssh/
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
    sudo useradd -d /home/${ceph_username} -m ${ceph_username}
    echo -e "${ceph_password}\n${ceph_password}" | (passwd --stdin ${ceph_username})
    echo "${ceph_username} ALL = (root) NOPASSWD:ALL" | sudo tee /etc/sudoers.d/${ceph_username}
    sudo chmod 0440 /etc/sudoers.d/${ceph_username}

    echo "generating ssh key: $ssh_key_name"
    #### generate ssh keys and copy ssh config file for the new user ####
    sudo -u ${ceph_username} -H mkdir -p /home/${ceph_username}/.ssh
    sudo -u ${ceph_username} -H ssh-keygen -f /home/${ceph_username}/.ssh/${ssh_key_name} -t rsa -N ''


    cp ~/.ssh/config /home/${ceph_username}/.ssh/
    chown ${ceph_username}:${ceph_username} -R /home/${ceph_username}/.ssh
    

}


