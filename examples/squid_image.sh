#!/bin/bash
DIR=$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )
src=/var/cache/install_discs/debian*.iso
stampedIron \
    --dirpath-product /srv/squid \
    --fpath-src-iso ${src[0]} \
    --func-seedgen "m4 \$cookbook/debian.seed.m4" \
    --run-vars "WAIT_FOR_IP=1" \
    --recipes "\$cookbook/squid \$cookbook/shutdown" \
    $@
