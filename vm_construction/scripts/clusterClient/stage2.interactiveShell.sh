#!/bin/bash
DIR=$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )
utildir=`dirname $DIR`/util/

firmware=`apt-cache search firmware | grep -iE ^firmware | cut -d' ' -f1`
apt-get install $firmware
#apt-get -y install doesn't work bcause of eulas and whatnot.XYU
btrfs balance start /
