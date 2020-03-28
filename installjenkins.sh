#!/bin/bash
sudo yum install java-1.8.0-openjdk-devel -y || exit 1
curl --silent --location http://pkg.jenkins-ci.org/redhat-stable/jenkins.repo | sudo tee /etc/yum.repos.d/jenkins.repo || exit 2
sudo rpm --import https://jenkins-ci.org/redhat/jenkins-ci.org.key || exit 3
sudo yum install jenkins -y || exit 4
sudo systemctl start jenkins || exit 5
systemctl status jenkins || exit 6
sudo systemctl enable jenkins || exit 7
sudo firewall-cmd --permanent --zone=public --add-port=8080/tcp || exit 8
sudo firewall-cmd --reload || exit 9
sudo yum install maven -y || exit 10
sudo touch /etc/yum.repos.d/wandisco-git.repo || exit 11
echo >> "[wandisco-git]
name=Wandisco GIT Repository
baseurl=http://opensource.wandisco.com/centos/7/git/\$basearch/
enabled=1
gpgcheck=1
gpgkey=http://opensource.wandisco.com/RPM-GPG-KEY-WANdisco" >> /etc/yum.repos.d/wandisco-git.repo || exit 12
sudo rpm --import http://opensource.wandisco.com/RPM-GPG-KEY-WANdisco || exit 13
sudo yum install git -y || exit 14