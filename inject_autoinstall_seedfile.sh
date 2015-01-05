#!/bin/bash
# to run:
# pass as 1st argument the name of the preseed file you want to inject.
#
# assumes you want to inject the seedfile in ubunt server,
# change the appropriate bash glob pattern below if not.
 
workdir=/opt/build/tmp
mkdir -p ${workdir}/iso ${workdir}/newiso

if [ ! $1 ]
then
    echo "error. you need to provide the seed file as the argument"
    exit
fi

#mount iso and copy its contents to a rw folder
#if the drive's already mounted, don't remount,
#but we want a fresh newiso directory in either case
#for purposes of enabling easy modification / testing of this script
if [ `mount | grep -i server-amd64.iso | wc -l` -eq 0 ]
then
    mount -o loop *server-amd64.iso ${workdir}/iso
fi

cp -rT ${workdir}/iso ${workdir}/newiso

#move to rw folder, prevent language selection from appearing.
newiso=${workdir}/newiso
echo en > ${newiso}/isolinux/lang
sed -ri 's/ (file=.cdrom.preseed.ubuntu-server.seed) *vga=[0-9]+/auto=true locale=en_US console-setup\/layoutcode=us \1 /g' ${newiso}/isolinux/txt.cfg
#sed -ri 's/ (file=.cdrom.preseed.ubuntu-server.seed) /auto=true \1 /g' ${newiso}/isolinux/txt.cfg
cat $1 ${newiso}/preseed/ubuntu-server.seed > /tmp/tmpseed
sed -ri 's/(steps.*)(language|timezone|keyboard|user|network),//g' /tmp/tmpseed
sed -ri 's/timeout +string +[0-9]{1,2}/timeout string 0/g' /tmp/tmpseed
cp /tmp/tmpseed ${newiso}/preseed/ubuntu-server.seed

#D stands for disable deep directory relocation
#r stands for rock ridge directory information
#V "" stands for the volume ID name.
#J stands for joliet directory info
#l stands for full 31 char ISO9660 filenames 
#-b is the el torito boot image name
#-c is the el torito boot catalog name

#this commented out line doesn't work: the reason: the binary and catalog paths must be relative for some silly reason.
#mkisofs -input-charset utf-8 -D -r -V "ATTENDLESS_UBUNTU" -cache-inodes -J -l -b ${newiso}/isolinux/isolinux.bin -c ${newiso}/isolinux/boot.cat -no-emul-boot -boot-load-size 4 -boot-info-table -o ${workdir}/autoinstall.iso ${newiso}/
cd ${newiso}
mkisofs -input-charset utf-8 -D -r -V "ATTENDLESS_UBUNTU" -cache-inodes -J -l -b isolinux/isolinux.bin -c isolinux/boot.cat -no-emul-boot -boot-load-size 4 -boot-info-table -o ${workdir}/autoinstall.iso ${newiso}/

