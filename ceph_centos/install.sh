

function install_ceph_deploy_rpm {

    $VERBOSE && echo "intalling packages: ceph_deploy_rpm"

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

    $VERBOSE && echo "intalling packages: ceph_rpm"

    #### import rpm keys to avoid key warnings ####

    for f in $(dirname $0)/keys/*.key; do 
      sudo rpm --import $f
    done

    #### install packages for basic ceph-deploy ####

    rpm -Uvh --replacepkgs $(dirname $0)/ceph-rpm/*.rpm


}


function install_extra_sshpass_rpm {

    $VERBOSE && echo "intalling packages: extra_rpm"

    #### install packages for basic ceph-deploy ####

    sshpass -h > /dev/null 2>&1  || rpm -Uvh --replacepkgs ${DIRNAME}/extra-rpm/sshpass-1.05-1.el6.x86_64.rpm

}



function install_extra_rpm {

    $VERBOSE && echo "intalling packages: extra_rpm"

    #### install packages for basic ceph-deploy ####

    rpm -Uvh --replacepkgs $(dirname $0)/extra-rpm/*.rpm

}


function install_kernel_lt_rpm {

    $VERBOSE && echo "intalling packages: kernel_lt"

    #### install packages for basic ceph-deploy ####

    rpm -Uvh --replacepkgs $(dirname $0)/kernel-lt-rpm/*.rpm

    $VERBOSE && echo "updatign grub conf "
    sed -i 's/default=1/default=0/g' /boot/grub/grub.conf
}



