#!/bin/bash
# called during initial ramboot.sh setup
# though you will need to run this particular script if you
# 1. update grub version
# 2. reinstall grub
# 3. update grub config due to a kernel update or manual update

DIR=$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )

#if a ramboot entry doesn't exist in current grub...
grubcfg=/boot/grub/grub.cfg
if [ `grep ramboot $grubcfg | wc -l ` -eq 0 ]
then
    ${DIR}/./backup.sh $grubcfg || exit 1
    # grab the first menu entry,
    # replace its initrd.img path with that of ramboot
    # and prepend this modified entry before the original
    # entry in grub.
    lineno=`awk '/^menuentry/ {print NR-1; exit }' /boot/grub/grub.cfg`
    head -n$lineno $grubcfg > /tmp/grub.cfg
    cat /boot/grub/grub.cfg | awk '{ if (/^menuentry/ || x == 1) { x=1; print $0; if (/^\}/) { exit }; } }' | sed -r 's/.boot.initrd.img.*/\/boot\/initrd.img-ramboot/g' | sed -r "s/menuentry *'.*?'/menuentry 'boot to ram'/g" >> /tmp/grub.cfg
    tail -n+$lineno $grubcfg >> /tmp/grub.cfg
    cp /tmp/grub.cfg $grubcfg    
fi
