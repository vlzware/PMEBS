#!/bin/bash
##################################################################
# Poor Man's Encrypted Backup Solution
#
# pmebs-umount.sh
#
# Usage: TODO:
#
# This script unmounts a local/remote PMEBS volume
##################################################################

if [[ ! "$CALLPERM" = true ]]; then
    echo "This script is not supposed to be called directly. Use pmebs.sh instead. Exiting."
    exit
fi
CALLPERM=false

. $PMEBSDIR/pmebs.conf

RES=0

echo -e " ${COLOR}PMEBS >>>${NC} Umounting..."
umount $MNT || RES=1

echo -e " ${COLOR}PMEBS >>>${NC} Closing the encrypted container..."
cryptsetup close $CRYPTO || RES=1

echo -e " ${COLOR}PMEBS >>>${NC} Stopping nbd..."
nbd-client -d /dev/$NBDDEV || RES=1
pkill nbd-server || RES=1

if [[ "$LOCAL" = false ]]; then
    echo -e " ${COLOR}PMEBS >>>${NC} Closing sshfs..."
    fusermount -u $FUSEMNT
fi

if [[ "$RES" != 0 ]]; then
    echo -e " ${COLOR}PMEBS >>> The script finished with errors!${NC}"
    exit 1
fi

echo
echo " >>> Done!"

