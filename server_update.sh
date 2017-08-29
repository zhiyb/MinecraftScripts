#!/bin/bash

[ ! -e "server.conf" ] && echo -e "\e[0;35mserver.conf \e[1;31mnot found\e[0m" && exit 1
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

echo -e "\n\e[1;37m$(date -Iseconds) \e[1;32m$0\e[1;33m: Fetching manifest...\e[0m"
manifest="$(get "$manifest")"

version="$(echo "$manifest" | jq -r ".latest.$type")"
info="$(echo "$manifest" | jq -r ".versions[] | select(.id == \"$version\")")"
time="$(echo "$info" | jq -r ".releaseTime")"
url="$(echo "$info" | jq -r ".url")"
echo -e "\e[1;33mLatest \e[1;37m$type\e[1;33m: \e[1;37m$version ($time)\e[0m"

file="$folder/$version.jar"
if [ -e "$file" ]; then
	echo -e "\e[1;36mFile \e[1;35m$file \e[1;36malready exists\e[0m"
	echo "$version.jar" > "$infofile"
	exit 1
else
	echo -e "\e[1;33mFetching version metadata...\e[0m"
	meta="$(get "$url")"

	server="$(echo "$meta" | jq -r ".downloads.server")"
	url="$(echo "$server" | jq -r ".url")"

	echo -e "\e[1;33mDownloading \e[1;35m$file \e[33mfrom: \e[1;37m$url\e[0m"
	if ! download "$url" "$file"; then
		echo -e "\e[1;31mUpdate failed!\e[0m"
		exit 2
	fi
fi

echo "$version.jar" > "$infofile"
exit 0
