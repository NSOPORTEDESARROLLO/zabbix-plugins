#!/bin/bash

########################################################################################
# Script Name : asterisk_stats.sh
# Description : Realiza consultas a Asterisk a traves de Asterisk Manager Interface (AMI)
# Author      : Christopher Naranjo Gonzalez
# Email       : cnaranjo@nsoporte.com
# Date        : 2025-09-01
# Version     : 1.0
##########################################################################################


# Datos de conexión
HOST=149.28.55.84
PORT=5038
USER=admin
PASS=1234567890

# Enviar comandos al AMI
(
echo "Action: Login"
echo "Username: $USER"
echo "Secret: $PASS"
echo "Events: off"
echo
sleep 1
echo "Action: Command"
echo
sleep 1
echo "Action: Logoff"
echo
) | nc $HOST $PORT  | grep "Channel:" 


