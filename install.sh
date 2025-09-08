#!/bin/bash

###########################################################
# Script Name : install.sh
# Description : Nsoporte Zabbix installer scripts
# Author      : Christopher Naranjo Gonzalez
# Email       : cnaranjo@nsoporte.com
# Date        : 2025-09-05
# Version     : 1.0
###########################################################

# Create directories if they do not exist
if [ ! -d "/usr/local/lib/zabbix/nsoporte" ]; then
    mkdir -p /usr/local/lib/zabbix/nsoporte
fi

if [ ! -d "/etc/zabbix/zabbix_agent2.d" ]; then
    mkdir -p /etc/zabbix/zabbix_agent2.d
fi

# Copy the plugins to the appropriate directory
for plugin in $(find plugins/ -type f); do
    cp -f "$plugin" /usr/local/lib/zabbix/nsoporte/    
done
# Set execute permissions on the copied scripts
chmod +x /usr/local/lib/zabbix/nsoporte/*

# Copy zabbix configuration files
for config in $(find zabbix_config/ -type f); do
    cp -f "$config" /etc/zabbix/zabbix_agent2.d/
done

# chnod permissions for zabbix configuration files
chown -R zabbix:zabbix /etc/zabbix/zabbix_agentd.d/*

# Restart Zabbix Agent service to apply changes
systemctl enable zabbix-agent2
systemctl restart zabbix-agent2
