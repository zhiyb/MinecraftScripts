# MinecraftScripts
Scripts for managing Minecraft server (Auto backup, etc)

And Minecraft client update & launching script

## Start

> ### FreeBSD
> ```
> pkg install screen jq bash openjdk
> ```

> ### MacOS
> ```
> brew install screen jq
> brew switch screen `brew info --json=v1 screen | jq -r '.[].versions.stable'`
> ```

> ### Debian
> ```
> apt install screen jq net-tools
> ```

```
cp server_template.conf server.conf
./server.sh
```
