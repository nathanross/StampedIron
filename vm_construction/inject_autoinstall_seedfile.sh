#!/bin/bash

# Copyright 2015 Nathan Ross
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
# http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.
#

# to run:
# pass as 1st argument the name of the preseed file you want to inject.
# optional 2nd argument: path to 'cp -r' to cd root
#
# assumes you want to inject the seedfile in ubunt server,
# change the appropriate bash glob pattern below if not.

error() {
    log error $@
    exit 1
}

if [ ! $WORKDIR ]; then
    WORKDIR=/opt/build/tmp
fi
workdir=$WORKDIR

if [ ! $DISTRO ]; then
    DISTRO="debian"
fi
 
workdir=/opt/build/tmp

mkdir -p ${workdir}/iso ${workdir}/newiso
if [ $DISTRO = "debian" ]; then
    mkdir -p ${workdir}/irmod
fi

rm -rf ${workdir}/newiso/*

usage=" 
 inject_seedfile.sh <seed file> (<file or dir to copy to cd root>)

 environment variables:
 WORKDIR - place to locate unarchived iso and new iso.
 DISTRO - distro of cd. Supported values: debian, ubuntu
"

seedfile=$1
copydir=$2

if [ ! $seedfile ] || [ ! -e $seedfile ] || ( [ $copydir ] && [ ! $copydir ] )
then
    error $usage
fi

seedpath=`readlink -f $seedfile`

#mount iso and copy its contents to a rw folder
#if the drive's already mounted, don't remount,
#but we want a fresh newiso directory in either case
#for purposes of enabling easy modification / testing of this script
if [ `mount | grep -i *.iso | wc -l` -eq 0 ]
then
    mount -o loop *.iso ${workdir}/iso
fi
if [ $2 ]
then
    cp -r $2 ${workdir}/newiso
fi
cp -rT ${workdir}/iso ${workdir}/newiso


newiso=${workdir}/newiso
if [ $DISTRO = "ubuntu" ]
then
    echo en > ${newiso}/isolinux/lang
    sed -ri 's/ (file=.cdrom.preseed.ubuntu-server.seed) *vga=[0-9]+/auto=true locale=en_US console-setup\/layoutcode=us \1 /g' ${newiso}/isolinux/txt.cfg
    cat $1 ${newiso}/preseed/ubuntu-server.seed > /tmp/tmpseed
    sed -ri 's/(steps.*)(language|timezone|keyboard|user|network),//g' /tmp/tmpseed
    sed -ri 's/timeout +string +[0-9]{1,2}/timeout string 0/g' /tmp/tmpseed
    cp /tmp/tmpseed ${newiso}/preseed/ubuntu-server.seed

elif [ $DISTRO = "debian" ]
then
    sed -ri 's/timeout 0/timeout 1/g' ${newiso}/isolinux/isolinux.cfg
    #don't know which folder actuall requires it, don't care to find out through A/B testing. Which is the only way to be sure as their documentation on this is shitty.
    cd ${workdir}/irmod
    gzip -d < ${newiso}/install.amd/initrd.gz | \
        cpio --extract --verbose --make-directories --no-absolute-filenames
    cp $seed ./preseed.cfg
    find . | cpio -H newc --create --verbose | \
        gzip -9 > ${newiso}/install.amd/initrd.gz
    cd ../

fi


#D stands for disable deep directory relocation
#r stands for rock ridge directory information
#V "" stands for the volume ID name.
#J stands for joliet directory info
#l stands for full 31 char ISO9660 filenames 
#-b is the el torito boot image name
#-c is the el torito boot catalog name

#this commented out line doesn't work: the reason: the binary and catalog paths must be relative for some silly reason.
#mkisofs -input-charset utf-8 -D -r -V "ATTENDLESS_UBUNTU" -cache-inodes -J -l bi ${newiso}/isolinux/isolinux.bin -c ${newiso}/isolinux/boot.cat -no-emul-boot -boot-load-size 4 -boot-info-table -o ${workdir}/autoinstall.iso ${newiso}/
#cd ${newiso}
genisoimage -input-charset utf-8 -D -r -V "ATTENDLESS_${distro}" -cache-inodes -J -l -b isolinux/isolinux.bin -c isolinux/boot.cat -no-emul-boot -boot-load-size 4 -boot-info-table -o ${workdir}/autoinstall.iso ${newiso}/

