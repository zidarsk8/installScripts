#!/bin/bash

#### check script arguments ####

EXPECTED_ARGS=1
E_BADARGS=65

if [[ $EUID -eq 0 ]]; then
   echo "don't run this as root" 
   exit 1
fi

if [ $# -ne $EXPECTED_ARGS ]; then
  echo "Usage: $(basename "$0") cluster_name"
  echo ""
  exit $E_BADARGS
fi

DIRNAME=$(dirname "$0")


source "${DIRNAME}/ceph.cfg"
source "${DIRNAME}/ceph-storage-cluster.cfg"


cluster_name=$1

cd 

mkdir "$cluster_name"
cd "$cluster_name"


ceph-deploy install ${CLUSTER_NODES[@]}

ceph-deploy new $CLUSTER_MONITOR

ceph-deploy mon create $CLUSTER_MONITOR

ceph-deploy gatherkeys $CLUSTER_MONITOR


osd_dev=()
osd_block=()

cnt=${#CLUSTER_OSD[@]}
for ((i=0;i<cnt;i++)); do
    osd_dev[i]="${CLUSTER_OSD[i]}${CLUSTER_DEVICE}"
    osd_block[i]="${CLUSTER_OSD[i]}${CLUSTER_DEVICE}1"
done


if $ZAP ; then
    ceph-deploy disk zap ${osd_dev[@]}
fi

ceph-deploy osd prepare ${osd_dev[@]}

ceph-deploy osd activate ${osd_block[@]}


