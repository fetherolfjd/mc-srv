#!/usr/bin/env bash

# stop the server if running
# mc_svr_pid=$(ps -ef | grep minecraft-server.jar | grep -v grep | awk -F' ' '{print $2}')
# if [ -n "$mc_svr_pid" ]; then
#   echo "Stopping minecraft server process: $mc_svr_pid"
#   kill "$mc_svr_pid"
# fi

java_installed="true"
jq_installed="true"

echo "Ensuring Java installed..."
java -version
if [ $? -ne 0 ]; then
  java_installed="false"
fi

if [ "$java_installed" = "false" ]; then
  echo "Attemping to install Java..."
  apt-get update
  apt-get upgrade -y
  apt install -y openjdk-17-jre-headless
  echo "Java installed!"
fi
echo "Java checking complete!"

echo "Ensuring jq installed..."
jq --version
if [ $? -ne 0 ]; then
  jq_installed="false"
fi

if [ "$jq_installed" = "false" ]; then
  echo "Attempting to install jq..."
  apt-get update
  apt-get upgrade -y
  apt install -y jq
  echo "jq installed!"
fi
echo "jq checking complete!"

echo "Getting minecraft server version information..."
mc_info_url="https://launchermeta.mojang.com/mc/game/version_manifest.json"

mc_info=$(curl "$mc_info_url")

latest_release_ver=$(echo "$mc_info" | jq -r '.latest.release')

pkg_info_url=""
for info_block in $(echo "$mc_info" | jq -c '.versions[]'); do
  v=$(echo "$info_block" | jq -r '.id')
  if [ "$v" = "$latest_release_ver" ]; then
    pkg_info_url=$(echo "$info_block" | jq -r '.url')
    break
  fi
done

if [ -z "$pkg_info_url" ]; then
  echo "Unable to find package info URL for version $latest_release_ver"
  exit 1
fi

pkg_info=$(curl "$pkg_info_url")
dl_url=$(echo "$pkg_info" | jq -r '.downloads.server.url')

if [ -z "$dl_url" ]; then
  echo "Unable to get server download URL for version $latest_release_ver at url $pkg_info_url"
  exit 1
fi

mc_home="/opt/minecraft"

if [ ! -d "$mc_home" ]; then
  mkdir -p "$mc_home"
fi

cur_ver_dir="${mc_home}/${latest_release_ver}"

if [ -d "$cur_ver_dir" ]; then
  echo "Minecraft version $latest_release_ver already installed"
  exit 1
fi

echo "Found latest version '$latest_release_ver'; installing..."
mkdir -p "$cur_ver_dir"

echo "Downloading minecraft server jar version '$latest_release_ver' to '$cur_ver_dir'..."
curl -kLo "${cur_ver_dir}/minecraft-server.jar" "$dl_url"
echo "Download complete!"

echo "Accepting EULA..."
eula_file="${cur_ver_dir}/eula.txt"
echo "#By changing the setting below to TRUE you are indicating your agreement to our EULA (https://account.mojang.com/documents/minecraft_eula)." >> "$eula_file"
datestring=$(date -u '+%a %b %d %H:%M:%S %Z %Y')
echo "#${datestring}" >> "$eula_file"
echo "eula=true" >> "$eula_file"
echo "EULA accepted."

cur_ver_ln="${mc_home}/current"
echo "Linking '${cur_ver_dir}' to '${cur_ver_ln}'..."
ln -sfn "$cur_ver_dir" "$cur_ver_ln"
echo "'$cur_ver_ln' linked."

echo "Ensuring '$mc_home' is owned by user/group 'minecraft'..."
chown -R minecraft:minecraft "$mc_home"
echo "Ownership done."

echo "Installation of minecraft server version '$latest_release_ver' complete!"
