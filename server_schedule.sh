#!/usr/bin/env bash

[ ! -e "server.conf" ] && echo -e "\e[0;35mserver.conf \e[1;31mnot found\e[0m" && exit 1
. server.conf
[ "$updsleep" == 0 ] && exit 0

disconnect()
{
	screen -S $screen -p 0 -X stuff 'say New version '$(<$infofile)' available, update scheduled\n'
	while :; do
		num="$(netstat -nt | grep -F $port | wc -l)"
		echo -e "\e[1;37m$num \e[0;33mconnections.\e[0m"
		(($num == 0)) && break
		sleep 30s
	done
}

update()
{
	while :; do
		./server_update.sh && break
		sleep $updsleep
	done
}

echo -e "\e[1;34mUpdate scheduled every \e[1;37m$updsleep\e[0m"
while :; do
	update
	disconnect

	screen -S $screen -p 0 -X stuff '\nstop Server update\n'
	echo -e "\e[1;33mStopped server for update.\e[0m"
done
exit 0
