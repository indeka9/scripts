# === CONFIGURATION ===
DISK="sdc"
DISKEFI=1
DISKBOOT=2
DISKROOT=3
ROOTNAME=main

RSYNC_FROM_DIR="/mnt/copyfrom" 
RSYNC_TO_DIR="/mnt/copyto"

DISKMOUNT="$ROOTNAME"

btrfs_list="@:tmp @opt:opt @tmp:tmp @var_cache:var/cache @var_tmp:var/tmp @var_log:var/log @home:home @.mozilla:home/$USER/.mozilla @.thunderbird:home/$USER/.thunderbird @.wine:home/$USER/.wine"

mount_options="noatime,ssd,space_cache=v2,discard=async,compress=zstd:3"

echo "cryptsetup luksFormat /dev/$DISK$DISKROOT"

echo "cryptsetup luksOpen /dev/$DISK$DISKROOT $ROOTNAME"

echo "mkdir /mnt/copyfrom"
echo "mkdir /mnt/copyto"


echo "mkfs.fat -F 32 /dev/${DISK}${DISKEFI}"
echo "mkfs.btrfs  /dev/${DISK}${DISKBOOT}"

echo "mount /dev/mapper/$ROOTNAME $RSYNC_TO_DIR"
echo "mkfs.btrfs  /dev/mapper/$ROOTNAME $RSYNC_TO_DIR"


echo cd "$RSYNC_TO_DIR"


# Set IFS to space to split the string into an array 
IFS=' ' read -r -a array <<< "$btrfs_list"

# Loop through the array and print elements
for element in "${array[@]}"; do
    IFS=':' read -r part1 part2 <<< "$element"
    echo "btrfs subvolume create ${part1}"
done

cd ..

echo "umount -R $RSYNC_TO_DIR"
echo "mkdir -p $RSYNC_TO_DIR/boot"
echo "mkdir -p $RSYNC_TO_DIR/boot/efi"

# Loop through the array and print elements
for element in "${array[@]}"; do
    IFS=':' read -r part1 part2 <<< "$element"
    echo "mkdir -p $RSYNC_TO_DIR/${part2}"
done

echo "mount -o $mount_options /dev/${DISK}${DISKBOOT} $RSYNC_TO_DIR/boot"
echo "mount -o $mount_options /dev/${DISK}${DISKEFI} $RSYNC_TO_DIR/boot/efi"

for element in "${array[@]}"; do
    IFS=':' read -r part1 part2 <<< "$element"
    echo "mount -o $mount_options,subvol=$part1 /dev/mapper/$DISKMOUNT $RSYNC_TO_DIR"
done


echo "rsync -aAXv --numeric-ids --delete ${RSYNC_FROM_DIR}/ ${RSYNC_TO_DIR}/"
echo "pacstrap ${RSYNC_TO_DIR} base, linux, linux-headers linux-firmware"

echo "genfstab -U -P ${RSYNC_TO_DIR} >> ${RSYNC_TO_DIR}/etc/fstab" 

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

modules='all_video boot btrfs cat chain configfile echo efifwsetup efinet ext2 fat font gettext gfxmenu gfxterm gfxterm_background gzio halt help hfsplus iso9660 jpeg keystatus loadenv loopback linux ls lsefi lsefimmap lsefisystab lssal memdisk minicmd normal ntfs part_apple part_msdos part_gpt password_pbkdf2 png probe reboot regexp search search_fs_uuid search_fs_file search_label sleep smbios squash4 test true video xfs zfs zfscrypt zfsinfo play tpm luks cryptodisk cpuid'
echo "grub-install  --bootloader-id Linux --efi-directory /boot  --modules=\"${modules}\" --sbat /usr/share/grub/sbat.csv"
echo "efibootmgr --create --disk /dev/${DISK} --part ${DISK}${DISKEFI} --label "Linux shim" --loader 'EFI\BOOT\shimx64.efi' --unicode"



