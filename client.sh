#!/bin/bash

# Argument:
# list	| Fetch version list from official server

# File folders
folder=minecraft

# http://wiki.vg/Authentication
authserv=https://authserver.mojang.com
authurl="$authserv/authenticate"
refreshurl="$authserv/refresh"

# http://wiki.vg/Game_files
# Manifest JSON file URL
manifesturl=https://launchermeta.mojang.com/mc/game/version_manifest.json
# Assets resource URL
assetsurl=http://resources.download.minecraft.net

red="\e[1;31m"
green="\e[1;32m"
yellow="\e[1;33m"
blue="\e[1;34m"
white="\e[1;37m"
default="\e[0m"

get()
{
	curl -s $@
}

download()
{
	curl --progress-bar -o "$2" -L "$1"
	#aria2c --daemon=false --enable-rpc=false -c -o "$2" "$1"
}

auth()
{
	url="$1"
	shift
	get "$url" -H "Content-Type: application/json" -d $@
}

authenticate()
{
	echo -ne "Username: $white$auth_username"
	[ -z "$auth_username" ] && read auth_username || echo
	echo -ne "${default}Password: "
	[ -z "$auth_password" ] && read -s auth_password || echo
	echo -e "${default}Logging in..."
	info="$(auth "$authurl" "{\"agent\":{\"name\":\"Minecraft\",\"version\":1},\"username\":\"$auth_username\",\"password\":\"$auth_password\"}")"
	err="$(echo "$info" | $jq -r ".errorMessage")"
	[ "$err" == "null" ] && err="$(echo "$info" | $jq -r ".error")"
	if [ "$err" != "null" ]; then
		echo -e "${red}Error: $err ${default}" >&2
		unset auth_username auth_password
		return 1
	fi

	auth_player_name="$(echo "$info" | jq -r ".selectedProfile.name")"
	auth_uuid="$(echo "$info" | jq -r ".selectedProfile.id")"
	auth_access_token="$(echo "$info" | jq -r ".accessToken")"
	client_token="$(echo "$info" | jq -r ".clientToken")"
	legacy="$(echo "$info" | jq -r ".selectedProfile.legacy")"
	user_type=mojang
	[ "$legacy" == true ] && user_type=legacy
	echo "$info" > launcher.json
	return 0
}

checkFile()
{
	([ "$skipcheck" == true ] || [ -z "$sha1" ]) && [ -e "$file" ] && return
	[ -e "$file" ] && [ "$(sha1sum -b "$file" | awk '{print $1}')" == "$sha1" ]
}

updateFile()
{
	checkFile && return 0
	echo -e "Downloading: $blue$url$default"
	mkdir -p "$(dirname "$file")"
	download "$url" "$file"
	checkFile
}

updateJar()
{
	echo "Checking client..."
	file="versions/$version/$version.jar"
	jar[${#jar[@]}]="$file"
	sha1="$(echo "$meta" | $jq -r ".downloads.client.sha1")"
	url="$(echo "$meta" | $jq -r ".downloads.client.url")"
	updateFile
}

updateLibrary()
{
	name="$(echo "$libmeta" | $jq -r ".name")"
	libmeta="$(eval echo "\"$(echo "$libmeta" | sed 's/\"/\\\"/g')\"" | $jq -r "
		if (has(\"rules\")) then
			if ((.rules[]? | select(.os?.name? // empty | . == \"$os\").action) //
			(.rules[]? | select(has(\"os\") | not).action) // \"disallow\") == \"disallow\" then
				empty
			else
				if (has(\"natives\")) then
					.natives.$os as \$os |
					.downloads.classifiers | .[\$os]
				else
					.downloads.artifact
				end
			end
		else
			if (has(\"natives\")) then
				.natives.$os as \$os |
				.downloads.classifiers | .[\$os]
			else
				.downloads.artifact
			end
		end")"
	[ -z "$libmeta" ] && return 0
	[ "$libmeta" == null ] && echo "$@" && read -s

	file="libraries/$(echo "$libmeta" | $jq -r ".path")"
	jar[${#jar[@]}]="$file"
	sha1="$(echo "$libmeta" | $jq -r ".sha1")"
	url="$(echo "$libmeta" | $jq -r ".url")"
	updateFile
}

updateLibraries()
{
	echo "Checking libraries..."
	count="$(echo "$meta" | $jq -r ".libraries | length")"
	for ((i = 0; i != $count; i++)); do
		libmeta="$(echo "$meta" | $jq -r ".libraries[$i]")"
		updateLibrary "$libmeta" || return 1
	done
}

updateAssets()
{
	[ -z "$meta" ] && echo -e "${red}Empty metadata${default}" >&2 && return 1

	echo "Checking assets..."
	assets="$(echo "$meta" | $jq -r ".assets")"
	file="assets/indexes/$assets.json"
	[ -e "$file" ] && [ "$skipcheck" == true ] && return 0
	sha1="$(echo "$meta" | $jq -r ".assetIndex.sha1")"
	url="$(echo "$meta" | $jq -r ".assetIndex.url")"
	updateFile || (echo -e "${red}Failed to fetch assets metadata${default}" >&2 && return 1)

	unset sha1
	assetsmeta="$(<"$file")"
	hashlist=($(echo "$assetsmeta" | $jq -r ".objects[].hash" | grep -o "[[:print:][:space:]]*"))
	for ((i = 0; i != ${#hashlist[@]}; i++)); do
		hash="${hashlist[$i]}"
		file="assets/objects/${hash:0:2}/$hash"
		url="$assetsurl/${hash:0:2}/$hash"
		updateFile
	done
}

load()
{
	[ ! -e "versions/$version/$version.json" ] && (updateVersionMetadata || return 1)
	[ -z "$meta" ] && meta="$(<"versions/$version/$version.json")"
	[ -z "$meta" ] && echo -e "${red}Empty metadata${default}" >&2 && return 1
	type="$(echo "$meta" | $jq -r ".type")"
	release="$(echo "$meta" | $jq -r ".releaseTime")"

	echo -e "Loading version $green$version$default ($yellow$type, $release$default)..."
	updateLibraries || return 1
	updateAssets || return 1
	updateJar || return 1
}

updateVersionMetadata()
{
	echo -e "Updating version $green$version$default..."
	[ -z "$manifest" ] && manifest="$(get "$manifesturl")"

	info="$(echo "$manifest" | $jq -r ".versions[] | select(.id == \"$version\")")"
	type="$(echo "$info" | $jq -r ".type")"
	release="$(echo "$info" | $jq -r ".releaseTime")"
	url="$(echo "$info" | $jq -r ".url")"
	[ -z "$url" ] && echo -e "${red}Failed to extract metadata URL${default}" >&2 && return 1

	echo -e "Fetching version $green$version$default metadata..."
	meta="$(get "$url")"
	[ -z "$meta" ] && echo -e "${red}Failed to fetch metadata${default}" >&2 && return 1
	mkdir -p "versions/$version"
	echo "$meta" > "versions/$version/$version.json"
}

update()
{
	echo -e "Updating to latest $green$version$default..."
	manifest="$(get "$manifesturl")"
	version="$(echo "$manifest" | $jq -r ".latest.$version")"
	[ -z "$version" ] && echo -e "${red}Failed to extract version information${default}" >&2 && return 1
	return 0
}

run()
{
	[ -z "$meta" ] && echo -e "${red}Empty metadata${default}" >&2 && return 1
	[ -z "$type" ] && type="$(echo "$meta" | $jq -r ".type")"
	[ -z "$assets" ] && assets="$(echo "$meta" | $jq -r ".assets")"
	[ -z "$version" ] && version="$(echo "$meta" | $jq -r ".id")"

	((${#jar[@]} < 1)) && echo -e "${red}Empty jar file list${default}" >&2 && return 1
	if [ "$os" == windows ]; then
		sep=";"
	else
		sep=":"
	fi
	jars="${jar[0]}"
	for ((i = 1; i != ${#jar[@]}; i++)); do
		jars="$jars$sep${jar[$i]}"
	done

	class="$(echo "$meta" | $jq -r ".mainClass")"
	version_name="$version"
	game_directory=.
	assets_root=assets
	game_assets=assets
	assets_index_name="$assets"
	version_type="$type"
	args="$(eval echo "$(echo "$meta" | $jq -r ".minecraftArguments")")"

	mkdir -p natives
	echo -e "Launching Minecraft $green$version$default..."
	$java -Djava.library.path=natives -cp $jars $class $args
}

listVersions()
{
	echo -e "Fetching version list..."
	manifest="$(get "$manifesturl")"
	echo "$manifest" | $jq -r ".versions[] | .id + \" (\" + .type + \")\""
}

unalias grep 2> /dev/null
unset manifest meta
unset jar
declare -a jar hashlist
cd "$(dirname "$0")"

if [ "$1" == list ]; then
	listVersions
	exit
fi

# Load configurations
[ ! -e "config.conf" ] && echo "config.conf not found!" && read -s && exit 1
. config.conf

mkdir -p "$folder"
cd "$folder"

# Refresh / Login
if [ "$auth" == true ]; then
	refresh || until authenticate; do :; done
fi

if [ "$version" == "snapshot" ] || [ "$version" == "release" ]; then
	update || (read -s && exit 1)
fi
load || (read -s && exit 1)
run || (echo -e "${red}Fatal error${default}" >&2 && exit 1)
exit
