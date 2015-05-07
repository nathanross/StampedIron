#!/bin/bash
DIR=$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )
utildir=${DIR}/util/

#to be run inside a VM where you have ensured internet access
cp ${DIR}/jessie.sources.list /etc/apt/sources.list

apt-get -y update && apt-get -y upgrade
apt-get -y install intel-microcode git mercurial curl wget ntp
echo 'snd-hda-intel' >> /etc/modules-load.d/modules.conf
cp ${dir}/wlan0.home /etc/network/interfaces.d/wlan0.home

$utildir/./ramboot.sh
btrfs balance start /
