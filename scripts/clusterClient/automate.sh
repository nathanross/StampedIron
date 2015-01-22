#!/bin/bash
if [ `virt-what` = kvm ] && [ -e /dev/sdb ]
then
    mount /dev/sdb /mnt
    if [ -e /mnt/run.sh ]
    then
        chmod +x /mnt/run.sh
        /mnt/./run.sh
    fi        
fi
