#!/bin/bash

[ ! -e "server.conf" ] && echo -e "\e[0;35mserver.conf \e[1;31mnot found\e[0m" && exit 1
. server.conf

echo -e "\e[1;34mServer auto restart: \e[1;37m$restart\e[0m"
while :; do
	[ -e "$infofile" ] && file="$(<$infofile)"
	[ -z "$file" ] && echo -e "\e[1;31mCannot locate executable file from \e[0;35m$infofile\e[0m" && exit 1

	echo -e "\n\e[1;37m$(date -Iseconds) \e[1;32m$0: \e[1;33mStarting \e[1;35m$folder/$file...\e[0m"
	(cd $folder; $java -jar "$file" $args)
	[ "$restart" != "true" ] && break
	echo -e "\e[1;33mRestarting in 5 seconds...\e[0m"
	sleep 5s
done
exit 0
