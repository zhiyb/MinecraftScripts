#!/bin/bash

[ ! -e "server.conf" ] && echo "server.conf not found!" && exit 1
. server.conf

# Check for existing screen session
screen -S $screen -Q select . && echo -e "\e[1;31mSession $screen already exists\e[0m" && exit 1

[ "$updsleep" != 0 ] && ./server_update.sh

# Main server execution loop
echo -e "\e[1;33mserver_loop.sh\e[0m"
screen -dmS $screen ./server_loop.sh

# Automatic backup
if [ "$baksleep" != 0 ]; then
	sleep 3s
	echo -e "\e[1;33mserver_backup.sh\e[0m"
	screen -S $screen -X screen -t backup ./server_backup.sh
fi

# Automatic update
if [ "$updsleep" != 0 ]; then
	echo -e "\e[1;33mserver_schedule.sh\e[0m"
	screen -S $screen -X screen -t schedule ./server_schedule.sh
fi

screen -r $screen -p 0
