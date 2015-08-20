#! /bin/bash

source=world
bakfolder=backup
prefix="${source}_"
suffix=.tar.bz2
sleep=1h
baknum=64

function doBackup
{
	echo -n "Backing up: "
	screen -S MC -p 0 -X stuff 'say 备份中, 服务器进入只读模式!\nsave-off\nsave-all\n'
	sleep 3s
	echo -n "$1... "
	tar jcf "$bakfolder/$1" "$source"
	echo "Done."
	screen -S MC -p 0 -X stuff 'save-on\nsay 备份完成.\n'
}

function tidyBackups
{
	remove="$(find -L "$bakfolder" -type f -name "${prefix}*-*${suffix}" 2> /dev/null | grep "[0-9]\{8\}-[0-9]\{6\}" | sort | head -n -$baknum | xargs)"
	[ -z "$remove" ] && return
	rm -f $remove
	echo "Removed: $remove"
}

declare -a backups
mkdir -p "$bakfolder"

while :; do
	filename="${prefix}$(date +%Y%m%d-%H%M%S)${suffix}"
	doBackup "$filename"
	tidyBackups
	sleep ${sleep}
done
exit
