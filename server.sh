#!/bin/bash

cd "$(dirname "$0")"
[ ! -e "server.conf" ] && echo "server.conf not found!" && exit 1
. server.conf

# Check for existing screen session
screen -S $screen -Q select . && echo -e "\e[1;31mSession $screen already exists\e[0m" && exit 1

[ "$updsleep" != 0 ] && ./server_update.sh

# Start screen session with windows
screen -c screenrc -S $screen -p 0
