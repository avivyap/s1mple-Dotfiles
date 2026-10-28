#!/usr/bin/bash

ip=$(ip a | grep 192 | awk '{print $2}' | tr '/' ' ' | awk '{print $1}')

if [ -n "$ip" ];then

	echo "%{F#2495e7}󰈀 %{F#FFFFFF}$ip"
else

	echo "%{F#2495e7}󰈀 %{F#FFFFFF}Disconnected"

fi


