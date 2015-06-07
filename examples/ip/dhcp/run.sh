#!/bin/bash
DIR=$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )
cp ${DIR}/interfaces /etc/network/interfaces
service networking restart
ifup eth0
