#!/bin/bash -ex
source config.cfg

echo "########## CAI DAT NOVA TREN CONTROLLER ################"
apt-get install -y nova-api nova-cert nova-conductor nova-consoleauth \
nova-novncproxy nova-scheduler python-novaclient \
nova-compute-kvm python-guestfs 

echo "########## SAO LUU CAU HINH cho NOVA ##################"
controlnova=/etc/nova/nova.conf
test -f $controlnova.orig || cp $controlnova $controlnova.orig
rm $controlnova
cat << EOF > $controlnova
[DEFAULT]
dhcpbridge_flagfile=/etc/nova/nova.conf
dhcpbridge=/usr/bin/nova-dhcpbridge
logdir=/var/log/nova
state_path=/var/lib/nova
lock_path=/var/lock/nova
force_dhcp_release=True
iscsi_helper=tgtadm
libvirt_use_virtio_for_bridges=True
connection_type=libvirt
root_helper=sudo nova-rootwrap /etc/nova/rootwrap.conf
verbose=True
ec2_private_dns_show_ip=True
api_paste_config=/etc/nova/api-paste.ini
volumes_path = /var/lib/nova/volumes
enabled_apis = ec2,osapi_compute,metadata

# Khai bao cho GLANCE
glance_host = $MASTER

# Khai bao cho RABBITMQ
rpc_backend = rabbit
rabbit_host = $MASTER
rabbit_userid = guest
rabbit_password = $RABBIT_PASS

# Cau hinh cho VNC
my_ip = $MASTER
vncserver_listen = $MASTER
vncserver_proxyclient_address = $MASTER
auth_strategy = keystone
novncproxy_base_url = http://$MASTER:6080/vnc_auto.html

# Tung dong Start VM khi reboot OpenStack
resume_guests_state_on_host_boot=True

#Cho phep dat password cho Instance khi khoi tao
libvirt_inject_password = True
enable_instance_password = True

network_api_class = nova.network.neutronv2.api.API
neutron_url = http://$MASTER:9696
neutron_auth_strategy = keystone
neutron_admin_tenant_name = service
neutron_admin_username = neutron
neutron_admin_password = $ADMIN_PASS
neutron_admin_auth_url = http://$MASTER:35357/v2.0
linuxnet_interface_driver = nova.network.linux_net.LinuxOVSInterfaceDriver
firewall_driver = nova.virt.firewall.NoopFirewallDriver
security_group_api = neutron
service_neutron_metadata_proxy = true
neutron_metadata_proxy_shared_secret = $METADATA_SECRET
 
 
[database]
connection = mysql://nova:$MYSQL_PASS@$MASTER/nova
 
[keystone_authtoken]
auth_uri = http://$MASTER:5000
auth_host = $MASTER
auth_port = 35357
auth_protocol = http
admin_tenant_name = service
admin_user = nova
admin_password = $ADMIN_PASS

EOF
chown nova:nova $controlnova

echo "########## XOA FILE DB MAC DINH ##########"
sleep 7
rm /var/lib/nova/nova.sqlite

echo "########## DONG BO DB CHO NOVA ##########"
sleep 7 
nova-manage db sync


echo " "
echo "########## FIX LOI CHO NOVA ##########"
sleep 5
dpkg-statoverride --update --add root root 0644 /boot/vmlinuz-$(uname -r)

cat > /etc/kernel/postinst.d/statoverride <<EOF
#!/bin/sh
version="\$1"
# passing the kernel version is required
[ -z "\${version}" ] && exit 0
dpkg-statoverride --update --add root root 0644 /boot/vmlinuz-\${version}
EOF

chmod +x /etc/kernel/postinst.d/statoverride

# fix loi libvirtError: internal error: no supported architecture for os type 'hvm'
echo 'kvm_intel' >> /etc/modules
sleep 10
echo "########## KHOI DONG LAI NOVA ##########"
service nova-conductor restart
service nova-api restart
service nova-cert restart
service nova-consoleauth restart
service nova-scheduler restart
service nova-novncproxy restart
service nova-compute restart

sleep 10
echo "########## KHOI DONG NOVA LAN 2 ##########"
service nova-conductor restart
service nova-api restart
service nova-cert restart
service nova-consoleauth restart
service nova-scheduler restart
service nova-novncproxy restart
service nova-compute restart

echo "########## KIEM TRA LAI DICH VU NOVA ##########"
sleep 10
nova-manage service list
#sleep 3
#nova-manage service list

echo "########## KET THUC CAI DAT NOVA ##########"

