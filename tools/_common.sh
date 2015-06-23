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

error() { echo -e $@; exit 1; }

mkdtmp() {
    local -n l=$1;
    if [ $WORKDIR ]; then
       l="${WORKDIR}/`date +%s%N`"
       mkdir -p $l
    else
        l=`mktemp -d 2>/dev/null || mktemp -d -t 'mytmpdir'`
    fi
}

usage() {
    [ "$1" ] && echo "error: $@";
    error $USAGE_MSG
}

dbg() {
    [ "$VERBOSE" ] && [ $VERBOSE -eq 1 ] && echo "$@"
    $@
}
