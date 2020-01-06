#!/bin/bash
##################################################################
# Poor Man's Encrypted Backup Solution
#
# pmebs.sh
#
# Usage: TODO:
#
# This script calls the appropriate script for creating or (un)mounting
# a PMEBS volume.
##################################################################
PMEBSDIR=`dirname "$0"`
CALLPERM=true

# 31 red, 32 green, 33 brown, 34 blue, 35 purple, 36 cyan
COLOR='\033[0;33m'
NC='\033[0m'

printUsage () {
    echo -e "${COLOR}PMEBS Usage${NC}"
    echo -e "-----------"
    echo -e "${COLOR}Create volume:${NC}" >&2
    echo -e "sudo $0 -c[reate] volume_name volume_size_in_MB block_size_in_MB" >&2
    echo -e "${COLOR}Mount local volume:${NC}" >&2
    echo -e "sudo $0 -lm[ount] volume_name" >&2
    echo -e "${COLOR}Unmount local volume:${NC}" >&2
    echo -e "sudo $0 -lu[mount] volume_name" >&2
    echo -e "${COLOR}Mount remote volume:${NC}" >&2
    echo -e "sudo $0 -m[ount] volume_name sftpserver" >&2
    echo -e "${COLOR}Unmount remote volume:${NC}" >&2
    echo -e "sudo $0 -u[mount] volume_name" >&2
    exit 1
}

checkCount () {
    if [[ ! "$1" -eq "$2" ]]; then
        printUsage
    fi
}

confirm () {
    echo
    read -rsp $'Continue (any key) or break with Ctrl-C ...\n' -n1 key
}

if [[ "$#" -eq 0 ]]; then
    printUsage
fi

if [ "$(whoami)" != "root" ]; then
    echo -e "ERROR: Run this as root!" >&2
    exit 1
fi

case $1 in
    -c|-create)
        checkCount $# 4
        NAME=$2
        VOLSIZE=$3
        BLKSIZE=$4
        . $PMEBSDIR/pmebs-create.sh
        exit
        ;;

    -lm|-lmount)
        checkCount $# 2
        NAME=$2
        echo -e " ${COLOR}PMEBS >>>${NC} I will mount the local volume \"$NAME\""
        confirm
        LOCAL=true
        . $PMEBSDIR/pmebs-mount.sh
        exit
        ;;

    -lu|-lumount)
        checkCount $# 2
        NAME=$2
        echo -e " ${COLOR}PMEBS >>>${NC} I will unmount the local volume \"$NAME\""
        confirm
        LOCAL=true
        . $PMEBSDIR/pmebs-umount.sh
        exit
        ;;

    -m|-mount)
        checkCount $# 3
        NAME=$2
        SFTP=$3
        echo -e " ${COLOR}PMEBS >>>${NC} I will mount the remote volume \"$NAME\" from \"$SFTP\""
        confirm
        LOCAL=false
        . $PMEBSDIR/pmebs-mount.sh $SFTP
        exit
        ;;

    -u|-umount)
        checkCount $# 2
        NAME=$2
        echo -e " ${COLOR}PMEBS >>>${NC} I will unmount the remote volume \"$NAME\""
        confirm
        LOCAL=false
        . $PMEBSDIR/pmebs-umount.sh
        exit
        ;;

    *)
        printUsage
esac

echo "Hummmm"
exit