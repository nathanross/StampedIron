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
    ${DIR}/./run_image.sh ${out_device}:2 ${autoinstall_iso}:1
}

main $@
