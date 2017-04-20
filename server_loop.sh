#!/bin/bash

[ ! -e "server.conf" ] && echo "server.conf not found!" && exit 1
. server.conf

while :; do
	[ -e "$infofile" ] && file="$(<$infofile)"
	[ -z "$file" ] && echo -e "\e[1;31mCannot locate executable file from $infofile\e[0m" && exit 1

	echo -e "\e[1;33mStarting $folder/$file...\e[0m"
	(cd $folder; $java -jar "$file" $args)
	[ "$restart" != "true" ] && break
	echo -e "\e[1;33mRestarting in 5 seconds...\e[0m"
	sleep 5s
done
exit 0
