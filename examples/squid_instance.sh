#!/bin/bash
DIR=$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )

export OUTDIR=/srv/squid/ \
       SRC=/tmp/debian-8.1.0-amd64-CD-1.iso \
       SEEDFILE="\$cookbook/debian.ext4.seed" \
       RUN_ARGS="WAIT_FOR_IP=1" \
       RECIPES="
   \$cookbook/squid
   \$cookbook/shutdown
"

