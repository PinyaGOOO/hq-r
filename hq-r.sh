#!/bin/bash
echo -n "Napishi MAC path:HQ-SRV=HARDWARE-net0: "
read mac

nmcli con modify ens18 ipv6.method manual ipv6.addresses 2024:1::2/64
nmcli con modify ens18 ipv6.gateway 2024:1::1
nmcli con modify ens18 ipv4.method manual ipv4.addresses 1.1.1.2/30
nmcli con modify ens18 ipv4.gateway 1.1.1.1
nmcli con modify ens18 ipv4.dns 8.8.8.8
nmcli con modify ens18 ipv6.dns 2001:4860:4860::8888

nmcli con modify Проводное\ подключение\ 1 ipv6.method manual ipv6.addresses FD24:172::1/122
nmcli con modify Проводное\ подключение\ 1 ipv4.method manual ipv4.addresses 172.16.100.1/26

nmcli con modify Проводное\ подключение\ 2 ipv6.method manual ipv6.addresses 2024:4::1/64
nmcli con modify Проводное\ подключение\ 2 ipv6.gateway 2024:4::2
nmcli con modify Проводное\ подключение\ 2 ipv4.method manual ipv4.addresses 4.4.4.1/30

echo -e "net.ipv4.ip_forward=1\nnet.ipv6.conf.all.forwarding=1" >> /etc/sysctl.conf
sysctl -p

dnf install -y nftables
echo -e 'table inet my_nat {\n\tchain my_masquerade {\n\ttype nat hook postrouting priority srcnat;\n\toifname "ens18" masquerade\n\t}\n}' > /etc/nftables/hq-r.nft
echo 'include "/etc/nftables/hq-r.nft"' >> /etc/sysconfig/nftables.conf
systemctl enable --now nftables

nmcli con add type ip-tunnel ifname tun1 mode gre remote 2.2.2.2 local 1.1.1.2
nmcli con modify ip-tunnel-tun1 ipv4.method manual ipv4.addresses 10.10.10.1/30
nmcli con modify ip-tunnel-tun1 ipv6.method manual ipv6.addresses FD24:10::1/64
nmcli connection modify ip-tunnel-tun1 ip-tunnel.ttl 64
sed -i '11i\parent=ens18' /etc/NetworkManager/system-connections/ip-tunnel-tun1.nmconnection
sed -i '/id=ip-tunnel-tun1/d' /etc/NetworkManager/system-connections/ip-tunnel-tun1.nmconnection
sed -i '2i\id=tun1' /etc/NetworkManager/system-connections/ip-tunnel-tun1.nmconnection

dnf install -y frr
sed -i '/ospfd=no/d' /etc/frr/daemons
sed -i '18i\ospfd=yes' /etc/frr/daemons
sed -i '/ospf6d=no/d' /etc/frr/daemons
sed -i '19i\ospf6d=yes' /etc/frr/daemons
systemctl restart frr
systemctl enable --now frr

vtysh -c "configure terminal" \
    -c "router ospf" \
    -c "passive-interface default" \
    -c "network 172.16.100.0/26 area 0" \
    -c "network 10.10.10.0/30 area 0" \
    -c "exit" \
    -c "interface tun1" \
    -c "no ip ospf network broadcast" \
    -c "no ip ospf passive" \
    -c "exit" \
    -c "do write" \
    -c "router ospf6" \
    -c "ospf6 router-id 1.1.1.1" \
    -c "exit" \
    -c "interface tun1" \
    -c "ipv6 ospf6 area 0" \
    -c "exit" \
    -c "interface ens18" \
    -c "ipv6 ospf6 area 0" \
    -c "exit" \
    -c "do write"

dnf install -y dhcp-server


echo -e "subnet 172.16.100.0 netmask 255.255.255.192 {\n  range 172.16.100.2 172.16.100.62;\n  option routers 172.16.100.1;\n  default-lease-time 600;\n  max-lease-time 7200;\n}\nhost hq-srv {\n\thardware ethernet $mac;\n\tfixed-address 172.16.100.2;\n}" >> /etc/dhcp/dhcpd.conf
echo -e "DHCPDARGS=ens19" >>/etc/sysconfig/dhcpd
systemctl restart dhcpd
systemctl enable --now dhcpd

useradd -c "Admin" admin -U
echo "admin:P@ssw0rd" | chpasswd
useradd -c "Network Admin" network_admin -U
echo "network_admin:P@ssw0rd" | chpasswd

mkdir /var/backup
echo -e '#!/bin/bash\n\ndata=$(date +%d.%m.%Y-%H:%M:%S)\nmkdir /var/backup/$data\ncp -r /etc/frr /var/backup/$data\ncp -r /etc/nftables /var/backup/$data\ncp -r /etc/NetworkManager/system-connections /var/backup/$data\ncp -r /etc/dhcp /var/backup/$data\ncd /var/backup\ntar czfv "./$data.tar.gz" ./$data\nrm -r /var/backup/$data' > /var/backup/backup.sh
chmod +x /var/backup/backup.sh
/var/backup/backup.sh





