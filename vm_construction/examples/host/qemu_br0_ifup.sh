#!/bin/sh
switch=br0
/usr/sbin/tunctl -u `whoami` -t $1
/sbin/ip link set $1 up
sleep 0.5s
/sbin/brctl addif $switch $1
exit 0
