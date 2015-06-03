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

export IFS=''
error() { echo -e $@; exit 1 }

main() {
    local -r image=$1 sdb_in=$2
    ([ ! -e $image ] || \
        ([ $sdb_in ] && [ ! -e $sdb_in ])) && \
        error "\n
run_image.sh <image> (<folder or .img to add as sdb>)\n
this script is for building images using the automation shim, or launching\n
an image with boilerplate settings for debugging.\n
\n
This project is for making the building of VMs easier, and likewise\n
you'll have more flexibility and scalability in provisioning VMs if \n
you create your own domain file for use with virsh, or another \n
hypervisor leveraging tool / VMM like Qemu, Virtualbox, VMWare, etc.\n
\n

environment vars:
INSTANCE_NAME = name to give to instance
VCPU= num of vcpus. 2 is default
MEM= amount of mem to use in KB. 219200 is default
BOOT_ORDER=

"

    attach=''
    if [ $sdb_in ]; then
        if [ -d "$mountdir" ]; then
            if [ -e /tmp/dirhost.raw]; then
                umount /tmp/dirhost.raw
            fi
            rm -f /tmp/dirhost.raw
            dirsize=`du -s --block-size=1 "$mountdir" | cut -f1`
            qemu-img create /tmp/dirhost.raw `echo "$dirsize + (50*1024*1024)" | bc`
            yes | mkfs.ext4 -L "stampedIronShim" /tmp/dirhost.raw 
            mount /tmp/dirhost.raw /mnt
            shopt -s dotglob
            cp -r $2/* /mnt
            umount /mnt
            hdb=/tmp/dirhost.raw
        fi
        attach="-hdb $hdb"
    fi

    qemu-system-x86_64 -enable-kvm -cpu host -smp 2 -m 2048 $QEMU_OPTS -hda $image $attach
    
}

main $@
