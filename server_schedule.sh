#!/bin/bash

[ ! -e "server.conf" ] && echo "server.conf not found!" && exit 1
. server.conf
[ "$updsleep" == 0 ] && exit 0

disconnect()
{
	screen -S $screen -p 0 -X stuff 'say New version '$(<$infofile)' available, update scheduled\n'
	while :; do
		num="$(netstat -nt | grep -F $port | wc -l)"
		echo "$num connections."
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
	echo "Stopped server for update."
done
