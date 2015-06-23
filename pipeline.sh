#!/bin/bash
DIR=$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )
stampedIron=${DIR}
cookbook=$stampedIron/examples/recipes

error() { echo $1; exit 1; }

scratch=${SCRATCH:-''}
[ -d $scratch ] || error 'must provide a dir $SCRATCH'


outdir=${OUTDIR:-''}
[ -d $outdir ] || error 'must provide a dir $OUTDIR'

src=${SRC:-''}
[ -f $src ] || error 'must provide a file $SRC'

[ $RECIPES ] || error 'must provide $RECIPES'
recipes=(envsubst '$cookbook'<<< $RECIPES )

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


