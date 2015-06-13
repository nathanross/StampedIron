#!/bin/bash
DIR=$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )
cp ${DIR}/interfaces /etc/network/interfaces
if [ ! $IP_ADDRESS ] || [ ! $NETMASK ] || [ ! $GATEWAY ]; then
    echo 'error, you must provide env vars $IP_ADDRESS, $NETMASK, and $GATEWAY or this script'
    echo 'doesnt know what to do.'
    exit 1
fi
echo -e "    address $IP_ADDRESS
      netmask $NETMASK
      gateway $GATEWAY
" >> /etc/network/interfaces
 
service networking restart
ifup eth0

