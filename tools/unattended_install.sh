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
. $DIR/_common.sh
export IFS=''

main() {
    local -r autoinstall_iso=$1 out_device=$2 size=${3:-"14.5G"}

    #usage
    ([ ! $autoinstall_iso ] || [ ! -e $autoinstall_iso ] || \
        [ ! $out_device ]) && \
        error "\n
unattended_install.sh <autoinstall_iso> <out_device> (<new_disk_size>)\n
\n
    <out_device>: device or disk image to install to.\n
       if a non-existent path, creates raw .img of size <new_disk_size> \n
\n
    <new_disk_size> defaults to 14.5gb
"
    
    [ ! -e $out_device ] && qemu-img create $out_device $size
    start_time=`date +%s`
    nice -n-10 kvm -hda ${out_device} -cdrom ${autoinstall_iso} -smp 2 -m 1024 -boot d
    end_time=`date +%s`
    echo "start,$start_time"
    echo "end,$end_time"
    echo "wait,`expr $end_time - $start_time`"

    # multipartition installs over virsh scsi controllers
    # have had initrd problems on startup that vanilla qemu has not.
    # until we test out a good device setup for virsh install xml,
    # just using qemu-specific cmd
    #${DIR}/./run_image.sh ${out_device}:2 ${autoinstall_iso}:1
}

main $@
