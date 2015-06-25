#!/bin/bash
DIR=$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )
src=/var/cache/install_discs/debian*.iso
export OUTDIR=/srv/squid \
       SRC=${src[0]} \
       SEEDFN="m4 \$cookbook/debian.seed.m4" \
       RUN_VARS="WAIT_FOR_IP=1" \
       RECIPES="\$cookbook/squid \$cookbook/shutdown"

