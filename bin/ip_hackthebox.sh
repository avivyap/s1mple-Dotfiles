#!/bin/bash

ip=$(ip a | grep tun | grep inet | awk '{print $2}' | tr '/' ' ' | awk '{print $1}')


if [ -n "$ip" ];then

	echo "%{F#9FEF00}󰆧 %{F#FFFFFF}$ip"

else

	echo "%{F#9FEF00}󰆧 %{F#FFFFFF}Disconnected"


fi
