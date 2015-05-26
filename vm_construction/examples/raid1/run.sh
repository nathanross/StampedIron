#!/bin/bash
btrfs device add /dev/sda2 /
btrfs balance start -dconvert=raid1 -mconvert=raid1 /
sync
shutdown now
