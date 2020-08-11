#!/bin/bash
# Purpose - Script to add a user to Linux system including passsword
# Author - Vivek Gite <www.cyberciti.biz> under GPL v2.0+
# ------------------------------------------------------------------
# create user
if [ $(id -u) -eq 0 ]; then
	username="zabbix"
	password="zabbix"
	
	egrep "^$username" /etc/passwd >/dev/null
	if [ $? -eq 0 ]; then
		echo "$username exists!"
	else
		pass=$(perl -e 'print crypt($ARGV[0], "password")' $password)
		useradd -m -p "$pass" "$username"
		[ $? -eq 0 ] && echo "User has been added to system!" || echo "Failed to add a user!"
	fi
else
	echo "Only root may add a user to the system."
fi

## SSH

ssh_location="/home/zabbix/.ssh"

if [ ! -d $ssh_location ]; then
    mkdir $ssh_location
    cat /vagrant/*.pub >> /home/zabbix/.ssh/authorized_keys
fi

## PSK 

openssl rand -hex 32 > /home/zabbix/zabbix_agentd.psk

## PSQL

sudo apt-get update
sudo apt-get install -y postgresql postgresql-contrib

sudo -i -u postgres psql -c "ALTER ROLE postgres WITH PASSWORD 'postgres';"

sudo -u postgres createdb zabbix
sudo -u postgres createdb zabbix-proxy

## PHP

sudo apt-get install -y php7.2-dev php7.2-bcmath php7.2-mbstring php7.2-gd php7.2-xml php7.2-ldap php7.2-json php7.2-pgsql

## Zabbix

wget https://repo.zabbix.com/zabbix/5.0/ubuntu/pool/main/z/zabbix-release/zabbix-release_5.0-1+bionic_all.deb
dpkg -i zabbix-release_5.0-1+bionic_all.deb
sudo apt-get update

# server

sudo apt-get install -y zabbix-server-pgsql zabbix-frontend-php zabbix-apache-conf
sudo apt upgrade -y

zcat /usr/share/doc/zabbix-server-pgsql*/create.sql.gz | sudo -u postgres psql zabbix

cp -f /vagrant/server-config/apache.conf /etc/zabbix/apache.conf
cp -f /vagrant/server-config/zabbix_agentd.conf /etc/zabbix/zabbix_agentd.conf
cp -f /vagrant/server-config/zabbix_server.conf /etc/zabbix/zabbix_server.conf

sudo systemctl restart zabbix-server apache2
sudo systemctl enable zabbix-server apache2

# proxy

sudo apt-get install -y zabbix-proxy-pgsql
sudo apt upgrade -y

zcat /usr/share/doc/zabbix-proxy-pgsql/schema.sql.gz | sudo -u postgres psql zabbix-proxy

cp -f /vagrant/server-config/zabbix_proxy.conf /etc/zabbix/zabbix_proxy.conf

sudo systemctl restart zabbix-proxy
sudo systemctl enable zabbix-proxy

# agent

sudo apt-get install -y zabbix-agent
sudo service zabbix-agent start
