#!/bin/bash
java="java -Xmx6G"
args="nogui"
restart=false

update=true
infofile=latest.txt

while :; do
	[ "$update" == "true" ] && ./update.sh "$infofile"
	[ -e "$infofile" ] && file="$(<$infofile)"
	[ -z "$file" ] && echo -e "\e[1;31mCannot locate executable file from $infofile\e[0m" && read -s && exit 1

	echo -e "\e[1;33mStarting $file...\e[0m"
	$java -jar ./"$file" $args
	[ "$restart" != "true" ] && read -s && exit 0
	sleep 5
done
