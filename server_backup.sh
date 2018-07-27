#!/usr/bin/env bash

[ ! -e "server.conf" ] && echo -e "\e[0;35mserver.conf \e[1;31mnot found\e[0m" && exit 1
. server.conf
[ "$baksleep" == 0 ] && exit 0

suffix=.tar.bz2
pattern="${prefix}[0-9]\{8\}-[0-9]\{6\}\.tar\.bz2\$"

online()
{
	while :; do
		num="$(netstat -nt | grep -F ESTABLISHED | grep -F $port | wc -l)"
		(($num != 0)) && echo -e "\e[1;37m$num \e[0;33mconnections.\e[0m" && break
		sleep 30s
	done
}

doBackup()
{
	echo -ne "\n\e[1;37m$(date -Iseconds) \e[1;32m$0\e[1;33m: Backing up: "
	#screen -S $screen -p 0 -X stuff 'say Backup started, entering read-only mode...\nsave-off\nsave-all\n'
	screen -S $screen -p 0 -X stuff '\nsave-off\nsave-all\n'
	sleep 10s
	echo -ne "\e[0;35m$1\e[1;33m..."
	tar jcf "$bakfolder/$1" "$source"
	ln -sf "$1" "$bakfolder/${prefix}latest${suffix}"
	echo -e " Done.\e[0m"
	screen -S $screen -p 0 -X stuff 'save-on\nsay Backup done.\n'
}

tidyBackups()
{
	remove="$(find -L "$bakfolder" -type f -name "${prefix}*-*${suffix}" 2> /dev/null | grep "$pattern" | sort | head -n -$baknum | xargs)"
	[ -z "$remove" ] && return
	rm -f $remove
	echo -e "\e[1;31mRemoved: \e[0;35m$remove\e[0m"
}

declare -a backups
mkdir -p "$bakfolder"

echo -e "\e[1;34mBackup scheduled every \e[1;37m$baksleep\e[0m"
while :; do
	online
	sleep ${baksleep}
	filename="${prefix}$(date +%Y%m%d-%H%M%S)${suffix}"
	doBackup "$filename"
	tidyBackups
done
exit 0
