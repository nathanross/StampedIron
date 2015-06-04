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

DIR=$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )
export IFS=''
error() { echo -e $@; exit 1; }
split(){ local -n ret=$1; IFS=$2; ret=($3); }
usage() {
    error "\n
run_image.sh <image>:prio (<folder or .img to add as sdb>:prio)\n
this script is for building images using the automation shim, or launching\n
an image with boilerplate settings for debugging.\n
\n
This project is for making the building of VMs easier, and likewise\n
you'll have more flexibility and scalability in provisioning VMs if \n
you create your own domain file for use with virsh, or another \n
hypervisor leveraging tool / VMM like Qemu, Virtualbox, VMWare, etc.\n
\n

environment vars:
NAME = name to give to instance
VCPU= num of vcpus. 2 is default
MEM= amount of mem to use in KB. 219200 is default
BOOT_PRIO= 'sdb' or 'sda' depending on whether primary or secondary disk should have boot prio

"
}
mkdtmp() {
    local -n l=$1;
    if [ $WORKDIR ]; then
       l="${WORKDIR}/`date +%s%N`"
       mkdir -p $l
    else
        l=`mktemp -d 2>/dev/null || mktemp -d -t 'mytmpdir'`
    fi
}

mkRoImage() {
    local -n l_newdisk=$1;
    local -r d_src=$2 d_tmp=$3;
    dirsize=`du -s --block-size=1 "$d_src" | cut -f1`
    l_newdisk=$d_tmp/`date +%s%N`.raw
    qemu-img create $l_newdisk `echo "$dirsize + (50*1024*1024)" | bc`
    i=`expr $i + 1`
    yes | mkfs.ext4 -L "stampedIronShim"
    mkdir -p $tmpdir/mnt
    mount $l_newdisk $tmpdir/mnt
    cp -rT $src_dir $tmpdir/mnt
    umount $l_newdisk
}

main() {
    local -r name=${NAME:-vcon`date +%s`} vcpu=${VCPU:-2} mem=${MEM:-219200}
    local disks='' bootprio='' l_disk=''    

    int_re='^[0-9]+$'
    
    mkdtmp tmpdir
    i=0
    for x in $@
    do
        unset arr_disk
        split arr_disk ':' "$x"
        echo "arr:${arr_disk[*]}"
        l_disk=${arr_disk[0]}
        bootprio=${arr_disk[1]}
        echo "x:$x"
        echo "ld:$l_disk"
        echo "b:$bootprio"
        [[ $bootprio =~ $int_re ]] || usage
        
        [ ! -e $l_disk ] && \
            error "asked to use disk at $l_disk but no file/dir exists there"
        
        [ -d $l_disk ] && mkRoImage l_disk $l_disk $tmpdir        
        bootprio=${arr_disk[1]}
        disks="${disks}\n<disk type='file' device='disk'>
      <driver name='qemu' type='raw'/>
      <source file='${l_disk}'/>
      <target dev='sda'/>
      <address type='drive' bus='0' target='0' unit='$i' />
      <boot order='${bootprio}' />
    </disk>"
        i=`expr $i + 1`
    done
    
    [ ! $disks ] && usage
    env -i name=$name mem=$mem vcpu=$vcpu disks=$disks \
        envsubst < ${DIR}/virsh/domain.xml > $tmpdir/domain.xml
    virsh create $tmpdir/domain.xml
    
    #virsh start $name
    #virsh remove $name
    #rm -rf $tmpdir
    
}

main $@
