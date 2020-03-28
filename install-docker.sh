#!/bin/bash

# install docker
sudo yum install -y yum-utils device-mapper-persistent-data lvm2 -y
sudo yum-config-manager --add-repo https://download.docker.com/linux/centos/docker-ce.repo
sudo yum install docker-ce -y 
sudo usermod -aG docker $(whoami)
sudo systemctl enable docker.service
sudo systemctl start docker.service
docker --version
sudo yum install epel-release -y
sudo yum install -y python-pip
sudo pip install docker-compose 
sudo yum upgrade python* -y
docker-compose version