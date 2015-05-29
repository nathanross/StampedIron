#!/bin/bash

# Copyright 2015 Nathan Ross
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
# http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.
#
DIR=$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )
apt-get -y install bridge-utils uml-utilities

#add bridge interface to network config
cat ${DIR}/bridge_interface >> /etc/network/interfaces

cp *.sh /usr/local/bin

#enable packet forwarding, NAT
sysctl net.ipv4.ip_forward=1
sysctl net.ipv6.conf.default.forwarding=1
sysctl net.ipv6.conf.all.forwarding=1
iptables -t nat -A POSTROUTING -o eth0 -j MASQUERADE
iptables -I FORWARD -m conntrack --ctstate RELATED,ESTABLISHED -j ACCEPT
iptables -I FORWARD -o eth0 -j ACCEPT
iptables -I FORWARD -m physdev --physdev-is-bridged -j ACCEPT
echo '1' > /proc/sys/net/ipv4/ip_forward

#bring up bridge interface
service networking restart
