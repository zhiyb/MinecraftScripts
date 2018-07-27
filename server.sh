#!/usr/bin/env bash

cd "$(dirname "$0")"
[ ! -e "server.conf" ] && echo -e "\e[0;35mserver.conf \e[1;31mnot found\e[0m" && exit 1
. server.conf

# Check for existing screen session
screen -S $screen -Q select . && echo -e "\e[1;31mSession \e[1;37m$screen \e[1;31malready exists\e[0m" && exit 1

[ "$updsleep" != 0 ] && ./server_update.sh

# Start screen session with windows
screen -c screenrc -S $screen -p 0
