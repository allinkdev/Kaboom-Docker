#!/bin/sh
set -e
if [ "$EUID" -ne 0 ] then
    echo "Please run as root"
    exit
fi

docker system prune -a -f
./build.sh