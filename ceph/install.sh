function import_rpm_keys {

    for f in ${DIRNAME}/keys/*.key; do 
      sudo rpm --import $f
    done

}

function install_ceph_deploy_rpm {

    $VERBOSE && echo "intalling packages: ceph_deploy_rpm"

    #### import rpm keys to avoid key warnings ####

    #### install packages for basic ceph-deploy ####

    rpm -Uvh --replacepkgs ${DIRNAME}/ceph-deploy-rpm/*.rpm
    
    mv /usr/lib/python2.6/site-packages/ceph_deploy/hosts/centos/install.py{,.orig}
    cp ${DIRNAME}/ceph-deploy-centos-install.py /usr/lib/python2.6/site-packages/ceph_deploy/hosts/centos/install.py
}



function install_ceph_deploy_deb {

    echo "intalling packages: ceph_deploy_deb"

    wget -q -O- 'https://ceph.com/git/?p=ceph.git;a=blob_plain;f=keys/release.asc' | sudo apt-key add -

    echo deb http://ceph.com/debian-dumpling/ $(lsb_release -sc) main | sudo tee /etc/apt/sources.list.d/ceph.list

    sudo apt-get update > /dev/null && sudo apt-get install -y ceph-deploy

}



function install_ceph_deploy {

    if [ $(lsb_release -si) == "CentOS" ]; then
        install_ceph_deploy_rpm
    else
        install_ceph_deploy_deb
    fi
}


function install_ceph_rpm {

    $VERBOSE && echo "intalling packages: ceph_rpm"

    #### install packages for basic ceph-deploy ####

    rpm -Uvh --replacepkgs ${DIRNAME}/ceph-rpm/*.rpm


}


function install_sshpass {

    sshpass -h > /dev/null 2>&1 && return

    $VERBOSE && echo "intalling packages: sshpass"

    if [ $(lsb_release -si) == "CentOS" ]; then
        rpm -Uvh --replacepkgs ${DIRNAME}/extra-rpm/sshpass-1.05-1.el6.x86_64.rpm
    else
        apt-get install -y sshpass
    fi
    
}


function install_extra_rpm {

    $VERBOSE && echo "intalling packages: extra_rpm"

    #### install packages for basic ceph-deploy ####

    rpm -Uvh --replacepkgs ${DIRNAME}/extra-rpm/*.rpm

}


function install_kernel_lt_rpm {

    $VERBOSE && echo "intalling packages: kernel_lt"

    #### install packages for basic ceph-deploy ####

    rpm -Uvh --replacepkgs ${DIRNAME}/kernel-lt-rpm/*.rpm

    $VERBOSE && echo "updatign grub conf "
    sed -i 's/default=1/default=0/g' /boot/grub/grub.conf
}


function install_xfsprogs {
    
    mkfs.xfs -V  > /dev/null 2>&1 && return

    $VERBOSE && echo "intalling packages: xfsprogs"

    if [ $(lsb_release -si) == "CentOS" ]; then
        rpm -Uvh ${DIRNAME}/extra-rpm/xfsdump-3.0.4-3.el6.x86_64.rpm ${DIRNAME}/rpm/xfsprogs-3.1.1-10.el6_4.1.x86_64.rpm
    else
        apt-get install -y xfsprogs
    fi

}


