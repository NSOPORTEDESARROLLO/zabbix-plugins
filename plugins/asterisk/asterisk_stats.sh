#!/bin/bash 

mode=$1
data=$2

TMPFOLDER="/tmp/zabbix_asterisk_stats"
AST="/usr/sbin/asterisk"


function PrintHelp() {
	echo "Usage:"
	echo "		$0 mode data "
	echo "Where:"
	echo "		mode: "
	echo "		data: Operational data like peer or peers"
	echo "Samples:"
	echo "		$0 cron"
	echo "		$0 avgchansip 114,112,115"
	echo "		$0 iax2peer callmyway"
	exit 1
}

function PrintFileStats() {
	# Imprime la salida de varios comandos del CLI en varios archivos
	
	if [ ! -d $TMPFOLDER ];then 
		mkdir -p $TMPFOLDER
	fi

	# core show channels
	$AST -rx "core show channels" > $TMPFOLDER/channels.txt

	# queue show
	$AST -rx "queue show" > $TMPFOLDER/queues.txt
	
	# Genera archivos separados por queue
	QUEUES=$(cat $TMPFOLDER/queues.txt |awk '/^[^ ]+ +has/')
	if [ ! -d "$TMPFOLDER/queues.d" ];then
		mkdir -p $TMPFOLDER/queues.d
	fi
	IFS=$'\n'
	for queue in $QUEUES;do
		queue_name=$(echo $queue |cut -d ' ' -f1)
		#echo $queue_name 
		if [ $queue_name != "default" ];then
			$AST -rx "queue show $queue_name" > $TMPFOLDER/queues.d/$queue_name.txt
		fi
	done 

	# Sip show peers
	$AST -rx "sip show peers" > $TMPFOLDER/sip_peers.txt

	# iax2 show peers
	$AST -rx "iax2 show peers" > $TMPFOLDER/iax2_peers.txt

	# Permisos de lectura
	chmod -R 777 $TMPFOLDER 
}


function GetChanSipStatus() {
	# Obtine el status de un peer
	local ext="$1"
	#local status=$(grep -E "^\s*${ext}(/${ext})?\b" "$TMPFOLDER/sip_peers.txt" | awk '{print $3}')
	local status=$(cat $TMPFOLDER/sip_peers.txt |grep "^${ext}" |awk '{print $(NF-2)}')
	if [ "$status" = "" ];then
		echo "${ext} not found"
	else
		echo $status
	fi
}

function GetChanSipLatency() {
	# Obtiene la latencia de un peer si este se encuentra en estado ok
	local ext=$1
	local status=$(GetChanSipStatus ${ext})
	#echo ${status}
	if [ "$status" = "OK" ];then
		local lat=$(cat $TMPFOLDER/sip_peers.txt |grep "^${ext}" | awk '{print $(NF-1)}' |cut -d '(' -f2)
		echo $lat
	else
		echo "-1"
	fi


}

function GetIax2Status() {
        # Obtine el status de un peer IAX2
        local ext="$1"
        local status=$(cat $TMPFOLDER/iax2_peers.txt |grep "^${ext}" | awk '{print $(NF-2)}' )
        if [ "$status" = "" ];then
                echo "${ext} not found"
        else
            	echo $status
        fi
}

function GetIax2Latency() {
        # Obtiene la latencia de un peer si este se encuentra en estado ok
        local ext=$1
        local status=$(GetIax2Status ${ext})
	if [ "$status" = "OK" ];then
                local lat=$($TMPFOLDER/iax2_peers.txt |grep "^${ext}" | awk '{print $(NF-1)}' |cut -d '(' -f2)
                echo $lat
        else
                echo "-1"
        fi

}

function GetActiveChannels() {
	# Obtiene el numero de canales activos
	if [ -f "$TMPFOLDER/channels.txt" ];then
		cat $TMPFOLDER/channels.txt |grep "active calls" |awk '{print $1}'
	else
		echo -n "Error"
	fi
}


function GetQueueCalls() {
	# Obtiene las llamadas en espera  de la Cola
	local queue=$1
	if [ -f "$TMPFOLDER/queues.d/$queue.txt" ];then
		cat $TMPFOLDER/queues.d/$queue.txt |head -1 |awk '{print $3}'
	else 
		echo "-1"
	fi
}

function AverageChanSip() {
	# Recibe varios sip peers separados por coma y revisa el estado
	local peers=$1
	local checker=1
	IFS=$','
	for peer in ${peers};do
		local status=$(GetChanSipLatency ${peer})
		if [ $status = -1 ];then
			checker=-1
			break
		fi
	done
	echo "$checker"
}

function AverageIax2() {
        # Recibe varios IAX2 peers separados por coma y revisa el estado
        local peers=$1
        local checker=1
        IFS=$','
        for peer in ${peers};do
                local status=$(GetIax2Latency ${peer})
                if [ $status = -1 ];then
                        checker=-1
                        break
                fi
        done
        echo "$checker"
}

if [ "$mode" = "" ];then PrintHelp;fi
case $mode in
	cron)	 
		PrintFileStats
	;;
	queuecalls)
		if [ "$data" != "" ];then GetQueueCalls $data;else PrintHelp;fi
	;;
	chansippeer)
		if [ "$data" != "" ];then GetChanSipLatency $data;else PrintHelp;fi
	;;		
	iax2peer)
		if [ "$data" != "" ];then GetIax2Latency $data;else PrintHelp;fi
	;;
	corechannels)
		GetActiveChannels
	;;
	avgchansip)
		if [ "$data" != "" ];then AverageChanSip $data;else PrintHelp;fi
	;;
	avgiax2)
                if [ "$data" != "" ];then AverageIax2 $data;else PrintHelp;fi
        ;;
	*)
		PrintHelp
	;;
esac

