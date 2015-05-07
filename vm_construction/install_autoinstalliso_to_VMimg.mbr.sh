#!/bin/bash
if [ ! $WORKDIR ]
then
    WORKDIR=/opt/build/tmp
fi
workdir=$WORKDIR

if [ $1 ]
then
    size=$1
else
    echo "setting image size to default of 14.5gb"
    size=14.5G
fi

#if [ $1 = "/dev/sda" ]
#then
#    echo "error: you specified the first hard disk as the install drive. You almost certainly don't want this. You'll get the biggest security benefit of this system (easy on-the-go full disk hash). having a system that is hard to carry with you. if you want to persist to hard drive, a better approach would be to install to a usb master, and put either usb in the comp, boot to ram, then copy usb contents to hard disk. don't forget to make an extra usb slave in case of disk failure of the first and you don't have time that day to spend an hour writing 8gb over usb 2.0"
#    exit
#fi

rm -f $workdir/disk.raw
qemu-img create $workdir/disk.raw $size
qemu-system-x86_64 -enable-kvm -cpu host -smp 2 -cdrom $workdir/autoinstall.iso -boot order=d -m 2048 $workdir/disk.raw