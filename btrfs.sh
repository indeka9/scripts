# === CONFIGURATION ===
DISK="sdb"
DISKEFI=1
DISKBOOT=2
DISKROOT=3
ROOTNAME=root

echo "mkdir /mnt/copyfrom"
echo "mkdir /mnt/copyto"

RSYNC_FROM_DIR="/mnt/copyfrom" 
RSYNC_TO_DIR="/mnt/copyto"

DISKMOUNT="$ROOTNAME"

btrfs_list="@:tmp @opt:opt @tmp:tmp @var_cache:var/cache @var_tmp:var/tmp @var_log:var/log @home:home @.mozilla:home/indika/.mozilla @.thunderbird:home/$USER/.thunderbird @.wine:home/$USER/.wine"

mount_options="defaults"

echo "cryptsetup luksFormat /dev/$DISK$DISKROOT"

echo "cryptsetup luksOpen /dev/$DISK$DISKROOT $ROOTNAME"

echo "mount /dev/mapper/$ROOTNAME $RSYNC_TO_DIR"

echo cd "$RSYNC_TO_DIR"


# Set IFS to space to split the string into an array
IFS=' ' read -r -a array <<< "$btrfs_list"

# Loop through the array and print elements
for element in "${array[@]}"; do
    IFS=':' read -r part1 part2 <<< "$element"
    echo "btrfs subvolume create ${part1}"
done

#cd ..

echo "umount -R $RSYNC_TO_DIR"

echo "mkdir -p $RSYNC_TO_DIR/boot"
echo "mkdir -p $RSYNC_TO_DIR/boot/efi"

# Loop through the array and print elements
for element in "${array[@]}"; do
    IFS=':' read -r part1 part2 <<< "$element"
    echo "mkdir -p $RSYNC_TO_DIR/${part2}"
done

echo "mount -o defaults /dev/${DISK}${DISKBOOT} $RSYNC_TO_DIR/boot"
echo "mount -o defaults /dev/${DISK}${DISKEFI} $RSYNC_TO_DIR/boot/efi"

for element in "${array[@]}"; do
    IFS=':' read -r part1 part2 <<< "$element"
    echo "mount -o $mount_options,subvol=$part1 /dev/mapper/$DISKMOUNT $RSYNC_TO_DIR"
done


echo "rsync -aAXv --numeric-ids --delete ${RSYNC_FROM_DIR}/ ${RSYNC_TO_DIR}/"

echo "mount --types proc /proc /mnt/copyto/proc"
echo "mount --rbind /sys /mnt/copyto/sys"
echo "mount --make-rslave /mnt/copyto/sys"
echo "mount --rbind /dev /mnt/copyto/dev"
echo "mount --make-rslave /mnt/copyto/dev"
echo "test -L /dev/shm && rm /dev/shm && mkdir /dev/shm"
echo "mount --types tmpfs tmpfs /mnt/copyto/dev/shm"
echo "chmod 1777 /mnt/copyto/dev/shm"

echo "chroot /mnt/copyto /bin/bash"
echo "source /etc/profile"
echo "export PS1=\"(chroot) \$PS1\""

