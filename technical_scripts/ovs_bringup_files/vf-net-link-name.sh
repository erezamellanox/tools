#!/bin/bash

SWID="$1"
PORT="$2"

for i in `ls -1 /sys/class/net/*/address`; do
    nic=`echo $i | cut -d/ -f 5`
    address=`cat $i | tr -d :`
    if [ "$address" = "$SWID" ]; then
        echo "NAME=${nic}_$PORT"
        break
    fi
Done
