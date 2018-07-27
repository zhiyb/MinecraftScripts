#!/usr/bin/env bash

[ ! -e "server.conf" ] && echo -e "\033[0;35mserver.conf \033[1;31mnot found\033[0m" && exit 1
. server.conf

get()
{
	curl -s $@
}

download()
{
	mkdir -p "$(dirname "$2")"
	curl --progress-bar -o "$2" -L "$1"
	#aria2c --daemon=false --enable-rpc=false -c -o "$2" "$1"
}

echo -e "\n\033[1;37m$(date -Iseconds) \033[1;32m$0\033[1;33m: Fetching manifest...\033[0m"
manifest="$(get "$manifest")"

version="$(echo "$manifest" | jq -r ".latest.$type")"
info="$(echo "$manifest" | jq -r ".versions[] | select(.id == \"$version\")")"
time="$(echo "$info" | jq -r ".releaseTime")"
url="$(echo "$info" | jq -r ".url")"
echo -e "\033[1;33mLatest \033[1;37m$type\033[1;33m: \033[1;37m$version ($time)\033[0m"

file="$folder/$version.jar"
if [ -e "$file" ]; then
	echo -e "\033[1;36mFile \033[1;35m$file \033[1;36malready exists\033[0m"
	echo "$version.jar" > "$infofile"
	exit 1
else
	echo -e "\033[1;33mFetching version metadata...\033[0m"
	meta="$(get "$url")"

	server="$(echo "$meta" | jq -r ".downloads.server")"
	url="$(echo "$server" | jq -r ".url")"

	echo -e "\033[1;33mDownloading \033[1;35m$file \033[33mfrom: \033[1;37m$url\033[0m"
	if ! download "$url" "$file"; then
		echo -e "\033[1;31mUpdate failed!\033[0m"
		exit 2
	fi
fi

echo "$version.jar" > "$infofile"
exit 0
