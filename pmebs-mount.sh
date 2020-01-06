#!/bin/bash
##################################################################
# Poor Man's Encrypted Backup Solution
#
# pmebs-mount.sh
#
# Usage: TODO:
#
# This script nmounts a local/remote PMEBS volume
##################################################################
set -e  # no point of continuing on errors

if [[ ! "$CALLPERM" = true ]]; then
    echo "This script is not supposed to be called directly. Use pmebs.sh instead. Exiting."
    exit
fi
CALLPERM=false

. $PMEBSDIR/pmebs.conf

if [[ "$LOCAL" = false ]]; then
    mkdir -p $FUSEMNT
    echo -e " ${COLOR}PMEBS >>>${NC} Mounting sshfs..."
    sed -i '/exportname/c\    exportname = '"$FUSEMNT/$DATADIR/$NAME"'' $CONFDIR/$NBDCONF
    sshfs $SFTP $FUSEMNT $SSHOPT
fi

echo -e " ${COLOR}PMEBS >>>${NC} Loading nbd..."
modprobe nbd

echo -e " ${COLOR}PMEBS >>>${NC} Mounting nbd volume as defined in ${CONFDIR}/${NBDCONF}..."
nbd-server -C $CONFDIR/$NBDCONF localhost@$NBDPORT
sleep 1
nbd-client localhost $NBDPORT -N $DEFEXP /dev/$NBDDEV

echo -e " ${COLOR}PMEBS >>>${NC} Opening your device..."
cryptsetup open /dev/$NBDDEV --header $HEADDIR/$NAME.$HEADEXT $CRYPTO

echo -e " ${COLOR}PMEBS >>>${NC} Mounting..."
mount /dev/mapper/$CRYPTO $MNT

echo
echo " >>> Done!"
set +e
