#!/usr/bin/env bash

mc_home="/opt/minecraft"
jar_name="minecraft-server.jar"

# stop the server if running
mc_svr_pid=$(ps -ef | grep minecraft-server.jar | grep -v grep | awk -F' ' '{print $2}')
if [ -n "$mc_svr_pid" ]; then
  echo "Stopping minecraft server process: $mc_svr_pid"
  kill "$mc_svr_pid"
  killed="false"
  while [ "$killed" = "false" ]; do
    killed_pid=$(ps -ef | grep minecraft-server.jar | grep -v grep | awk -F' ' '{print $2}')
    if [ -z "$killed_pid" ]; then
      echo "Minecraft process '$mc_svr_pid' has been killed."
      killed="true"
    fi
  done
fi

pushd "${mc_home}/current"
java -Xms1G -Xmx1G -jar "$jar_name" --nogui &
