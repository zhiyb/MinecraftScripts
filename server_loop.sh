#!/usr/bin/env bash

[ ! -e "server.conf" ] && echo -e "\033[0;35mserver.conf \033[1;31mnot found\033[0m" && exit 1
. server.conf

echo -e "\033[1;34mServer auto restart: \033[1;37m$restart\033[0m"
while :; do
	[ -e "$infofile" ] && file="$(<$infofile)"
	[ -z "$file" ] && echo -e "\033[1;31mCannot locate executable file from \033[0;35m$infofile\033[0m" && exit 1

	echo -e "\n\033[1;37m$(date +%Y-%m-%dT%H:%M:%S%z) \033[1;32m$0: \033[1;33mStarting \033[1;35m$folder/$file...\033[0m"
	(cd $folder; $java -jar "$file" $args)
	[ "$restart" != "true" ] && break
	echo -e "\033[1;33mRestarting in 5 seconds...\033[0m"
	sleep 5s
done
exit 0
