#run.sh <image> <image to mount>
if [ $2 ]
then
    echo "aaaa"
    if [ -d $2 ]
    then
        echo "bbbb"
        umount /tmp/dirhost.raw
        rm -f /tmp/dirhost.raw
        qemu-img create /tmp/dirhost.raw 200M
        yes | mkfs.ext4 /tmp/dirhost.raw 
        mount /tmp/dirhost.raw /mnt
        cp -r $2 /mnt
        umount /mnt
        hdb=/tmp/dirhost.raw
    else
        hdb=$2
    fi
    qemu-system-x86_64 -enable-kvm -cpu host -smp 2 -m 2048 -hda $1 -hdb $hdb
else
    qemu-system-x86_64 -enable-kvm -cpu host -smp 2 -m 2048 -hda $1 
fi
