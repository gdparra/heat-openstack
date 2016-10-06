#!/bin/bash

sudo apt-get update
sudo apt-get install -y git python-pip vim
sudo apt-get upgrade -y python


touch host
sudo sed -e "s/[ 	]*127.0.0.1[ 	]*localhost[ 	]*$/127.0.0.1 localhost $HOSTNAME/" /etc/hosts > host
sudo cp -f host /etc/hosts
sudo su -c "useradd stack -s /bin/bash -m -g cc -G cc"
sudo sed -i '$a stack ALL=(ALL) NOPASSWD: ALL' /etc/sudoers
chown stack:stack /home/stack 
cd /home/stack



git clone https://github.com/openstack-dev/devstack.git -b stable/liberty

cd devstack


$HOST_IP=$(/sbin/ifconfig eth0 | grep 'inet addr' | cut -d: -f2 | awk '{print $1}')

#VAR=$(ip addr | grep 'state UP' -A2 | tail -n1 | awk '{print $2}' | cut -f1  -d'/')

#printf '\nHOST_IP=%s'$VAR'\n' >> local.conf
#printf '	address '$VAR'\n'>> interface

#git clone https://github.com/BAbrandon/ScriptsForHeat.git
touch interface
cat <<EOF | cat > interface
auto eth0
iface eth0 inet static
        address $HOST_IP 
		netmask 255.255.255.0
		gateway 192.168.0.1
EOF

sudo cp -f interface /etc/network/interfaces
sudo ifdown eth0
sudo ifup eth0

cat <<EOF | cat > local.conf
[[local|localrc]]
#credential
SERVICE_TOKEN=secret
ADMIN_PASSWORD=secret
MYSQL_PASSWORD=secret
RABBIT_PASSWORD=secret
SERVICE_PASSWORD=secret
#network
FLAT_INTERFACE=eth0
FIXED_RANGE=192.168.1.0/24
NETWORK_GATEWAY=192.168.1.1
FIXED_NETWORK_SIZE=4096
HOST_IP=$HOST_IP
PUBLIC_NETWORK_GATEWAY=192.168.0.1
#multi_host
MULTI_HOST=1
# Enable Logging
LOGFILE=/opt/stack/logs/stack.sh.log
VERBOSE=True
LOG_COLOR=True
SCREEN_LOGDIR=/opt/stack/logs
#service
disable_service n-net
enable_service q-svc
enable_service q-agt
enable_service q-dhcp
enable_service q-l3
enable_service q-meta
enable_service neutron
enable_service q-fwaas
enable_service q-vpn
enable_service q-lbaas
Q_PLUGIN=ml2
Q_ML2_TENANT_NETWORK_TYPE=vxlan
EOF





touch sysctl.conf
sudo sed -e "s/as needed.$/as needed.\n net.ipv4.ip_forward=1\n/" /etc/sysctl.conf >  sysctl.conf

sudo sed -e "s/as needed.$/as needed.\n net.ipv4.conf.default.rp.filter=0\n/" sysctl.conf > sysctl.conf

sudo sed -e "s/as needed.$/as needed.\n net.ipv4.conf.all.rp.filter=0\n/" sysctl.conf > sysctl.conf

sudo cp sysctl.conf /etc/sysctl.conf

sudo iptables -t nat -A POSTROUTING -o eth0 -j MASQUERADE

cat <<EOF | cat > local.sh
for i in `seq 2 10`; do /opt/stack/nova/bin/nova-manage fixed reserve 192.168.1.$i; done
EOF

./stack.sh
