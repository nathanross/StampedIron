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

#run.sh <image> <image to mount>
if [ $2 ]
then
    if [ -d $2 ]
    then
        umount /tmp/dirhost.raw
        rm -f /tmp/dirhost.raw
        qemu-img create /tmp/dirhost.raw 200M
        yes | mkfs.ext4 /tmp/dirhost.raw 
        mount /tmp/dirhost.raw /mnt
        shopt -s dotglob
        cp -r $2/* /mnt
        umount /mnt
        hdb=/tmp/dirhost.raw
    else
        hdb=$2
    fi
    qemu-system-x86_64 -enable-kvm -cpu host -smp 2 -m 2048 -hda $1 -hdb $hdb
else
    qemu-system-x86_64 -enable-kvm -cpu host -smp 2 -m 2048 -hda $1 
fi
