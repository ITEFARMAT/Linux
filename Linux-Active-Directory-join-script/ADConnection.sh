!/bin/sh

#$1 = User DomainAdmin Name provided while domain adding                                        #line 79
#$2 = Provide Group from Active Directory -    #line 100
#$3 = Provide Password for service account required to bind & fetch sshKey                      #line 105
#Root login disabled                                                                            #line 171
#$4 = Provide group from to AD permitted SUDO loggin without password                           #line 137


if [ "$1" != "" ]; then
    echo 
else
    echo "User DomainAdmin Name are missing !"
    exit
fi
if [ "$2" != "" ]; then
    echo 
else
    echo "Group from ActiveDirectory missing !"
    exit
fi

if [ "$3" != "" ]; then
    echo 
else
    echo "Service account LDAP reader password missing !"
    exit
fi

if [ "$4" != "" ]; then
    echo 
else
    echo "Group permitted for SUDO logins missing !"
    exit
fi

yum install sssd realmd oddjob ntpdate oddjob-mkhomedir adcli ntp samba-common samba-common-tools krb5-workstation openldap-clients policycoreutils-python -y || exit 1
yum install wget -y || exit 2
cp /etc/resolv.conf /etc/resolv.conf.backup || exit 3
echo -n > /etc/resolv.conf || exit 4
echo "search #please provide domain name 
nameserver #please provide domain contoller IP" >> /etc/resolv.conf || exit 5
systemctl enable ntpd || exit 6
cp /etc/ntp.conf /etc/ntp.conf.backup || exit 7 
echo -n > /etc/ntp.conf || exit 8
echo "# For more information about this file, see the man pages
# ntp.conf(5), ntp_acc(5), ntp_auth(5), ntp_clock(5), ntp_misc(5), ntp_mon(5).

driftfile /var/lib/ntp/drift

# Permit time synchronization with our time source, but do not
# permit the source to query or modify the service on this system.
restrict default nomodify notrap nopeer noquery

# Permit all access over the loopback interface.  This could
# be tightened as well, but to do so would effect some of
# the administrative functions.
restrict 127.0.0.1 
restrict ::1

# Hosts on local network are less restricted.
#restrict 192.168.1.0 mask 255.255.255.0 nomodify notrap

# Use public servers from the pool.ntp.org project.
# Please consider joining the pool (http://www.pool.ntp.org/join.html).
server 10.1.1.4
server AD-DC.ad.br-ag.eu
server 0.centos.pool.ntp.org iburst
server 1.centos.pool.ntp.org iburst
server 2.centos.pool.ntp.org iburst
server 3.centos.pool.ntp.org iburst

#broadcast 192.168.1.255 autokey        # broadcast server
#broadcastclient                        # broadcast client
#broadcast 224.0.1.1 autokey            # multicast server
#multicastclient 224.0.1.1              # multicast client
#manycastserver 239.255.254.254         # manycast server
#manycastclient 239.255.254.254 autokey # manycast client

# Enable public key cryptography.
#crypto

includefile /etc/ntp/crypto/pw

# Key file containing the keys and key identifiers used when operating
# with symmetric key cryptography. 
keys /etc/ntp/keys

# Specify the key identifiers which are trusted.
#trustedkey 4 8 42

# Specify the key identifier to use with the ntpdc utility.
#requestkey 8

# Specify the key identifier to use with the ntpq utility.
#controlkey 8

# Enable writing of statistics records.
#statistics clockstats cryptostats loopstats peerstats

# Disable the monitoring facility to prevent amplification attacks using ntpdc
# monlist command when default restrict does not include the noquery flag. See
# CVE-2013-5211 for more details.
# Note: Monitoring will not be disabled with the limited restriction flag.
disable monitor" >> /etc/ntp.conf || exit 9

ntpdate -u #provide your domain controller FULLNAME || exit 10
systemctl enable ntpd || exit 11
systemctl restart ntpd || exit 12
realm join --user=$1 #DomainName
cp /etc/sssd/sssd.conf /etc/sssd/sssd.conf.backup || exit 13
echo -n > /etc/sssd/sssd.conf || exit 14
echo "[sssd] 
domains = #domainname 
config_file_version = 2
services = nss, pam 
default_domain_suffix = #FULLDOMAINNAME

[domain/#domain] 
ad_domain = domain 
krb5_realm = #FULL DOMAIN
realmd_tags = manages-system joined-with-samba 
cache_credentials = True 
id_provider = ad 
krb5_store_password_if_offline = True  
default_shell = /bin/bash 
ldap_id_mapping = True  
use_fully_qualified_names = True 
fallback_homedir = /home/%u@%d
access_provider = ad
ad_access_filter = memberOf=CN=$2,OU=,DC=,DC=,DC=" >> /etc/sssd/sssd.conf || exit 13 # Dodajemy CN odpowiedniej grupy z AD
systemctl restart sssd || exit 15
systemctl daemon-reload || exit 16
touch /usr/local/bin/fetch_ssh_key || exit 17
echo "#!/bin/sh" >> /usr/local/bin/fetch_ssh_key || exit 18
echo "ldapsearch -h #domainname -xb \"DC=,DC=,DC=\" '(sAMAccountName='\"\${1%@*}\"')' -D ssh_reader -w $3 'sshPublicKey' | sed -n '/^ /{H;d};/sshPublicKey:/x;\$g;s/\n *//g;s/sshPublicKey: //gp'" >> /usr/local/bin/fetch_ssh_key || exit  19
chmod 500 /usr/local/bin/fetch_ssh_key || exit 20
cp /etc/ssh/sshd_config /etc/ssh/sshd_config.backup || exit 21
echo -n > /etc/ssh/sshd_config || exit 22
echo "# \$OpenBSD: sshd_config,v 1.100 2016/08/15 12:32:04 naddy Exp $

# This is the sshd server system-wide configuration file.  See
# sshd_config(5) for more information.

# This sshd was compiled with PATH=/usr/local/bin:/usr/bin

# The strategy used for options in the default sshd_config shipped with
# OpenSSH is to specify options with their default value where
# possible, but leave them commented.  Uncommented options override the
# default value.

# If you want to change the port on a SELinux system, you have to tell
# SELinux about this change.
# semanage port -a -t ssh_port_t -p tcp #PORTNUMBER
#
Port 22
#AddressFamily any
#ListenAddress 0.0.0.0
#ListenAddress ::

HostKey /etc/ssh/ssh_host_rsa_key
#HostKey /etc/ssh/ssh_host_dsa_key
HostKey /etc/ssh/ssh_host_ecdsa_key
HostKey /etc/ssh/ssh_host_ed25519_key

# Ciphers and keying
#RekeyLimit default none

# Logging
#SyslogFacility AUTH
SyslogFacility AUTHPRIV
#LogLevel INFO

# Authentication:

#LoginGraceTime 2m
PermitRootLogin no
#StrictModes yes
#MaxAuthTries 6
#MaxSessions 10

PubkeyAuthentication yes

# The default is to check both .ssh/authorized_keys and .ssh/authorized_keys2
# but this is overridden so installations will only check .ssh/authorized_keys
AuthorizedKeysFile      .ssh/authorized_keys

#AuthorizedPrincipalsFile none

AuthorizedKeysCommand /usr/local/bin/fetch_ssh_key
AuthorizedKeysCommandUser root

# For this to work you will also need host keys in /etc/ssh/ssh_known_hosts
#HostbasedAuthentication no
# Change to yes if you don't trust ~/.ssh/known_hosts for
# HostbasedAuthentication
#IgnoreUserKnownHosts no
# Don't read the user's ~/.rhosts and ~/.shosts files
#IgnoreRhosts yes

# To disable tunneled clear text passwords, change to no here!
#PasswordAuthentication yes
#PermitEmptyPasswords no
PasswordAuthentication no

# Change to no to disable s/key passwords
#ChallengeResponseAuthentication yes
ChallengeResponseAuthentication no

# Kerberos options
#KerberosAuthentication no
#KerberosOrLocalPasswd yes
#KerberosTicketCleanup yes
#KerberosGetAFSToken no
#KerberosUseKuserok yes

# GSSAPI options
GSSAPIAuthentication yes
GSSAPICleanupCredentials no
#GSSAPIStrictAcceptorCheck yes
#GSSAPIKeyExchange no
#GSSAPIEnablek5users no

# Set this to 'yes' to enable PAM authentication, account processing,
# and session processing. If this is enabled, PAM authentication will
# be allowed through the ChallengeResponseAuthentication and
# PasswordAuthentication.  Depending on your PAM configuration,
# PAM authentication via ChallengeResponseAuthentication may bypass
# the setting of \"PermitRootLogin without-password\".
# If you just want the PAM account and session checks to run without
# PAM authentication, then enable this but set PasswordAuthentication
# and ChallengeResponseAuthentication to 'no'.
# WARNING: 'UsePAM no' is not supported in Red Hat Enterprise Linux and may cause several
# problems.
UsePAM yes

#AllowAgentForwarding yes
#AllowTcpForwarding yes
#GatewayPorts no
X11Forwarding yes
#X11DisplayOffset 10
#X11UseLocalhost yes
#PermitTTY yes
#PrintMotd yes
#PrintLastLog yes
#TCPKeepAlive yes
#UseLogin no
#UsePrivilegeSeparation sandbox
#PermitUserEnvironment no
#Compression delayed
#ClientAliveInterval 0
#ClientAliveCountMax 3
#ShowPatchLevel no
#UseDNS yes
#PidFile /var/run/sshd.pid
#MaxStartups 10:30:100
#PermitTunnel no
#ChrootDirectory none
#VersionAddendum none

# no default banner path
#Banner none

# Accept locale-related environment variables
AcceptEnv LANG LC_CTYPE LC_NUMERIC LC_TIME LC_COLLATE LC_MONETARY LC_MESSAGES
AcceptEnv LC_PAPER LC_NAME LC_ADDRESS LC_TELEPHONE LC_MEASUREMENT
AcceptEnv LC_IDENTIFICATION LC_ALL LANGUAGE
AcceptEnv XMODIFIERS

# override default of no subsystems
Subsystem       sftp    /usr/libexec/openssh/sftp-server

# Example of overriding settings on a per-user basis
#Match User anoncvs
#       X11Forwarding no
#       AllowTcpForwarding no
#       PermitTTY no
#       ForceCommand cvs server" >> /etc/ssh/sshd_config || exit 23
systemctl restart sssd sshd || exit 24
setenforce 0 || exit 25
wget https://github.com/patrikwm/Centos-SSH-Active-Directory/raw/master/my-ldapsearch.pp || exit 226
wget https://github.com/patrikwm/Centos-SSH-Active-Directory/raw/master/my-sssd.pp || exit 27
semodule -i my-sssd.pp || exit 28
semodule -i my-ldapsearch.pp || exit 29
setenforce 1 || exit 30
touch /etc/sudoers.d/sudoers || exit 31
echo "
%$4    ALL = NOPASSWD:       ALL" >> /etc/sudoers.d/sudoers || exit 32