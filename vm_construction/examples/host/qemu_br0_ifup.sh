#!/bin/sh
switch=br0
if [ ! $1 ]; then exit 1; fi
echo "Bringing up $1 for bridged mode..."
#/usr/sbin/tunctl -u `whoami` -t $1
/sbin/ip link set $1 up promisc on
sleep 0.5s
/sbin/brctl addif $switch $1
exit 0
