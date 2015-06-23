#!/bin/bash
DIR=$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )
stampedIron=${DIR}
cookbook=$stampedIron/examples/recipes

usage() {
    #if $1; then echo "error: ${1}"; fi
    echo -e "
    pipeline.sh

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
    exit 1
}

scratch=${SCRATCH:-''}
[ -d $scratch ] || usage 'must provide a dir $SCRATCH'

outdir=${OUTDIR:-''}
[ -d $outdir ] || usage 'must provide a dir $OUTDIR'

src=${SRC:-''}
[ -f $src ] || usage 'must provide a file $SRC'

seedfile=(env -i cookbook=$stampedIron/examples/seedfiles envsubst '$cookbook'<<< $SEEDFILE )
[ -f $seedfile ] || usage 'must provide a file $SEEDFILE'

[ $RECIPES ] || usage 'must provide $RECIPES'
recipes=(env -i cookbook=$stampedIron/examples/recipes envsubst '$cookbook'<<< $RECIPES )

fname_iso=${FNAME_ISO:-auto_install.iso}
fname_disk=${FNAME_DISK:-output.disk}
recreate_iso=${RECREATE_ISO:-0}
force_reinstall=${FORCE_REINSTALL:-0}
debug=${DEBUG:-0}


mkdir -p $scratch

if [ ! -e $outdir/$fname_iso ] ||
       ( [ $recreate_iso -eq 1 ] ); then
    #todo no env var, just check if preseed is more recently modified.
    (env -i PROXY=192.168.124.8:3128 envsubst '$PROXY'< $stampedIron/examples/seedfiles/debian.btrfs_raid1.mirroredl.seed) > /tmp/preseed
    WORKDIR=$scratch $stampedIron/./inject_autoinstall_seedfile.sh $src $outdir/$fname_iso /tmp/preseed
    FORCE_REINSTALL=1
fi

if [ ! -e $outdir/$disk.bak ] || [ $force_reinstall -eq 1 ]; then
    WORKDIR=$scratch $stampedIron/./unattended_install.sh $outdir/$fname_iso $outdir/$fname_disk
    cp $outdir/$disk $outdir/$fname_disk.bak
else
    [ $debug -eq 0 ] && \
        cp $outdir/$fname_disk.bak $outdir/$fname_disk
fi

MEM=1024 $stampedIron/./run_image.sh $outdir/$fname_disk::1 \
   $recipes


