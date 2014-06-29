#!/bin/bash -ex 

source config.cfg

echo "########## CAI DAT GLANCE ##########"
apt-get install glance python-glanceclient -y
echo "########## CAU HINH GLANCE API ##########"
sleep 5 
#/* Sao luu truoc khi sua file nova.conf
fileglanceapicontrol=/etc/glance/glance-api.conf
test -f $fileglanceapicontrol.orig || cp $fileglanceapicontrol $fileglanceapicontrol.orig
rm $fileglanceapicontrol

#Chen noi dung file /etc/glance/glance-api.conf

cat << EOF > $fileglanceapicontrol
[DEFAULT]
default_store = file
bind_host = 0.0.0.0
bind_port = 9292
log_file = /var/log/glance/api.log
backlog = 4096
workers = 1
registry_host = 0.0.0.0
registry_port = 9191
registry_client_protocol = http
rabbit_host = localhost
rabbit_port = 5672
rabbit_use_ssl = false
rabbit_userid = guest
rabbit_password = guest
rabbit_virtual_host = /
rabbit_notification_exchange = glance
rabbit_notification_topic = notifications
rabbit_durable_queues = False
qpid_notification_exchange = glance
qpid_notification_topic = notifications
qpid_hostname = localhost
qpid_port = 5672
qpid_username =
qpid_password =
qpid_sasl_mechanisms =
qpid_reconnect_timeout = 0
qpid_reconnect_limit = 0
qpid_reconnect_interval_min = 0
qpid_reconnect_interval_max = 0
qpid_reconnect_interval = 0
qpid_heartbeat = 5
qpid_protocol = tcp
qpid_tcp_nodelay = True
filesystem_store_datadir = /var/lib/glance/images/
swift_store_auth_version = 2
swift_store_auth_address = 127.0.0.1:5000/v2.0/
swift_store_user = jdoe:jdoe
swift_store_key = a86850deb2742ec3cb41518e26aa2d89
swift_store_container = glance
swift_store_create_container_on_put = False
swift_store_large_object_size = 5120
swift_store_large_object_chunk_size = 200
swift_enable_snet = False
s3_store_host = 127.0.0.1:8080/v1.0/
s3_store_access_key = <20-char AWS access key>
s3_store_secret_key = <40-char AWS secret key>
s3_store_bucket = <lowercased 20-char aws access key>glance
s3_store_create_bucket_on_put = False
sheepdog_store_address = localhost
sheepdog_store_port = 7000
sheepdog_store_chunk_size = 64
delayed_delete = False
scrub_time = 43200
scrubber_datadir = /var/lib/glance/scrubber
image_cache_dir = /var/lib/glance/image-cache/
[database]
# sqlite_db = /var/lib/glance/glance.sqlite
backend = sqlalchemy
connection = mysql://glance:$MYSQL_PASS@$MASTER/glance
[keystone_authtoken]
auth_host = 127.0.0.1
auth_port = 35357
auth_protocol = http
admin_tenant_name = service
admin_user = glance
admin_password = $ADMIN_PASS
[paste_deploy]
flavor=keystone
[store_type_location_strategy]

EOF
chown glance:glance $fileglanceapicontrol
#
sleep 5
echo "########## CAU HINH GLANCE REGISTER ##########"
#/* Sao luu truoc khi sua file nova.conf
fileglanceregcontrol=/etc/glance/glance-registry.conf
test -f $fileglanceregcontrol.orig || cp $fileglanceregcontrol $fileglanceregcontrol.orig
rm $fileglanceregcontrol
#Chen noi dung file /etc/glance/glance-registry.conf

cat << EOF > $fileglanceregcontrol
[DEFAULT]
bind_host = 0.0.0.0
bind_port = 9191
log_file = /var/log/glance/registry.log
backlog = 4096
api_limit_max = 1000
limit_param_default = 25
[database]
backend = sqlalchemy
connection = mysql://glance:$MYSQL_PASS@$MASTER/glance
[keystone_authtoken]
auth_host = 127.0.0.1
auth_port = 35357
auth_protocol = http
admin_tenant_name = service
admin_user = glance
admin_password = $ADMIN_PASS
[paste_deploy]
flavor=keystone

EOF

chown glance:glance $fileglanceregcontrol

sleep 5
echo "########## Xoa file glance.sqlite ##########"
# rm /var/lib/glance/glance.sqlite

sleep 5
echo "########## Dong bo DB cho GLANCE ##########"
glance-manage db_sync

sleep 5
echo "########## Khoi dong lai GLANCE ##########"
service glance-registry restart
service glance-api restart
service glance-registry restart
service glance-api restart

#
sleep 7
echo "########## Dua image vao Glance ##########"
mkdir images
cd images/
wget http://cdn.download.cirros-cloud.net/0.3.2/cirros-0.3.2-x86_64-disk.img
glance image-create --name "cirros-0.3.2-x86_64" --disk-format qcow2 \
--container-format bare --is-public True --progress < cirros-0.3.2-x86_64-disk.img
cd /root/

sleep 4
echo "########## Kiem tra lai image vua them vao GLANCE ##########"
glance image-list

echo "########## Ket thuc qua trinh cai dat GLANCE ##########"
