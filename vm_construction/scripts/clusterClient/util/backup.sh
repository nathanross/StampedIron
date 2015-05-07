#!/bin/bash

if [ ! $1 ]
then
    echo "error, please provide as an arg the file you wish to back up."
fi

if [ -e $1 ]
then
    if [ -e $1.bak.latest ] && [ `diff $1 $1.bak.latest | wc -l` -eq 0 ]
    then
       echo "not making new backup as there is a current backup at "
       echo "${1}.bak.latest"
       exit 0
    fi
    timestamp=`date +%Y.%m.%d.%H.%M.%S`
    cp $1 $1.bak.$timestamp
    cp $1 $1.bak.latest
    echo "backed up to ${1}.bak.${timestamp}"
    echo "backed up to ${1}.bak.latest"
    exit 0
else
    echo "error, that file doesn't exist!"
    exit 1
fi
