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

