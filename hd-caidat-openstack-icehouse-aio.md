# Hướng dẫn cài đặt bằng script OpenStack Icehouse AIO

**MỤC LỤC** 
được tạo bằng [DocToc](http://doctoc.herokuapp.com/)

- [Hướng dẫn cài đặt bằng script OpenStack Icehouse AIO](#user-content-h%C6%B0%E1%BB%9Bng-d%E1%BA%ABn-c%C3%A0i-%C4%91%E1%BA%B7t-b%E1%BA%B1ng-script-openstack-icehouse-aio)
- [I. Thông tin LAB](#user-content-i-th%C3%B4ng-tin-lab)
- [II. Các bước cài đặt](#user-content-ii-c%C3%A1c-b%C6%B0%E1%BB%9Bc-c%C3%A0i-%C4%91%E1%BA%B7t)
	- [1. Cài đặt Ubuntu 12.04 trong Vmware Workstation](#user-content-1-c%C3%A0i-%C4%91%E1%BA%B7t-ubuntu-1204-trong-vmware-workstation)
	- [2. Thực hiện các script](#user-content-2-th%E1%BB%B1c-hi%E1%BB%87n-c%C3%A1c-script)
		- [2.0 Update hệ thống và cài đặt các gói bổ trợ](#user-content-20-update-h%E1%BB%87-th%E1%BB%91ng-v%C3%A0-c%C3%A0i-%C4%91%E1%BA%B7t-c%C3%A1c-g%C3%B3i-b%E1%BB%95-tr%E1%BB%A3)
		- [2.1 Cài đặt MYSQL và tạo DB cho các thành phần](#user-content-21-c%C3%A0i-%C4%91%E1%BA%B7t-mysql-v%C3%A0-t%E1%BA%A1o-db-cho-c%C3%A1c-th%C3%A0nh-ph%E1%BA%A7n)
		- [2.2 Cài đặt KEYSTONE](#user-content-22-c%C3%A0i-%C4%91%E1%BA%B7t-keystone)
		- [2.3 Khai báo user, role, tenant, endpoint](#user-content-23-khai-b%C3%A1o-user-role-tenant-endpoint)
		- [2.4 Cài đặt GLANCE](#user-content-24-c%C3%A0i-%C4%91%E1%BA%B7t-glance)
		- [2.5 Cài đặt NOVA và kiểm tra hoạt động](#user-content-25-c%C3%A0i-%C4%91%E1%BA%B7t-nova-v%C3%A0-ki%E1%BB%83m-tra-ho%E1%BA%A1t-%C4%91%E1%BB%99ng)
		- [2.6 Cài đặt CINDER](#user-content-26-c%C3%A0i-%C4%91%E1%BA%B7t-cinder)
		- [2.7 Cài đặt OpenvSwich, cấu hình br-int, br-ex](#user-content-27-c%C3%A0i-%C4%91%E1%BA%B7t-openvswich-c%E1%BA%A5u-h%C3%ACnh-br-int-br-ex)
		- [2.8 Cài đặt NEUTRON](#user-content-28-c%C3%A0i-%C4%91%E1%BA%B7t-neutron)
		- [2.9 Cài đặt HORIZON](#user-content-29-c%C3%A0i-%C4%91%E1%BA%B7t-horizon)
		- [2.10 Tạo các subnet, router cho tenant](#user-content-210-t%E1%BA%A1o-c%C3%A1c-subnet-router-cho-tenant)
- [III. Chuyển qua hướng dẫn sử dụng dashboard (horizon)](#user-content-iii-chuy%E1%BB%83n-qua-h%C6%B0%E1%BB%9Bng-d%E1%BA%ABn-s%E1%BB%AD-d%E1%BB%A5ng-dashboard-horizon)

# I. Thông tin LAB
- Cài đặt OpenStack Icehouse trên Ubuntu 12.04, môi trường giả lập vmware-workstation
- Các thành phần cài đặt trong OpenStack: Keystone, Glance, Nova (sử dụng KVM), Neutron, Horizon
- Neutron sử dụng plugin ML2, GRE và use case cho mô hình mạng là per-teanant per-router
- Máy ảo sử dụng 2 Nics. Eth0 dành cho Extenal, API, MGNT. Eth1 dành cho Internal.

# II. Các bước cài đặt
## 1. Cài đặt Ubuntu 12.04 trong Vmware Workstation

Thiết lập cấu hình cho Ubuntu Server 12.04 trong VMware Workstation hoặc máy vật lý như sau

- RAM 4GB
- 1st HDD (sda) 60GB cài đặt Ubuntu server 12.04-4
- 2nd HDD (sdb) Làm volume cho CINDER
- 3rd HDD (sdc) Dùng cho cấu hình SWIFT
- NIC 1st : External - dùng chế độ bridge - Dải IP 192.168.1.0/24 - Gateway 192.168.1.1
- NIC 2nd : Inetnal VM - dùng chế độ vmnet4 (cần setup trong vmware workstation trước khi cài Ubuntu - dải IP  192.168.10.0/24

| NIC 	       | IP ADDRESS     |  SUBNET MASK  | GATEWAY       | DNS     |                   Note               |
| -------------|----------------|---------------|---------------|-------  |--------------------------------------| 
| NIC 1 (eth0) | 192.168.1.xxx  | 255.255.255.0 | 192.168.1.1   | 8.8.8.8 | Bridge trong VMware Workstation      |
| NIC 2 (eth1) | 192.168.10.xxx | 255.255.255.0 |    NULL       |   NULL  | Dùng VMnet4 trong Vmware Workstation |

- Mật khẩu cho tất cả các dịch vụ là Welcome123
- Cài đặt với quyền root

- Ảnh thiết lập cấu hình cho Ubuntu server

<img src=http://i.imgur.com/NpiF3HF.png width="60%" height="60%" border="1">

- Ảnh thiết lập network cho vmware workstation 

<img src=http://i.imgur.com/pNg16qO.png width="60%" height="60%" border="1">


## 2. Thực hiện các script

Thực hiện tải gói gile và phân quyền cho các file sau khi tải từ github về:

    apt-get install git -y
    git clone https://github.com/vietstacker/icehouse-aio-ubuntu.git
    cd icehouse-allinone-ubuntu
    chmod +x *.sh

### 2.0 Update hệ thống và cài đặt các gói bổ trợ

Thiết lập tên, khai báo file hosts, cấu hình ip address cho các NICs:

    bash 0-icehouse-aio-prepare.sh
    
Sau khi thực hiện script trên xong, hệ thống sẽ khởi động lại. Lúc này bạn đăng nhập vào hệ thống và di chuyển vào thưc mục icehouse-allinone bằng lệnh:

    cd icehouse-allinone-ubuntu

### 2.1 Cài đặt MYSQL và tạo DB cho các thành phần

Cài đặt MYSQL, tạo DB cho Keystone, Glance, Nova, Neutron:

    bash 1-icehouse-aio-install-mysql.sh

### 2.2 Cài đặt KEYSTONE 

Cài đặt và cấu hình file keystone.conf:

    bash 2-icehouse-aio-install-keystone.sh

### 2.3 Khai báo user, role, tenant, endpoint

Khai báo user, role, teant và endpoint cho các service trong OpenStack:

    bash 3-icehouse-aio-creatusetenant.sh

Chạy lệnh để hủy biến môi trường:

    unset OS_SERVICE_ENDPOINT OS_SERVICE_TOKEN

Thực thi lệnh source /etc/profile để khởi tạo biến môi trường:

    source /etc/profile
   
Script trên thực hiện tạo các teant có tên là admin, demo, service. Tạo ra service có tên là keystone, glance, nova, cinder, neutron swift

### 2.4 Cài đặt GLANCE

Cài đặt GLACE và add image cirros để kiểm tra hoạt động của Glance sau khi cài:

    bash 4-icehouse-aio-install-glance.sh

Script trên thực hiện cài đặt và cấu hình Glance. Sau đó thực hiển tải image cirros (một dạng lite lunix), có tác dụng để kiểm tra các 
hoạt động của Keystone, Glance và sau này dùng để khởi tạo máy ảo.

### 2.5 Cài đặt NOVA và kiểm tra hoạt động

Cài đặt các gói về nova:

    bash 5-icehouse-aio-install-nova.sh

Nếu xuất hiện cửa số dưới khi cấu hình cho gói libguestfs0 thì chọn (yes)

<img src=http://i.imgur.com/iIggDlR.png width="60%" height="60%">

### 2.6 Cài đặt CINDER

Cài đặt các gói cho CINDER, cấu hình volume group:

    bash 6-icehouse-aio-install-cinder.sh
   
### 2.7 Cài đặt OpenvSwich, cấu hình br-int, br-ex

Cài đặt OpenvSwtich và cấu hình br-int, br-ex cho Ubuntu:

    bash 7-icehouse-aio-config-ip-neutron.sh
  
### 2.8 Cài đặt NEUTRON
Cài đặt Neutron Server, ML, L3-agent, DHCP-agent, metadata-agent:

Login vào bằng tài khoản root và di chuyển vào thư mục icehouse-allinone

    cd icehouse-allinone-ubuntu
    bash 8-icehouse-aio-install-neutron.sh

### 2.9 Cài đặt HORIZON
Cài đặt Horizon để cung cấp GUI cho người dùng thao tác với OpenStack:

    bash 9-icehouse-aio-install-horizon.sh

### 2.10 Tạo các subnet, router cho tenant
Tạo sẵn subnet cho Public Network và Private Network trong teant ADMIN:

    bash creat-network.sh

# III. Chuyển qua hướng dẫn sử dụng dashboard (horizon)
Truy cập vào dashboard với IP 192.168.1.55/horizon

	User: admin hoặc demo
	Pass: Welcome123









