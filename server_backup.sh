#!/bin/bash

[ ! -e "server.conf" ] && echo "server.conf not found!" && exit 1
. server.conf

suffix=.tar.bz2
pattern="${prefix}[0-9]\{8\}-[0-9]\{6\}\.tar\.bz2\$"

online()
{
	while :; do
		num="$(netstat -nt | grep -F $port | wc -l)"
		(($num != 0)) && echo "$num connections." && break
		sleep 30s
	done
}

doBackup()
{
	echo -n "Backing up: "
	#screen -S $screen -p 0 -X stuff 'say Backup started, entering read-only mode...\nsave-off\nsave-all\n'
	screen -S $screen -p 0 -X stuff '\nsave-off\nsave-all\n'
	sleep 6s
	echo -n "$1... "
	tar jcf "$bakfolder/$1" "$source"
	ln -sf "$1" "$bakfolder/${prefix}latest${suffix}"
	echo "Done."
	screen -S $screen -p 0 -X stuff 'save-on\nsay Backup done.\n'
}

tidyBackups()
{
	remove="$(find -L "$bakfolder" -type f -name "${prefix}*-*${suffix}" 2> /dev/null | grep "$pattern" | sort | head -n -$baknum | xargs)"
	[ -z "$remove" ] && return
	rm -f $remove
	echo "Removed: $remove"
}

declare -a backups
mkdir -p "$bakfolder"

while :; do
	online
	sleep ${baksleep}
	filename="${prefix}$(date +%Y%m%d-%H%M%S)${suffix}"
	doBackup "$filename"
	tidyBackups
done
exit
