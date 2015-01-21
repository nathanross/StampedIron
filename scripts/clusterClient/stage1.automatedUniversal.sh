#!/bin/bash
DIR=$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )
utildir=`dirname $DIR`/util/

#to be run inside a VM where you have ensured internet access
cp jessie.sources.list /etc/apt/sources.list

apt-get -y update && apt-get upgrade
apt-get -y install intel-microcode git mercurial curl wget
cp wlan0.home /etc/network/interfaces.d/wlan0.home

$utildir/./ramboot.sh
btrfs balance start /
