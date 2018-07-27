#!/usr/bin/env bash

[ ! -e "server.conf" ] && echo -e "\033[0;35mserver.conf \033[1;31mnot found\033[0m" && exit 1
. server.conf
[ "$updsleep" == 0 ] && exit 0

disconnect()
{
	screen -S $screen -p 0 -X stuff 'say New version '$(<$infofile)' available, update scheduled\n'
	while :; do
		num="$(netstat -nt | grep -F $port | wc -l)"
		echo -e "\033[1;37m$num \033[0;33mconnections.\033[0m"
		(($num == 0)) && break
		sleep 30
	done
}

update()
{
	while :; do
		./server_update.sh && break
		sleep $updsleep
	done
}

echo -e "\033[1;34mUpdate scheduled every \033[1;37m$updsleep\033[0m"
while :; do
	update
	disconnect

	screen -S $screen -p 0 -X stuff '\nstop Server update\n'
	echo -e "\033[1;33mStopped server for update.\033[0m"
done
exit 0
