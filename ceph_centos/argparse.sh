#!/bin/bash
# Argument = -t test -r server -p password -v

function usage {
cat << EOF
usage: $0 options

This script run the test1 or test2 over a machine.

OPTIONS:
   -h      Show this message
   -n      Node number for single install
   -s      Synchronize ssh keys
   -r      Setup remote node
   -v      Verbose
EOF
}

NODE_NUMBER=0
GROUP_INSTALL=true
QUIET=

while getopts “h:n:s:r:v” OPTION
do
     case $OPTION in
         h)
             usage
             exit
             ;;
         n)
             NODE_NUMBER=$OPTARG
             GROUP_INSTALL=false
             ;;
         r)
             SERVER=$OPTARG
             GROUP_INSTALL=false
             ;;
         s)
             sync_ssh_keys $CEPH_USERNAME $CEPH_PASSWORD $SSH_KEY_FILE
             exit
             ;;
         q)
             QUIET="-q"
             ;;
         ?)
             usage
             exit
             ;;
     esac
done

#if [[ -z $TEST ]] || [[ -z $SERVER ]] || [[ -z $PASSWD ]]
#then
#     usage
#     exit 1
#fi



