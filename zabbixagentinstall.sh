#!/bin/bash
rpm -Uvh https://repo.zabbix.com/zabbix/4.4/rhel/7/x86_64/zabbix-release-4.4-1.el7.noarch.rpm
yum install apt-get update -y
yum install zabbix-agent -y
