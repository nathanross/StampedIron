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

export USAGE_MSG="
    stampedIron.sh

    takes a set of vars as to where to create an installed image
    and from what sources (seedfile, recipes), and creates the 
    installed image.

    caches autoinstall iso and base unattended install for
    faster iteration when tweaking changes to recipes

required env dirs:
    SCRATCH : dir for storing large temporary files
    SRC : source iso for creating autoinstall iso
    SEEDFILE : source seedfile for creating autoinstall iso
     value \$cookbook in this var will be replaced with
     this directory's example/seedfiles
    RECIPES : recipes, if any, to run on raw installed image.
     value \$cookbook in this var will be replaced with
     this directory's example/recipes
    OUTDIR : dir for outputting autoinstall iso,
             raw installed image, and cooked image.

optional env dirs:
    FNAME_ISO : name of autoinstall iso. default is auto_install.iso
    FNAME_DISK : name of cooked image, default is output.disk
    RECREATE_ISO : if you've changed the seedfile, set this to 1
     to recreate the seedfile
    FORCE_REINSTALL : create a new raw installed image from the
     autoinstall iso; implied by no autoinstall iso or RECREATE_ISO.
     only ever need to set this manually if you use ./run_image
     on the autoinstall iso accidentally.
    DEBUG : do not launch image (+run any recipes) from 
     raw installed disk, but from cooked/live image.
"

DIR=$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )
. ${DIR}/tools/_common.sh
stampedIron=${DIR}
d_tools=${DIR}/tools
cookbook=$stampedIron/examples/recipes

main() {
    local -r scratch=$SCRATCH outdir=$OUTDIR src=$SRC
    [ -d $outdir ] || usage 'must provide a dir $OUTDIR'
    [ -f $src ] || usage 'must provide a file $SRC'

    seedfile=`echo $SEEDFILE | env -i cookbook=$stampedIron/examples/seedfiles envsubst '$cookbook'`
    [ -f $seedfile ] || usage "must provide a file \$SEEDFILE, you provided $seedfile"

    [ "$RECIPES" ] || usage 'must provide $RECIPES'
    recipes=`echo $RECIPES | env -i cookbook=$stampedIron/examples/recipes envsubst '$cookbook'`

    local -r fname_iso=${FNAME_ISO:-auto_install.iso} \
          fname_disk=${FNAME_DISK:-output.disk} \
          recreate_iso=${RECREATE_ISO:-0} \
          run_vars=${RUN_VARS:-''} \
          debug=${DEBUG:-0}
    local force_reinstall=${FORCE_REINSTALL:-0}
    
    if [ ! -e $outdir/$fname_iso ] ||
           ( [ $recreate_iso -eq 1 ] ); then
        #todo no env var, just check if preseed is more recently modified.
        mkdtmp d_preseed
        (envsubst < $seedfile) > $d_preseed/preseed
        dbg $d_tools/./inject_autoinstall_seedfile.sh $src $outdir/$fname_iso $d_preseed/preseed || exit 1
        force_reinstall=1
    fi

    if [ ! -e $outdir/$fname_disk.bak ] || [ $force_reinstall -eq 1 ]; then
        dbg $d_tools/./unattended_install.sh $outdir/$fname_iso $outdir/$fname_disk || exit 1
        cp $outdir/$fname_disk $outdir/$fname_disk.bak || exit 1
    else
        [ $debug -eq 0 ] && \
            cp $outdir/$fname_disk.bak $outdir/$fname_disk || exit 1
    fi

    export $RUN_VARS
    dbg $d_tools/./run_image.sh $outdir/$fname_disk::1 \
              $recipes
}
main $@
