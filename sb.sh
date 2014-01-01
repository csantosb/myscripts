#!/bin/bash
# manage truecrypt containers using tcplay
# [[http://jasonwryan.com/blog/2013/01/10/truecrypt/][@ jasonwryan blog]]
# [[https://wiki.archlinux.org/index.php/Tcplay][@ arch wiki]]

user=csantos
group=users

cryptdev=sb
cryptpath=/home/csantos/Dropbox/"$cryptdev"

loopdev=$(losetup -f)
mountpt=/mnt/"$cryptdev"
backuppath=/home/csantos/"$cryptdev"

# must be run as root
if [[ $EUID != 0 ]]; then
    printf "%s\n" "You must be root to run this."
    exit 1
fi

# unecrypt and mount container
if [[ "$1" == "open" ]]; then

    losetup "$loopdev" "$cryptpath"
    tcplay --map="$cryptdev" --device="$loopdev"

    #   # read passphrase
    #   read -r -s passphrase <<EOF
    #   "$passphrase"
    # EOF

    # mount container
    [[ -d "$mountpt" ]] || mkdir "$mountpt"
    [[ -d "$backuppath" ]] || mkdir "$backuppath"

    # mount options
    mount -o nosuid /dev/mapper/"$cryptdev" "$mountpt"
    bindfs -u $user -g $group "$mountpt" "$backuppath"

    # close and clean up?
elif [[ "$1" == "close" ]]; then

    device=$(awk -v dev=$cryptdev -F":" '/dev/ {print $1}' <(losetup -a))

    umount "$backuppath"
    rm -rf "$backuppath"
    umount "$mountpt"
    rm -rf "$mountpt"

    dmsetup remove "$cryptdev" || printf "%s\n" "demapping failed"
    losetup -d "$device" || printf "%s\n" "deleting $loopdev failed"

else

    printf "%s\n" "Options are open or close."

fi

