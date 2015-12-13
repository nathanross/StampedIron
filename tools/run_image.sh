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

export USAGE_MSG="
run_image.sh <image>:prio (<folder or .img to add as sdb>:prio)
this script is for building images using the automation shim, or launching
an image with boilerplate settings for debugging.

This project is for making the building of VMs easier, and likewise
you'll have more flexibility and scalability in provisioning VMs if
you create your own domain file for use with virsh, or another 
hypervisor leveraging tool / VMM like Qemu, Virtualbox, VMWare, etc.

environment vars:
NAME = name to give to instance
VCPU= num of vcpus. 2 is default
MEM= amount of mem to use in MB. 1024 is default
VERBOSE= 1:print generated domain file. 0 is default.
BLOCKING= 1:block until VM halts then print runtime. 0 is default.
SCRATCH= location to store temporary disks
"

DIR=$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )
d_virsh=`dirname $DIR`/virsh
export IFS=''

#-- common --

error() { echo -e $@; exit 1; }
usage() { [ "$1" ] && echo "error: $@"; error $USAGE_MSG; }
dbg() { [ "$VERBOSE" ] && [ $VERBOSE -eq 1 ] && echo "$@"; $@; }
is_int() { [[ $1 =~ ^[0-9]+$ ]]; return $?; }
mkdtmp() {
    local -n l=$1;
    if [ "$DIRPATH_SCRATCH" ]; then
       l="${DIRPATH_SCRATCH}/`date +%s%N`"
       mkdir -p $l
    else
        l=`mktemp -d 2>/dev/null || mktemp -d -t 'mytmpdir'`
    fi
}
#layer of indirection to avoid returnvar scoping bug, see README.md
rcv() { local -n ret=$1; $2 ret "${@:3}"; }

#-- /common --

split() {
    local -n ret_split=$1
    local -r delim=$2
    local -r txt=$3

    local result=''
    IFS='';
    result=();
    local i=0;
    local delim_len=${#delim}
    local agg='' char='' lookahead='' on_delim=1;
    while [ $i -lt ${#txt} ]; do
        char="${txt:$i:1}"
        lookahead="${txt:$i:$delim_len}"
        if [ $lookahead = $delim ]; then
            result+=("$agg")
            agg=""
            i=`expr $i + $delim_len`
            on_delim=1
        else
            agg="${agg}${char}"
            i=`expr $i + 1`
            on_delim=0
        fi
    done
    [ $on_delim -eq 0 ] && result+=("$agg")
    # fun fact, this is the only way to identically copy sparse
    # arrays within a single assignment. A typifying comment
    # from the TLDP array page comments:
    # 'just when you thought you were still in kansas'
    ret_split=("${result[@]}")
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

genDiskStr() {
    local -n outstr=$1    
    local -r l_disk_in=$2 bootprio_in=$3 diskId=$4

    #split up disk entry, provide 100+i value for
    # boot priority if none provided
    local -r \
          l_disk=`readlink -f $l_disk_in` \
          bootprio=${boot_prio_in:-"`expr 100 + $i`"} \

    envadd=${arr_disk[2]}

    #sanity test
    is_int $bootprio || usage
    [ -e $l_disk ] || \
        error "asked to use disk at <$l_disk> but no file/dir exists there"

    device="type='file' device='disk'"
    driver="name='qemu' type='raw'"
    source="file='${l_disk}'"
    
    if [[ ${l_disk} =~ \.iso$ ]]; then
        device="type='file' device='cdrom'"
    elif [ -d $l_disk ]; then
        dirsize=`du -L --summarize $l_disk | cut -f1`
        [ "$DIRPATH_SCRATCH" ] || error "asked to use a directory, but this requires the DIRPATH_SCRATCH environment to be set to the path of a scratch dir."
        [ -d "$DIRPATH_SCRATCH" ] || error "the $DIRPATH_SCRATCH directory path provided does not point to an existent directory"
        fpath_tmpdisk=$DIRPATH_SCRATCH/stampedIron-tmp.`date +%s%N`.disk
        #add some padding for blocks, plus a baseline of 15mb for fs min size reqs
        tmpdiskSize=`echo '(' $dirsize ' * ' 1.2 ') + 15000' | bc`
        #convert to int
        echo "size for $l_disk:"
        echo $tmpdiskSize
        tmpdiskSize=`printf '%.0f' $tmpdiskSize`
        echo $tmpdiskSize
        fallocate -l "${tmpdiskSize}k" $fpath_tmpdisk || exit 1
        mkfs.ext4 $fpath_tmpdisk || exit 1
        mntpoint=/mnt/stampediron-mount
        mkdir -p $mntpoint
        mount $fpath_tmpdisk $mntpoint || exit 1
        cp -rT $l_disk $mntpoint || exit 1
        umount $mntpoint
        #losetup -d $loopPoint
        source="file='${fpath_tmpdisk}'"
    fi

    outstr="<disk $device>
      <driver $driver />
      <source $source />
      <target dev='sd${devicename[$i]}'/>
      <address type='drive' bus='0' target='0' unit='$i' />
      <boot order='${bootprio}' />
    </disk>"
}

main() {
    local -r name=${NAME:-vcon`date +%s`} vcpu=${VCPU:-2} memMB=${MEM:-1024}
    local disks='' bootprio='' l_disk=''
    local wait_for_ip=${WAIT_FOR_IP:-0} blocking=${BLOCKING:-0}
    local verbose=${VERBOSE:-0}
    
    devicename=(a b c d e f g h i j)
    
    #todo pass permissions for real tmpdir to virsh
    # so don't need to use named tmpdirs
    i=0
    rm -rf /tmp/si_env
    mkdir -p /tmp/si_env
    envdir=/tmp/si_env
    
    [ ! "$1" ] && usage
    rcv disk_args insert 1 "$envdir::200" "$@"
    i=0
    local diskstr envadd
    local arr_disk y
    for x in ${disk_args[*]}
    do
        unset arr_disk
        unset env_args
        # replace newlines with spaces
        # rm leading and trailing whitespace
        # the way sed reg. works,
        # just using lazy operator
        # won't work here, the lazy operator still
        # captures the whitespace.
        y="`echo "$x" | tr '\n' ' ' | sed -r 's/^ *(.*?[^ ]) *$/\1/g'`"
        
        #continue if empty/ doesn't appear valid.
        `echo -e "$y" | grep -E "^[^a-zA-Z0-9]*$" >/dev/null` && continue
        split arr_disk :: "$y"
        rcv diskstr genDiskStr ${arr_disk[0]} ${arr_disk[1]} $i
        disks="${disks}${diskstr}"
        envadd="${arr_disk[2]}"
        if [ "$envadd" ]; then
            rcv env_args split ';' "$envadd"
            envfile="$envdir/sd${devicename[$i]}"
            for arg in env_args; do
                echo "export " $envadd >> $envfile
            done
            chmod +x $envfile
        fi
        i=`expr $i + 1`
    done

    start_time=`date +%s`

    mkdtmp tmpdir
    env -i name=$name mem=`expr $memMB \* 1024` vcpu=$vcpu disks=$disks \
        envsubst < ${d_virsh}/default_domain.xml > $tmpdir/domain.xml
    virsh net-create ${d_virsh}/default_network.xml 2>/dev/null >/dev/null


    if [ $verbose -eq 1 ]; then
        cat $tmpdir/domain.xml
        virsh create $tmpdir/domain.xml
    else
        result=`virsh create $tmpdir/domain.xml`
        if ! [ $? -eq 0 ]; then echo $result; rm -rf $tmpdir; exit 1; fi
    fi
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
        echo -e "
                 start,$start_time
                 end,$end_time
                 wait,`expr $end_time - $start_time`"
    fi
    echo $tmpdir
    #rm -rf $tmpdir
    exit 0
}

main $@
