#!/bin/bash

[ ! -e "server.conf" ] && echo "server.conf not found!" && exit 1
. server.conf

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

while :; do
	update
	disconnect

	screen -S $screen -p 0 -X stuff 'stop Server update\n'
	echo "Stopped server for update."
done
