#!/bin/sh
switch=br0
/sbin/brctl delif $switch $1
/usr/sbin/tunctl -d $1
exit 0
