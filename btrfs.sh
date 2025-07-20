# === CONFIGURATION ===
DISK="sdc"
DISKEFI=2
DISKBOOT=3
DISKROOT=4
ROOTNAME=root

RSYNC_FROM_DIR="/mnt/copyfrom" 
RSYNC_TO_DIR="/mnt/copyto"

DISKMOUNT="$ROOTNAME"

btrfs_list="@opt:opt @tmp:tmp @var_cache:var/cache @var_tmp:var/tmp @var_log:var/log @home:home @.mozilla:home/$USER/.mozilla @.thunderbird:home/$USER/.thunderbird @.wine:home/$USER/.wine"

mount_options="noatime,ssd,space_cache=v2,discard=async,compress=zstd:3"

echo "cryptsetup luksFormat /dev/$DISK$DISKROOT"

echo "cryptsetup luksOpen /dev/$DISK$DISKROOT $ROOTNAME"

echo "mkdir /mnt/copyfrom"
echo "mkdir /mnt/copyto"


echo "mkfs.fat -F 32 /dev/${DISK}${DISKEFI}"
echo "mkfs.btrfs  /dev/${DISK}${DISKBOOT}"

echo "mkfs.btrfs  /dev/mapper/$ROOTNAME"
echo "mount /dev/mapper/$ROOTNAME $RSYNC_TO_DIR"


# Set IFS to space to split the string into an array 
IFS=' ' read -r -a array <<< "$btrfs_list"

# Loop through the array and print elements
for element in "${array[@]}"; do
    IFS=':' read -r part1 part2 <<< "$element"
    echo "btrfs subvolume create ${RSYNC_TO_DIR}/${part1}"
done

cd ..

echo "umount -R $RSYNC_TO_DIR"
echo "mkdir -p $RSYNC_TO_DIR/boot"
echo "mkdir -p $RSYNC_TO_DIR/boot/efi"

echo "mount -o $mount_options /dev/${DISK}${DISKBOOT} $RSYNC_TO_DIR/boot"
echo "mount -o defaults,noatime /dev/${DISK}${DISKEFI} $RSYNC_TO_DIR/boot/efi"
echo "mount -o $mount_options,subvol=@ /dev/mapper/$DISKMOUNT $RSYNC_TO_DIR/"

for element in "${array[@]}"; do
    IFS=':' read -r part1 part2 <<< "$element"
    echo "mkdir -p $RSYNC_TO_DIR/${part2}"
    echo "mount -o $mount_options,subvol=$part1 /dev/mapper/$DISKMOUNT $RSYNC_TO_DIR/${part2}"
done


echo "rsync -aAXv --numeric-ids --delete ${RSYNC_FROM_DIR}/ ${RSYNC_TO_DIR}"
echo "pacstrap ${RSYNC_TO_DIR} base linux linux-headers linux-firmware"

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
echo "lsblk -f"
echo "grub-install  --bootloader-id Linux --efi-directory /boot/efi  --modules=\"${modules}\" --sbat /usr/share/grub/sbat.csv"
echo ""
echo "efibootmgr --create --disk /dev/${DISK} --part ${DISKEFI} --label "Linux shim" --loader 'EFI\Linux\shimx64.efi' --unicode"




