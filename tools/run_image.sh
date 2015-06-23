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
split() {
    local -n ret=$1
    local -r delim=$2
    local -r txt=$3
    IFS='';
    ret=();
    local i=0;
    local delim_len=${#delim}
    local agg='' char='' lookahead='' on_delim=1;
    while [ $i -lt ${#txt} ]; do
        char="${txt:$i:1}"
        lookahead="${txt:$i:$delim_len}"
        if [ $lookahead = $delim ]; then
            ret+=("$agg")
            agg=""
            i=`expr $i + $delim_len`
            on_delim=1
        else
            agg="${agg}${char}"
            i=`expr $i + 1`
            on_delim=0
        fi
    done
    [ $on_delim -eq 0 ] && ret+=("$agg")    
}
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
MEM= amount of mem to use in MB. 1024 is default
VERBOSE= 1:print generated domain file. 0 is default.
BLOCKING= 1:block until VM halts then print runtime. 0 is default.


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
        [ $i -eq $pos ] && newarr+=($newval)
        newarr+=($x)
        i=`expr $i + 1`
    done
    [ $i -eq $pos ] && newarr+=($newval)
    
}
main() {
    local -r name=${NAME:-vcon`date +%s`} vcpu=${VCPU:-2} memMB=${MEM:-1024}
    local disks='' bootprio='' l_disk=''
    local wait_for_ip=${WAIT_FOR_IP:-0} blocking=${BLOCKING:-0}
    local verbose=${VERBOSE:-0}

    int_re='^[0-9]+$'
    
    mkdtmp tmpdir
    devicename=(a b c d e f g h i j)
    #todo pass permissions for real tmpdir
    # so need to use named tmpdirs
    i=0
    rm -rf /tmp/si_env
    mkdir -p /tmp/si_env
    envdir=/tmp/si_env
    insert disk_args 1 "$envdir::200" "$@"
    i=0
    for x in ${disk_args[*]}
    do
        unset arr_disk
        split arr_disk :: "$x"
        l_disk=`readlink -f ${arr_disk[0]}`        
        bootprio=${arr_disk[1]:-"`expr 100 + $i`"}
        envadd=${arr_disk[2]}
        [[ $bootprio =~ $int_re ]] || usage
        [ ! -e $l_disk ] && \
            error "asked to use disk at $l_disk but no file/dir exists there"
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
        if [ $envadd ]; then
            split env_args ';' "$envadd"
            envfile="$envdir/sd${devicename[$i]}"
            for arg in env_args; do
                echo "export " $envadd >> $envfile
            done
            chmod +x $envfile
        fi
        i=`expr $i + 1`
    done
    [ ! $disks ] && usage
    env -i name=$name mem=`expr $memMB \* 1024` vcpu=$vcpu disks=$disks \
        envsubst < ${DIR}/virsh/domain.xml > $tmpdir/domain.xml
    [ $verbose -eq 1 ] && cat $tmpdir/domain.xml

    start_time=`date +%s`
    cat $tmpdir/domain.xml
    virsh create $tmpdir/domain.xml 
    sleep 4

    if ! ([ $blocking -eq 1 ] || [ $wait_for_ip -eq 1 ]); then
        exit 0
    fi
       
    mac=`virsh domiflist $name | grep -i network | awk -v x=5 '{print $x}'`

    ip_printed=0
    while [ `virsh list --name --state-running | grep -E "^$name\$" | wc -l ` -gt 0 ];
    do
        end_time=`date +%s`
        diff=`expr $end_time - $start_time`
        if [ $ip_printed -eq 0 ]; then
            ip=`virsh net-dhcp-leases stampedIron | grep -i "$mac" | awk -v x=5 '{print $x }' | cut -d'/' -f1`
            if [ $ip ]; then        
                echo "ip,$ip"
                ip_printed=1
            fi
            if ([ $blocking -eq 0 ]) &&
               ([ $ip_printed -eq 1 ] || [ $diff -gt 60 ]); then
                rm -rf $tmpdir
                exit 0
            fi
        fi
        sleep 1
    done
    # in case machine exits in < 30 seconds
    if [ $blocking -eq 1 ]; then
        end_time=`date +%s`
        echo "start,$start_time"
        echo "end,$end_time"
        echo "wait,`expr $end_time - $start_time`"
    fi
    echo $tmpdir
    #rm -rf $tmpdir
    exit 0
}

main $@
