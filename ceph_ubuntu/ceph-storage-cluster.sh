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


CN=$1

cd 

mkdir "$CN"
cd "$CN"


ceph-deploy install ${NODES[@]}

ceph-deploy new $MONITOR

ceph-deploy mon create $MONITOR

ceph-deploy gatherkeys $MONITOR


osd_dev=()
osd_block=()

cnt=${#OSD[@]}
for ((i=0;i<cnt;i++)); do
    osd_dev[i]="${OSD[i]}${DEVICE}"
    osd_block[i]="${OSD[i]}${DEVICE}1"
done


if $ZAP ; then
    ceph-deploy disk zap ${osd_dev[@]}
fi

ceph-deploy osd prepare ${osd_dev[@]}

ceph-deploy osd activate ${osd_block[@]}


