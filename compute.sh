#!/bin/bash

sudo apt-get update
sudo apt-get install -y git python-pip vim
sudo apt-get upgrade -y python


touch host
sudo sed -e "s/[        ]*127.0.0.1[    ]*localhost[    ]*$/127.0.0.1 localhost $HOSTNAME/" /etc/hosts > host
sudo cp -f host /etc/hosts

chown stack:stack /home/stack
cd /home/stack



git clone https://github.com/openstack-dev/devstack.git -b stable/liberty

cd devstack

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
HOST_IP=192.168.0.137
PUBLIC_NETWORK_GATEWAY=192.168.0.1
#multi_host
MULTI_HOST=1
SERVICE_HOST=192.168.0.134
DATABASE_TYPE=mysql
MYSQL_HOST=$SERVICE_HOST
RABBIT_HOST=$SERVICE_HOST
GLANCE_HOSTPORT=$SERVICE_HOST:9292
Q_HOST=$SERVICE_HOST
KEYSTONE_AUTH_HOST=$SERVICE_HOST
KEYSTONE_SERVICE_HOST=$SERVICE_HOST
CINDER_SERVICE_HOST=$SERVICE_HOST
NOVA_VNC_ENABLED=True
NOVNCPROXY_URL="http://$SERVICE_HOST:6080/vnc_auto.html"
VNCSERVER_LISTEN=$HOST_IP
VNCSERVER_PROXYCLIENT_ADDRESS=$VNCSERVER_LISTEN
#service
ENABLED_SERVICES=n-cpu,n-api,n-api-meta,neutron,q-agt,q-meta
Q_PLUGIN=ml2
Q_ML2_TENANT_NETWORK_TYPE=vxlan
# Enable Logging
LOGFILE=/opt/stack/logs/stack.sh.log
VERBOSE=True
LOG_COLOR=True
SCREEN_LOGDIR=/opt/stack/logs
EOF

VAR=$(ip addr | grep 'state UP' -A2 | tail -n1 | awk '{print $2}' | cut -f1  -d'/')

printf '\nHOST_IP=%s'$VAR'\n' >> local.conf

touch interfaces
cat <<EOF | cat > interfaces
auto eth0
iface eth0 inet static
        address 192.168.0.137 
        netmask 255.255.255.0
        gateway 192.168.0.1
EOF

sudo cp -f interfaces /etc/network/
sudo ifdown eth0
sudo ifup eth0


touch sysctl.conf
sudo sed -e "s/as needed.$/as needed.\n net.ipv4.ip_forward=1\n/" /etc/sysctl.conf >  sysctl.conf

sudo sed -e "s/as needed.$/as needed.\n net.ipv4.conf.default.rp.filter=0\n/" sysctl.conf > sysctl.conf

sudo sed -e "s/as needed.$/as needed.\n net.ipv4.conf.all.rp.filter=0\n/" sysctl.conf > sysctl.conf

sudo cp -f sysctl.conf /etc/sysctl.conf

sudo iptables -t nat -A POSTROUTING -o eth0 -j MASQUERADE




 #./stack.sh
