# Hướng dẫn cài đặt bằng script OpenStack Icehouse AIO

**MỤC LỤC** 
được tạo bằng [DocToc](http://doctoc.herokuapp.com/)


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
    cd icehouse-aio-ubuntu
    chmod +x *.sh

### 2.0 Update hệ thống và cài đặt các gói bổ trợ

Thiết lập tên, khai báo file hosts, cấu hình ip address cho các NICs:

    bash 0-icehouse-aio-prepare.sh
    
Sau khi thực hiện script trên xong, hệ thống sẽ khởi động lại. Lúc này bạn đăng nhập vào hệ thống và di chuyển vào thưc mục icehouse-allinone bằng lệnh:

    cd icehouse-aio-ubuntu

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
   
### 2.7 Cài đặt OpenvSwitch, cấu hình br-int, br-ex

Cài đặt OpenvSwtich và cấu hình br-int, br-ex cho Ubuntu:

    bash 7-icehouse-aio-config-ip-neutron.sh
  
### 2.8 Cài đặt NEUTRON
Cài đặt Neutron Server, ML, L3-agent, DHCP-agent, metadata-agent:

Login vào bằng tài khoản root và di chuyển vào thư mục icehouse-allinone

    cd icehouse-aio-ubuntu
    bash 8-icehouse-aio-install-neutron.sh

### 2.9 Cài đặt HORIZON
Cài đặt Horizon để cung cấp GUI cho người dùng thao tác với OpenStack:

    bash 9-icehouse-aio-install-horizon.sh

### 2.10 Tạo các subnet, router cho tenant
Tạo sẵn subnet cho Public Network và Private Network trong teant ADMIN:

    bash creat-network.sh

# III. Chuyển qua hướng dẫn sử dụng dashboard (horizon)
Truy cập vào dashboard với IP http://IP_ADDRESS_External/horizon

	User: admin hoặc demo
	Pass: Welcome123









