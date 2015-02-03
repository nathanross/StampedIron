#!/bin/bash
#ramboot
#see http://archive.today/1Dzsx

echo " -- RAMBOOT (ramboot.sh) --"
echo " -- adding a boot-to-ram option to this system... --"

DIR=$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )

#1. replace fstab root partition mount point with tmpfs
$DIR/./backup.sh /etc/fstab || exit 1
sed -ri 's/^[^#]* +\/ +.*$/none \/ tmpfs 0 0/g' /etc/fstab

#2. temporarily change initrd script,
# generate a new initrd image, then return original initrd
# script

#a. backup old script
dirInitram=/usr/share/initramfs-tools/scripts
$DIR/./backup.sh ${dirInitram}/local || exit 1

#b. make ramboot changes
# WARNING: I think this or the grunt script is
# slightly different in Ubuntu. TODO: look into
# and make changes
# so it accommodates that difference.

curLine="mount \\$.roflag. -t \\$.FSTYPE. \\$.ROOTFLAGS. \\$.ROOT. \\$.rootmnt."
replacement="mkdir \/ramboottmp \n mount \${roflag} -t \${FSTYPE} \${ROOTFLAGS} \${ROOT} \/ramboottmp \n mount -t tmpfs -o size=100% none \${rootmnt} \n cd \${rootmnt} \n cp -rfa \/ramboottmp\/* \${rootmnt} \n"
if [ `grep "$curLine" ${dirInitram}/local | wc -l` -eq 0 ]
then
    echo "couldn't find replacement line in ${dirInitram}/local exiting"
    exit 1
fi
#echo "sed -ri s/$curLine/$replacement/g ${dirInitram}/local"
sed -ri "s/$curLine/$replacement/g" ${dirInitram}/local

#c. generate new image
rm -f /boot/initrd.img-ramboot #fails silently if DNE
mkinitramfs -o /boot/initrd.img-ramboot || exit 1

#d. backup ramboot changes and replace with old script.
echo "backed up ramboot initrd script to ${dirInitram}/local.ramboot"
cp ${dirInitram}/local ${dirInitram}/local.ramboot
cp -f ${dirInitram}/local.bak.latest ${dirInitram}/local

#3. replace fstab with previous fstab
cp /etc/fstab /etc/fstab/fstab.ramboot
cp /etc/fstab.bak.latest /etc/fstab

#4. add ramboot as an option to grub
${DIR}/./ramboot-fix-grub.sh

echo "-- /RAMBOOT COMPLETED --"
