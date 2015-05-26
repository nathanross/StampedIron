#!/bin/bash
apt-get -y update
apt-get -y update
apt-get -y upgrade
sync
btrfs balance start /
shutdown now
