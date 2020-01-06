#!/bin/bash
##################################################################
# Poor Man's Encrypted Backup Solution
#
# pmebs-create.sh
#
# Usage: TODO:
#
# This script guides through the creation of LUKS-encrypted volume
# with detached header and splitted data volumes.
#
# On succes it mounts the volume under $MNT
##################################################################
set -e

if [[ ! "$CALLPERM" = true ]]; then
    echo "This script is not supposed to be called directly. Use pmebs.sh instead. Exiting."
    exit
fi
CALLPERM=false

. $PMEBSDIR/pmebs.conf

# for debugging
DOCREATE=true                   # create the container files
DOWIPE=false                    # securely wipe the disk
DOCRYPTFORMAT=true              # create new disk/header
DOFSFORMAT=true                 # format the mounted fs

VOLSIZEBYTES=$((VOLSIZE*1024*1024))
BLKCNT=$((VOLSIZE/BLKSIZE))
MAXNM=$((BLKCNT-1))

echo -e " ${COLOR}PMEBS >>>${NC} I will create a volume \"$NAME\" with $VOLSIZE MB as $BLKCNT x $BLKSIZE MB blocks in $CURRDIR for user \"$USR\". The config directory is \"$CONFDIR/\""
confirm

mkdir -p $CONFDIR

if [ "$DOCREATE" = true ]; then
    echo
    echo -e " ${COLOR}PMEBS >>>${NC} Creating files..."
    echo
    mkdir -p $CURRDIR/$DATADIR
    for i in $(eval echo -e {0..$MAXNM}); do
        #TODO: support different blocks - K, G
        truncate -s ${BLKSIZE}M $CURRDIR/$DATADIR/$NAME.$i
        printf "."
    done
    echo
fi

echo
echo -e " ${COLOR}PMEBS >>>${NC} Loading and configuring nbd..."
echo
modprobe nbd
cp $PMEBSDIR/$NBDDEFCONF $CONFDIR/$NBDCONF
echo >> $CONFDIR/$NBDCONF
echo "    filesize = $VOLSIZEBYTES" >> $CONFDIR/$NBDCONF
echo "    exportname = $CURRDIR/$DATADIR/$NAME" >> $CONFDIR/$NBDCONF

echo
echo -e " ${COLOR}PMEBS >>>${NC} Mounting volume as nbd..."
echo
nbd-server -C $CONFDIR/$NBDCONF localhost@$NBDPORT
sleep 1
nbd-client localhost $NBDPORT -N $DEFEXP /dev/$NBDDEV

if [ "$DOWIPE" = true ]; then
    echo
    echo -e " ${COLOR}PMEBS >>>${NC} Wiping..."
    echo
    cryptsetup open --type plain -d /dev/urandom /dev/$NBDDEV wipeme
    set +e	# the next line is expected to fail with "device full.."
    cat /dev/zero | pv > /dev/mapper/wipeme
    set -e
    sync
    cryptsetup close wipeme
fi

if [ "$DOCRYPTFORMAT" = true ]; then
    echo
    echo -e " ${COLOR}PMEBS >>>${NC} Creating LUKS header..."
    echo
    mkdir -p $HEADDIR
    cryptsetup luksFormat /dev/$NBDDEV --header $HEADDIR/$NAME.$HEADEXT --align-payload=0 -i $ITER
fi

echo
echo -e " ${COLOR}PMEBS >>>${NC} Opening your new device..."
echo
cryptsetup open /dev/$NBDDEV --header $HEADDIR/$NAME.$HEADEXT $CRYPTO

if [ "$DOFSFORMAT" = true ]; then
    echo
    echo -e " ${COLOR}PMEBS >>>${NC} Formatting, mounting and chown-ing..."
    echo
    mkfs.ext4 -L PMEBS.$NAME /dev/mapper/$CRYPTO
    mkdir -p $MNT
    mount /dev/mapper/$CRYPTO $MNT
    mkdir $UNENCDIR
    echo "UNENC: $UNENCDIR"
    chown $USR:$USR $UNENCDIR
else
    echo
    echo -e " ${COLOR}PMEBS >>>${NC} Mounting..."
    echo
    mount /dev/mapper/$CRYPTO $MNT
fi

echo
echo -e " ${COLOR}PMEBS >>>${NC} Done!"

set +e