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

# to run:
# pass as 1st argument the name of the preseed file you want to inject.
# optional 2nd argument: path to 'cp -r' to cd root
#
# assumes you want to inject the seedfile in ubunt server,
# change the appropriate bash glob pattern below if not.
DIR=$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )
export IFS=''

error() { echo -e $@; exit 1 }

append_late_command() {
    local -n ret_string=$1
    local shellscript=$2 seed_data=$3
    
    #ensure each line ends with semicolon and then
    # replace newlines with spaces
    shellscript=`echo "$shellscript" | sed -r 's/([^;])$/\1;/g' | tr '\n' ' '`
    
    if [ `echo "$seed_data" | grep -E '^d-i preseed/late_command string ' $seedpath | wc -l` -gt 0 ]
    then
        ret_string=`echo -e "$seed_data" | sed -r "s@^(d-i preseed/late_command string) @\1 $shellscript @"`
    else
        ret_string=`echo -e "$seed_data" "\nd-i preseed/late_command string $shellscript"`
    fi

}

main() {
    local src_iso=$1 seedfile=$2 copydir=$3
    
    local d_work=${WORKDIR:-"/opt/build/tmp"}
    local dist=${DISTRO:-"debian"}

    [ ! -e ${src_iso} ] || \
        [ ! -e ${seedfile} ] || \
        ( [ $copydir ] && [ ! -e ${copydir} ] ) || \
        error " \n
 inject_seedfile.sh <src iso> <seed file> (<file or dir to copy to cd root>)\n
\n
 environment variables:\n
 WORKDIR - place to locate unarchived iso and new iso.\n
 DISTRO - (deprecated) distro of cd. Supported values: debian, ubuntu \n
"

    local d_mntiso=${d_work}/iso
    local d_newiso=${d_work}/newiso
    
    mkdir -p ${d_mntiso} ${d_newiso}
    [ $dist = "debian" ] && mkdir -p ${d_work}/irmod

    rm -rf ${d_work}/newiso/*

    # if iso is not mounted mount it.
    grep -qs `basename $src_iso` /proc/mounts || \
        mount -o loop ${src_iso} ${d_mntiso}
    
    # copy over mounted comments to a new directory
    #-T option is so it copies into the dir rather
    # then creating a subdir. The reason we don't use a wildcard
    # here is hidden files, shopt dotglob compatibility problem potential.
    cp -rT ${d_mntiso} ${d_newiso}

    # the automation shim is used to run
    # on start-up, without any human action, arbitrary run.sh
    # scripts in specially labeld /dev/sdb partitions.
    cp -r ${DIR}/automation_shim ${d_newiso}
    [ $copydir ] && cp -r ${copydir} ${d_newiso}


    if [ $dist = 'debian' ] || [ $dist = 'ubuntu' ]
    then
        # adding the automation shim as a startup service
        # is done by adding a late command on the seedfile
        # but there can only be one late command, so if a late
        # command is extant in the user's preseed, the shim
        # late command is appended to it.

        local seed_data='';
        append_late_command seed_data \
                            `cat ${DIR}/automation_shim/late_command.seed` \
                            `cat $seedfile`
        #echo "$seed_data"

        if [ $dist = "ubuntu" ]; then
            echo en > ${d_newiso}/isolinux/lang
            sed -ri 's/ (file=.cdrom.preseed.ubuntu-server.seed) *vga=[0-9]+/auto=true locale=en_US console-setup\/layoutcode=us \1 /g' "${d_newiso}/isolinux/txt.cfg"
            echo -e "$seed_data \n" | cat - ${d_newiso}/preseed/ubuntu-server.seed > /tmp/tmpseed
            sed -ri 's/(steps.*)(language|timezone|keyboard|user|network),//g' /tmp/tmpseed
            sed -ri 's/timeout +string +[0-9]{1,2}/timeout string 0/g' /tmp/tmpseed
            cp /tmp/tmpseed ${d_newiso}/preseed/ubuntu-server.seed
        elif [ $dist = "debian" ]; then
            sed -ri 's/timeout 0/timeout 1/g' ${d_newiso}/isolinux/isolinux.cfg
            # don't know which folder actually requires it, should find out through A/B testing.
            # Which is the only way to be sure as their documentation on this is poor.
            cd ${d_work}/irmod
            gzip -d < ${d_newiso}/install.amd/initrd.gz | \
                cpio --extract --make-directories --no-absolute-filenames
            echo ${seed_data} > ./preseed.cfg
            find . | cpio -H newc --create | \
                gzip -9 > ${d_newiso}/install.amd/initrd.gz
            cd ../
        fi
    fi
    
    #D stands for disable deep directory relocation
    #r stands for rock ridge directory information
    #V "" stands for the volume ID name.
    #J stands for joliet directory info
    #l stands for full 31 char ISO9660 filenames 
    #-b is the el torito boot image name
    #-c is the el torito boot catalog name

    #this commented out line doesn't work: the reason: the binary and catalog paths must be relative for some silly reason.
    #mkisofs -input-charset utf-8 -D -r -V "ATTENDLESS_UBUNTU" -cache-inodes -J -l bi ${newiso}/isolinux/isolinux.bin -c ${newiso}/isolinux/boot.cat -no-emul-boot -boot-load-size 4 -boot-info-table -o ${workdir}/autoinstall.iso ${newiso}/
    #cd ${newiso}
    genisoimage -input-charset utf-8 -D -r -V "ATTENDLESS_${dist}" -cache-inodes -J -l -b isolinux/isolinux.bin -c isolinux/boot.cat -no-emul-boot -boot-load-size 4 -boot-info-table -o ${d_work}/autoinstall.iso ${d_newiso}/

}

main $@
