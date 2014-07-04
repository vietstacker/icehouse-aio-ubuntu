#!/bin/bash -ex
source config.cfg

echo "########## Tao Physical Volume va Volume Group (tren disk sdb ) ##########"
fdisk -l
pvcreate /dev/sdb
vgcreate cinder-volumes /dev/sdb

#
echo "########## Cai dat cac goi cho CINDER ##########"
sleep 3
apt-get install -y cinder-api cinder-scheduler cinder-volume iscsitarget open-iscsi iscsitarget-dkms python-cinderclient


echo "########## Cau hinh file cho cinder.conf ##########"

filecinder=/etc/cinder/cinder.conf
test -f $filecinder.orig || cp $filecinder $filecinder.orig
rm $filecinder
cat << EOF > $filecinder
[DEFAULT]
rootwrap_config = /etc/cinder/rootwrap.conf
api_paste_confg = /etc/cinder/api-paste.ini
iscsi_helper = tgtadm
volume_name_template = volume-%s
volume_group = cinder-volumes
verbose = True
auth_strategy = keystone
state_path = /var/lib/cinder
lock_path = /var/lock/cinder
volumes_dir = /var/lib/cinder/volumes
rpc_backend = cinder.openstack.common.rpc.impl_kombu
rabbit_host = $MASTER
rabbit_port = 5672
rabbit_userid = guest
rabbit_password = $RABBIT_PASS
glance_host = $MASTER
 
[database]
connection = mysql://cinder:$MYSQL_PASS@$MASTER/cinder
 
[keystone_authtoken]
auth_uri = http://$MASTER:5000
auth_host = $MASTER
auth_port = 35357
auth_protocol = http
admin_tenant_name = service
admin_user = cinder
admin_password = $ADMIN_PASS
EOF

# Phan quyen cho file cinder
chown cinder:cinder $filecinder

echo "########## Dong bo cho cinder ##########"
sleep 3
cinder-manage db sync

echo "########## Khoi dong lai CINDER ##########"
sleep 3
service cinder-api restart
service cinder-scheduler restart
service cinder-volume restart

echo "########## Hoan thanh viec cai dat CINDER ##########"

