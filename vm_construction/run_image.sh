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

image="$1"
mountdir="$2"
[ $image ] || ( echo "./run_image.sh <image> (<folder or .img to add as device>)" && exit 1 )

attach=''
if [ $mountdir ]; then
    if [ -d "$mountdir" ]; then
        umount /tmp/dirhost.raw
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
