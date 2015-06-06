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
insert() {
    local -n newarr=$1
    local pos=$2 newval=$3 oldarr=("${@:4}")
    newarr=()
    i=0
    for x in ${oldarr[*]};
    do
        echo '###'
        echo $x
        [ $i -eq $pos ] && newarr+=($newval)
        newarr+=($x)
        i=`expr $i + 1`
    done
    [ $i -eq $pos ] && newarr+=($newval)
    
}
main() {
    local -r name=${NAME:-vcon`date +%s`} vcpu=${VCPU:-2} mem=${MEM:-219200}
    local disks='' bootprio='' l_disk=''    

    int_re='^[0-9]+$'
    
    mkdtmp tmpdir
    i=0
    devicename=(a b c d e f g h i j)
    ip_disk="${DIR}/virsh/ip/dhcp:100"
    if [ $IP_ADDRESS ];
    then
        cp -rT $DIR/virsh/ip/static /tmp/si_static
        sed -ri "s/address .addr/address $IP_ADDRESS/g" \
            /tmp/si_static/interfaces
        #stampedIron network default if not provided as env var.
        sed -ri "s/netmask .netmask/netmask ${NETMASK:-255.255.255.0}/g" \
            /tmp/si_static/interfaces
        sed -ri "s/gateway .gateway/gateway ${GATEWAY:-192.168.124.1}/g" \
            /tmp/si_static/interfaces
        ip_disk="/tmp/si_static:100"
    fi
    insert disk_set 1 $ip_disk $@
    i=0
    for x in ${disk_set[*]}
    do
        unset arr_disk
        split arr_disk ':' "$x"
        echo "arr:${arr_disk[*]}"
        l_disk=`readlink -f ${arr_disk[0]}`
        bootprio=${arr_disk[1]}
        [[ $bootprio =~ $int_re ]] || usage
        [ ! -e $l_disk ] && \
            error "asked to use disk at $l_disk but no file/dir exists there"
        bootprio=${arr_disk[1]}
        if [[ ${l_disk} =~ \.iso$ ]]; then
            device="type='file' device='cdrom'"
            driver="name='qemu' type='raw'"
            source="file='${l_disk}'"
        elif [ -d $l_disk ]; then
            device="type='dir' device='disk'><readonly/"
            driver="name='qemu'"
            source="dir='${l_disk}'"
        else
            device="type='file' device='disk'"
            driver="name='qemu' type='raw'"
            source="file='${l_disk}'"
        fi
        disks="${disks}
    <disk $device>
      <driver $driver />
      <source $source />
      <target dev='sd${devicename[$i]}'/>
      <address type='drive' bus='0' target='0' unit='$i' />
      <boot order='${bootprio}' />
    </disk>"
        i=`expr $i + 1`
    done
    [ ! $disks ] && usage
    env -i name=$name mem=$mem vcpu=$vcpu disks=$disks \
        envsubst < ${DIR}/virsh/domain.xml > $tmpdir/domain.xml
    cat $tmpdir/domain.xml

    start_time=`date +%s`
    virsh create $tmpdir/domain.xml
    
    sleep 4
    while [ `virsh list --name --state-running | grep -E "^$name\$" | wc -l ` -gt 0 ];
    do
        sleep 1
    done
    end_time=`date +%s`
    echo "start: $start_time"
    echo "end: $end_time"
    echo "wait: `expr $end_time - $start_time`"
    rm -rf $tmpdir
}

main $@
