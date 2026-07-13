#!/bin/sh
# a simple ping wrapper with less verbose output

# John Plocher residing at gmail

ip=$*
ping -oqt 1 $ip 2>&1 > /dev/null
if [ $? -ne 0 ]; then r="DOWN"; else r="UP  "; fi
echo "$r $ip"

