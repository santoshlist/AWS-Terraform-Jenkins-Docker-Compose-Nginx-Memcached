#!/bin/sh

# My general wait for script
# Proccess command line args
addr=$1; shift
port=$1; shift
ret=5

until curl --retry-delay 6 --connect-timeout 5 --max-time 5 --retry 5 \
--silent --fail ${addr}:${port} || [ $ret -eq 0 ]; do
    sleep 5 
    ret=$((ret-1))
done

# Exit if the number of retries left is none
[ $ret -eq 0 ] && exit 1


# Execute commands
echo "$@"
[ $# -gt 0 ] && exec "$@"