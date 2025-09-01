#!/bin/bash


#$1 -> Ping mode (1- latency, 2- loss)
#$2 -> Hostname
PING=$(which ping)
HOST=$2
function latency  {
	# Devuelve un float
	$PING -c 1 -W 1 $HOST | grep 'time=' | awk -F'time=' '{print $2}' | awk '{print $1}'

}


function loss {
	$PING  -c 5 -W 1 $HOST | sed -n 's/.* \([0-9]\+\)% packet loss.*/\1/p'

}


function help {

	echo ""
	echo "		Usage:"
	echo " $0 mode host/ip"
	echo "		Where:"
	echo "	mode: 1 -> icmp"
	echo "	      2 -> loss"
	echo ""

}

if [ "$1" = "" ];then
	help
	exit 1
fi

if [ "$2" = "" ];then
	help
	exit 1
fi

case $1 in
	1)
		latency
		;;
	2)
		loss
		;;
	*)
		help
		;;
esac

