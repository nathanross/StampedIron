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

#BTRFS is one of the few filesystems where changing the UUID both
# 1. cannot be done using the popular tool libraries
# 2. changing manually would be extremely complicated
#     (in other filesystems its as easy as changing a few bytes
#        at a static position. In BTRFS, the uuid is used
#        to calculate a checksum for each header)

src_device=$1
target_device=$2

if [ ! $src_device ] || [ ! $target_device ] || [ ! -e $src_device ] || [ -e $target_device ];
then
    echo "usage: ./btrfs_uuid_change.sh <src img> <new img path>"
fi

size=`stat $src_device -c "%s"`
count_4k=`echo "$size / 4096" | bc `
dd if=/dev/zero of=$target_device bs=4096 count=$count_4k

losetup /dev/loop8 $src_device
