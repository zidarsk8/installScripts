#!/bin/bash

#### check script arguments ####



function usage {
cat << EOF
usage: $0 options

This script run the test1 or test2 over a machine.

OPTIONS:
   -n      name
   -d      dry run, only print commands without running them 
   -h      help
EOF
}



DIRNAME=$(dirname "$0")

source "${DIRNAME}/ceph.cfg"
source "${DIRNAME}/ceph-storage-cluster.cfg"


CLUSTER_NAME=""
DRY=false

while getopts “n:d” OPTION
do
     case $OPTION in
         h)
             usage
             exit
             ;;
         n)  
             CLUSTER_NAME=$OPTARG
             ;;
         d)  
             DRY=true
             ;;
         ?)
             usage
             exit
             ;;
     esac
done




if [[ $EUID -eq 0 ]]; then
   echo "don't run this as root" 
   exit 1
fi

if [ $CLUSTER_NAME -eq "" ]; then
    usage
    exit
fi







echo "cd"
cd 


echo "" 
echo    "mkdir \"$CLUSTER_NAME\""
$DRY || mkdir "$CLUSTER_NAME"

echo "" 
echo    "mkdir cd "$CLUSTER_NAME"
$DRY || cd "$CLUSTER_NAME"


echo "" 
echo    "ceph-deploy install ${CLUSTER_NODES[@]}"
$DRY || ceph-deploy install ${CLUSTER_NODES[@]}


echo "" 
echo    "ceph-deploy new $CLUSTER_MONITOR"
$DRY || ceph-deploy new $CLUSTER_MONITOR

echo "" 
echo    "ceph-deploy mon create $CLUSTER_MONITOR"
$DRY || ceph-deploy mon create $CLUSTER_MONITOR

echo "" 
echo    "ceph-deploy gatherkeys $CLUSTER_MONITOR"
$DRY || ceph-deploy gatherkeys $CLUSTER_MONITOR



osd_dev=()
osd_block=()

cnt=${#CLUSTER_OSD[@]}
for ((i=0;i<cnt;i++)); do
    osd_dev[$i]="${CLUSTER_OSD[$i]}:${CLUSTER_DEVICE}"
    osd_block[$i]="${CLUSTER_OSD[$i]}:${CLUSTER_DEVICE}1"
done


if $CLUSTER_ZAP ; then
    echo "" 
echo    "ceph-deploy disk zap ${osd_dev[@]}"
    $DRY || ceph-deploy disk zap ${osd_dev[@]}
    echo "" 
echo    "ceph-deploy osd prepare ${osd_dev[@]}"
    $DRY || ceph-deploy osd prepare ${osd_dev[@]}
    echo "" 
echo    "ceph-deploy osd activate ${osd_block[@]}"
    $DRY || ceph-deploy osd activate ${osd_block[@]}
else
    echo "" 
echo    "ceph-deploy osd prepare ${osd_dev[@]}"
    $DRY || ceph-deploy osd prepare ${osd_dev[@]}
    echo "" 
echo    "ceph-deploy osd activate ${osd_dev[@]}"
    $DRY || ceph-deploy osd activate ${osd_dev[@]}
fi



echo "" 
echo    "ceph-deploy admin ${CLUSTER_NODES[@]}"
$DRY || ceph-deploy admin ${CLUSTER_NODES[@]}


echo "" 
echo    "ceph health"

$DRY || ceph health

