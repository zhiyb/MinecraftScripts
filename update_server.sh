#!/bin/bash

# snapshot or release
type=snapshot
manifest=https://launchermeta.mojang.com/mc/game/version_manifest.json

[ -z "$folder" ] && folder=server
[ -z "$infofile" ] && infofile=$folder/latest.txt

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

echo "Fetching manifest..."
manifest="$(get "$manifest")"

version="$(echo "$manifest" | jq -r ".latest.$type")"
info="$(echo "$manifest" | jq -r ".versions[] | select(.id | contains(\"$version\"))")"
time="$(echo "$info" | jq -r ".releaseTime")"
url="$(echo "$info" | jq -r ".url")"
echo "Latest $type: $version ($time)"

file="$folder/$version.jar"
if [ -e "$file" ]; then
	echo -e "File \e[1;32m$file\e[0m already exists"
else
	echo "Fetching version metadata..."
	meta="$(get "$url")"

	server="$(echo "$meta" | jq -r ".downloads.server")"
	url="$(echo "$server" | jq -r ".url")"

	echo -e "Downloading \e[1;32m$file\e[0m from: \e[1;33m$url\e[0m"
	if ! download "$url" "$file"; then
		echo "\e[1;31mUpdate failed!\e[0m"
		exit 1
	fi
fi

echo "$version.jar" > "$infofile"
exit 0
