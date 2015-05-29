#!/bin/sh
switch=br0
if [ ! $1 ]; then exit 1; fi
/sbin/ip link set $1 down
/sbin/brctl delif $switch $1
/sbin/ip link delete dev $1
#/usr/sbin/tunctl -d $1
exit 0
