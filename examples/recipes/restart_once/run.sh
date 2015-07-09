#!/bin/bash
this_recipe=`mount | grep -i /mnt/stamped_iron_auto | cut -d' ' -f1`
if [ ! -e /var/log/si_restarts ] || \
       ! `cat /var/log/si_restarts | grep $this_recipe > /dev/null`; then
    echo $this_recipe >> /var/log/si_restarts
    shutdown -r now
fi
