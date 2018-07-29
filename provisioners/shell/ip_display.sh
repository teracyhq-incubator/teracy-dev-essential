#! /bin/bash

ip_address=`LANG=en ifconfig  | grep 'inet addr:'| grep -v '127.0.0.1' | cut -d: -f2 | awk '{ print $1 }'`
echo "IP Address: $ip_address"
