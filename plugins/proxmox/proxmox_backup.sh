#!/bin/bash

###########################################################
# Script Name : proxmox_backup.sh
# Description : Proxmox Backup Monitor for Zabbix
# Author      : Christopher Naranjo Gonzalez
# Email       : cnaranjo@nsoporte.com
# Date        : 2025-09-05
# Version     : 1.0
###########################################################


#Listamos los logs de vzdump
LOGS=$(ls -1t /var/log/vzdump/*.log)
ERROR=0
ENDEDJOB=1
STATUS=$1
ZSERVER=192.168.0.30
ZPORT=10051

ZABBIX_AGENT_CONFIG="/etc/zabbix/zabbix_agent2.conf"
HOSTNAME=$(cat $ZABBIX_AGENT_CONFIG |grep ^"Hostname" |cut -d '=' -f 2 |sed 's/^[ \t]*//;s/[ \t]*$//')
PSK_IDENTITY=$(cat $ZABBIX_AGENT_CONFIG |grep ^"TLSPSKIdentity" |cut -d '=' -f 2 |sed 's/^[ \t]*//;s/[ \t]*$//')
PSK_FILE=$(cat $ZABBIX_AGENT_CONFIG |grep ^"TLSPSKFile" |cut -d '=' -f 2 |sed 's/^[ \t]*//;s/[ \t]*$//')
ZKEY="nsoporte.pve.backups"

PHASE="$1"
VZID="$2"
ZSENDER=$(which zabbix_sender)




if [ "$STATUS" = "" ];then
	echo "Error"
	exit 1
fi

function send_zabbix(){
	local msg=$1
	$ZSENDER -z $ZSERVER -p $ZPORT -s $HOSTNAME --tls-connect psk --tls-psk-identity $PSK_IDENTITY --tls-psk-file $PSK_FILE -k $ZKEY -o "$msg" >>/dev/null

}



function check_logs(){
	IFS=$'\n'
	for log in $LOGS;do
		#echo $log
		error=$(cat $log |grep "ERROR" |wc -l)
		if [ "$error" != "0" ];then
			ERROR=1
			break
		fi

	done
}

function check_ended_jobs() {
	IFS=$'\n'
        for log in $LOGS;do
		ended_job=$(cat $log |grep "Finished Backup" |wc -l)
		if [ "$ended_job" = "0" ];then
			ENDEDJOB=0
			break
		fi
	done

}


case $STATUS in
	"job-end")
		# Revisa errores
		check_logs
		echo "Zabbix Info:"
		echo "ERROR: $ERROR"
		if [ "$ERROR" = "0" ];then
			# Revisa si los trabajos se terminaron
			check_ended_jobs
			echo "ENDEDJOB: $ENDEDJOB"
			if [ "$ENDEDJOB" = "1" ];then
				send_zabbix 1
			fi
		else
				send_zabbix 0
		fi
	;;
	"job-abort")
		echo "Se aborta un trabajo"
	;;
	*)
		echo "Aca no hacemos nada aun"
	;;
esac
