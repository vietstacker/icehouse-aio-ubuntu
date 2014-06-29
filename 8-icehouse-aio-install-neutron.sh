#!/bin/bash -ex
source config.cfg

SERVICE_ID=$(keystone tenant-get "$SERVICE_TENANT_NAME" | awk '$2~/^id/{print $4}')
brex_address=`/sbin/ifconfig br-ex | awk '/inet addr/ {print $2}' | cut -f2 -d ":"`
MASTER=$brex_address

echo "########## CAI DAT NEUTRON TREN CONTROLLER ##########"
apt-get -y install neutron-server neutron-plugin-ml2 neutron-plugin-openvswitch-agent \
neutron-l3-agent neutron-dhcp-agent

######## SAO LUU CAU HINH NEUTRON.CONF CHO CONTROLLER##################"
echo "########## Sua lai file neutron.conf ##########"

#
controlneutron=/etc/neutron/neutron.conf
test -f $controlneutron.orig || cp $controlneutron $controlneutron.orig
rm $controlneutron
cat << EOF > $controlneutron
[DEFAULT]
state_path = /var/lib/neutron
lock_path = \$state_path/lock
core_plugin = ml2
service_plugins = router
auth_strategy = keystone
allow_overlapping_ips = True
rpc_backend = neutron.openstack.common.rpc.impl_kombu

rabbit_host = $MASTER
rabbit_password = $RABBIT_PASS
rabbit_userid = guest

notification_driver = neutron.openstack.common.notifier.rpc_notifier
notify_nova_on_port_status_changes = True
notify_nova_on_port_data_changes = True
nova_url = http://$MASTER:8774/v2
nova_admin_username = nova
nova_admin_tenant_id = $SERVICE_ID
nova_admin_password = $ADMIN_PASS
nova_admin_auth_url = http://$MASTER:35357/v2.0

[quotas]

[agent]
root_helper = sudo /usr/bin/neutron-rootwrap /etc/neutron/rootwrap.conf

[keystone_authtoken]
auth_host = 127.0.0.1
auth_port = 35357
auth_protocol = http
admin_tenant_name = service
admin_user = neutron
admin_password = $ADMIN_PASS
signing_dir = \$state_path/keystone-signing

[database]
connection = mysql://neutron:$MYSQL_PASS@$MASTER/neutron
[service_providers]
service_provider=LOADBALANCER:Haproxy:neutron.services.loadbalancer.drivers.haproxy.plugin_driver.HaproxyOnHostPluginDriver:default
service_provider=VPN:openswan:neutron.services.vpn.service_drivers.ipsec.IPsecVPNDriver:default

EOF


######## SAO LUU CAU HINH ML2 CHO CONTROLLER##################"
echo "########## Sau file cau hinh cho ml2_conf.ini ##########"
# sleep 7

controlML2=/etc/neutron/plugins/ml2/ml2_conf.ini
test -f $controlML2.orig || cp $controlML2 $controlML2.orig
rm $controlML2

cat << EOF > $controlML2
[ml2]
type_drivers = gre
tenant_network_types = gre
mechanism_drivers = openvswitch

[ml2_type_flat]

[ml2_type_vlan]

[ml2_type_gre]
tunnel_id_ranges = 1:1000

[ml2_type_vxlan]

[securitygroup]
enable_security_group = True
firewall_driver = neutron.agent.linux.iptables_firewall.OVSHybridIptablesFirewallDriver

[ovs]
local_ip = $LOCAL_IP
tunnel_type = gre
enable_tunneling = True

EOF


######## SAO LUU CAU HINH METADATA CHO CONTROLLER##################"
echo "########## Sua file cau hinh metadata_agent.ini ##########"
# sleep 7

metadatafile=/etc/neutron/metadata_agent.ini
test -f $metadatafile.orig || cp $metadatafile $metadatafile.orig
rm $metadatafile
cat << EOF > $metadatafile
[DEFAULT]
verbose = True 
auth_url = http://localhost:5000/v2.0
auth_region = RegionOne
admin_tenant_name = service
admin_user = neutron
admin_password = $ADMIN_PASS
nova_metadata_ip = $MASTER
metadata_proxy_shared_secret = $METADATA_SECRET

EOF

######## SUA FILE CAU HINH  DHCP ##################"
echo "########## Sua file cau hinh DHCP ##########"
sleep 7

dhcpfile=/etc/neutron/dhcp_agent.ini 
test -f $dhcpfile.orig || cp $dhcpfile $dhcpfile.orig
rm $dhcpfile
cat << EOF > $dhcpfile
[DEFAULT]
verbose = True 
interface_driver = neutron.agent.linux.interface.OVSInterfaceDriver
dhcp_driver = neutron.agent.linux.dhcp.Dnsmasq
use_namespaces = True

EOF

###################### SAO LUU CAU HINH L3 ###########################"
echo "########## Sua file cau hinh l3_agent.ini ##########"
sleep 7


l3file=/etc/neutron/l3_agent.ini
test -f $l3file.orig || cp $l3file $l3file.orig
rm $l3file
touch $l3file
cat << EOF >> $l3file
[DEFAULT]
verbose = True 
interface_driver = neutron.agent.linux.interface.OVSInterfaceDriver
use_namespaces = True

EOF

chown root:neutron /etc/neutron/*
chown root:neutron $controlML2

echo "########## KHOI DONG LAI NEUTRON        ##########"
sleep 5
cd /etc/init.d/; for i in $( ls neutron-* ); do sudo service $i restart; done

echo "########## KHOI DONG LAI NEUTRON (lan2) ##########"
sleep 5
cd /etc/init.d/; for i in $( ls neutron-* ); do sudo service $i restart; done
cd /root/


echo "########## KIEM TRA NEUTRON (cho 60s)   ##########"
#sleep 60
neutron agent-list
