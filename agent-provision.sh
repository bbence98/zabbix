#! /bin/bash

# Agent 
cd /var/cache/apt/archives
file="zabbix-release_5.0-1+bionic_all.deb"

if ! [[ -f $file ]];then
    wget https://repo.zabbix.com/zabbix/5.0/ubuntu/pool/main/z/zabbix-release/$file
    dpkg -i $file
    sudo apt-get update

    sudo apt-get install -y zabbix-agent
    sudo apt upgrade -y

    sudo service zabbix-agent start

    ## PSK 

    openssl rand -hex 32 > /home/vagrant/zabbix_agentd.psk
fi

cp -f /vagrant/agent-config/zabbix_agentd.conf /etc/zabbix/zabbix_agentd.conf
