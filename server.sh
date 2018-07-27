#!/usr/bin/env bash

cd "$(dirname "$0")"
[ ! -e "server.conf" ] && echo -e "\033[0;35mserver.conf \033[1;31mnot found\033[0m" && exit 1
. server.conf

# Check for existing screen session
screen -S $screen -Q select . && echo -e "\033[1;31mSession \033[1;37m$screen \033[1;31malready exists\033[0m" && exit 1

[ "$updsleep" != 0 ] && ./server_update.sh

# Start screen session with windows
screen -c screenrc -S $screen -p 0
