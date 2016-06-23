#!/bin/bash

update()
{
	screen -S MC -p 0 -X stuff 'stop 服务器计划更新\n'
	echo "Stopped server for update."
}

while :; do
	num="$(netstat -nt | grep -F 25565 | wc -l)"
	echo "$num connections."
	(($num == 0)) && update && exit
	sleep 30s
done
