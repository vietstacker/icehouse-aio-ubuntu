#!/bin/bash -ex

source config.cfg
export OS_SERVICE_TOKEN="$OS_SERVICE_TOKEN"
export OS_SERVICE_ENDPOINT="http://$MASTER:35357/v2.0"

export SERVICE_ENDPOINT="http://$MASTER:35357/v2.0"

get_id () {
    echo `$@ | awk '/ id / { print $4 }'`
}

# Tenants
ADMIN_TENANT=$(get_id keystone tenant-create --name=$ADMIN_TENANT_NAME)
SERVICE_TENANT=$(get_id keystone tenant-create --name=$SERVICE_TENANT_NAME)
DEMO_TENANT=$(get_id keystone tenant-create --name=$DEMO_TENANT_NAME)
INVIS_TENANT=$(get_id keystone tenant-create --name=$INVIS_TENANT_NAME)

# Users
ADMIN_USER=$(get_id keystone user-create --name="$ADMIN_USER_NAME" --pass="$ADMIN_PASS" --email=congtt@teststack.com)
DEMO_USER=$(get_id keystone user-create --name="$DEMO_USER_NAME" --pass="$ADMIN_PASS" --email=congtt@teststack.com)

# Roles
ADMIN_ROLE=$(get_id keystone role-create --name="$ADMIN_ROLE_NAME")
KEYSTONEADMIN_ROLE=$(get_id keystone role-create --name="$KEYSTONEADMIN_ROLE_NAME")
KEYSTONESERVICE_ROLE=$(get_id keystone role-create --name="$KEYSTONESERVICE_ROLE_NAME")

# Add Roles to Users in Tenants
keystone user-role-add --user-id $ADMIN_USER --role-id $ADMIN_ROLE --tenant-id $ADMIN_TENANT
keystone user-role-add --user-id $ADMIN_USER --role-id $ADMIN_ROLE --tenant-id $DEMO_TENANT
keystone user-role-add --user-id $ADMIN_USER --role-id $KEYSTONEADMIN_ROLE --tenant-id $ADMIN_TENANT
keystone user-role-add --user-id $ADMIN_USER --role-id $KEYSTONESERVICE_ROLE --tenant-id $ADMIN_TENANT

# The Member role is used by Horizon and Swift
MEMBER_ROLE=$(get_id keystone role-create --name="$MEMBER_ROLE_NAME")
keystone user-role-add --user-id $DEMO_USER --role-id $MEMBER_ROLE --tenant-id $DEMO_TENANT
keystone user-role-add --user-id $DEMO_USER --role-id $MEMBER_ROLE --tenant-id $INVIS_TENANT

# Configure service users/roles
NOVA_USER=$(get_id keystone user-create --name=nova --pass="$SERVICE_PASSWORD" --tenant-id $SERVICE_TENANT --email=nova@teststack.com)
keystone user-role-add --tenant-id $SERVICE_TENANT --user-id $NOVA_USER --role-id $ADMIN_ROLE

GLANCE_USER=$(get_id keystone user-create --name=glance --pass="$SERVICE_PASSWORD" --tenant-id $SERVICE_TENANT --email=glance@teststack.com)
keystone user-role-add --tenant-id $SERVICE_TENANT --user-id $GLANCE_USER --role-id $ADMIN_ROLE

SWIFT_USER=$(get_id keystone user-create --name=swift --pass="$SERVICE_PASSWORD" --tenant-id $SERVICE_TENANT --email=swift@teststack.com)
keystone user-role-add --tenant-id $SERVICE_TENANT --user-id $SWIFT_USER --role-id $ADMIN_ROLE

RESELLER_ROLE=$(get_id keystone role-create --name=ResellerAdmin)
keystone user-role-add --tenant-id $SERVICE_TENANT --user-id $NOVA_USER --role-id $RESELLER_ROLE

NEUTRON_USER=$(get_id keystone user-create --name=neutron --pass="$SERVICE_PASSWORD" --tenant-id $SERVICE_TENANT --email=neutron@teststack.com)
keystone user-role-add --tenant-id $SERVICE_TENANT --user-id $NEUTRON_USER --role-id $ADMIN_ROLE

CINDER_USER=$(get_id keystone user-create --name=cinder --pass="$SERVICE_PASSWORD" --tenant-id $SERVICE_TENANT --email=cinder@teststack.com)
keystone user-role-add --tenant-id $SERVICE_TENANT --user-id $CINDER_USER --role-id $ADMIN_ROLE

echo "########## Bat dau tao ENDPOINT cho cac dich vu ########## "
sleep 5 

#API Endpoint

echo "########## Tao service KEYSTONE ##########"
keystone service-create --name=keystone --type=identity --description="OpenStack Identity"
echo "########## Tao endpoint KEYSTONE ##########"
keystone endpoint-create \
--region RegionOne \
--service-id=$(keystone service-list | awk '/ identity / {print $2}') \
--publicurl=http://$MASTER:5000/v2.0 \
--internalurl=http://$MASTER:5000/v2.0 \
--adminurl=http://$MASTER:35357/v2.0

echo "########## Tao service GLANCE ##########"
keystone service-create --name=glance --type=image --description="OpenStack Image Service"
echo "########## Tao endpoint GLANCE ##########"
keystone endpoint-create \
--region RegionOne \
--service-id=$(keystone service-list | awk '/ image / {print $2}') \
--publicurl=http://$MASTER:9292/v2 \
--internalurl=http://$MASTER:9292/v2 \
--adminurl=http://$MASTER:9292/v2

echo "########## Tao service NOVA ##########"
keystone service-create --name=nova --type=compute --description="OpenStack Compute"
echo "########## Tao endpoint NOVA ##########"
keystone endpoint-create \
--region RegionOne \
--service-id=$(keystone service-list | awk '/ compute / {print $2}') \
--publicurl=http://$MASTER:8774/v2/%\(tenant_id\)s \
--internalurl=http://$MASTER:8774/v2/%\(tenant_id\)s \
--adminurl=http://$MASTER:8774/v2/%\(tenant_id\)s

echo "########## Tao service NEUTRON ##########"
keystone service-create --name neutron --type network --description "OpenStack Networking"
echo "########## Tao endpoint NEUTRON ##########"
keystone endpoint-create \
--region RegionOne \
--service-id $(keystone service-list | awk '/ network / {print $2}') --publicurl http://$MASTER:9696 \
--adminurl http://$MASTER:9696 \
--internalurl http://$MASTER:9696

echo "########## Tao service CINDER Version 1 ##########"
keystone service-create --name=cinder --type=volume --description="OpenStack Block Storage"
echo "########## Tao endpoint CINDER Version 1 ##########"
keystone endpoint-create \
--region RegionOne \
--service-id=$(keystone service-list | awk '/ volume / {print $2}') \
--publicurl=http://$MASTER:8776/v1/%\(tenant_id\)s \
--internalurl=http://$MASTER:8776/v1/%\(tenant_id\)s \
--adminurl=http://$MASTER:8776/v1/%\(tenant_id\)s

echo "########## Tao service CINDER Version 2 ##########"
keystone service-create --name=cinderv2 --type=volumev2 --description="OpenStack Block Storage v2"
echo "########## Tao endpoint CINDER Version 2 ##########"
keystone endpoint-create \
--region RegionOne \
--service-id=$(keystone service-list | awk '/ volumev2 / {print $2}') \
--publicurl=http://$MASTER:8776/v2/%\(tenant_id\)s \
--internalurl=http://$MASTER:8776/v2/%\(tenant_id\)s \
--adminurl=http://$MASTER:8776/v2/%\(tenant_id\)s

sleep 5
echo "########## TAO FILE CHO BIEN MOI TRUONG ##########"
echo "export OS_USERNAME=admin" > admin-openrc.sh
echo "export OS_PASSWORD=Welcome123" >> admin-openrc.sh
echo "export OS_TENANT_NAME=admin" >> admin-openrc.sh
echo "export OS_AUTH_URL=http://$MASTER:35357/v2.0" >> admin-openrc.sh

echo "########## Huy bien moi truong truoc do ##########"
unset OS_SERVICE_TOKEN OS_SERVICE_ENDPOINT
chmod +x admin-openrc.sh

sleep 5
echo "########## Thuc thi bien moi truong ##########"
cat  admin-openrc.sh >> /etc/profile
cp  admin-openrc.sh /root/admin-openrc.sh

# export OS_USERNAME=admin
# export OS_PASSWORD=Welcome123
# export OS_TENANT_NAME=admin
# export OS_AUTH_URL=http://$MASTER:35357/v2.0

echo "########## Hoan thanh cai dat keystone ##########"

#echo "#################### Kiem tra bien moi truong ##################"
#sleep 5
#keystone user-list
