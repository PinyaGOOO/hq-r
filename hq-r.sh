#!/bin/bash
dnf remove -y git
dnf install -y nftables
dnf install -y frr
dnf install -y dhcp-server
dnf install -y chrony

nmcli con modify ens18 ipv4.method manual ipv4.addresses 1.1.1.2/30
nmcli con modify ens18 ipv4.gateway 1.1.1.1
nmcli con modify ens18 ipv4.dns 8.8.8.8

nmcli con modify Проводное\ подключение\ 1 ipv4.method manual ipv4.addresses 172.16.100.1/28

nmcli con modify Проводное\ подключение\ 2 ipv4.method manual ipv4.addresses 4.4.4.1/30

echo -e "net.ipv4.ip_forward=1" >> /etc/sysctl.conf
sysctl -p

echo -e 'table inet my_nat {\n\tchain prerouting {\n\ttype nat hook prerouting priority filter; policy accept;\n\tip daddr 4.4.4.1 tcp dport 22 dnat ip to 172.16.100.2:2020\n\tip daddr 1.1.1.2 tcp dport 22 dnat ip to 172.16.100.2:2020\n\t}\n\n\tchain my_masquerade {\n\ttype nat hook postrouting priority srcnat;\n\toifname "ens18" masquerade\n\t}\n}' > /etc/nftables/hq-r.nft
echo 'include "/etc/nftables/hq-r.nft"' >> /etc/sysconfig/nftables.conf
systemctl enable --now nftables

nmcli con add type ip-tunnel ifname tun1 mode gre remote 2.2.2.2 local 1.1.1.2
nmcli con modify ip-tunnel-tun1 ipv4.method manual ipv4.addresses 10.10.10.1/30
nmcli connection modify ip-tunnel-tun1 ip-tunnel.ttl 64
sed -i '11i\parent=ens18' /etc/NetworkManager/system-connections/ip-tunnel-tun1.nmconnection
sed -i '/id=ip-tunnel-tun1/d' /etc/NetworkManager/system-connections/ip-tunnel-tun1.nmconnection
sed -i '2i\id=tun1' /etc/NetworkManager/system-connections/ip-tunnel-tun1.nmconnection

sed -i '/ospfd=no/d' /etc/frr/daemons
sed -i '18i\ospfd=yes' /etc/frr/daemons
sed -i '/ospf6d=no/d' /etc/frr/daemons
sed -i '19i\ospf6d=yes' /etc/frr/daemons
systemctl restart frr
systemctl enable --now frr

vtysh -c "configure terminal" \
    -c "router ospf" \
    -c "passive-interface default" \
    -c "network 172.16.100.0/28 area 0" \
    -c "network 10.10.10.0/30 area 0" \
    -c "network 4.4.4.0/30 area 0"\
    -c "exit" \
    -c "interface tun1" \
    -c "no ip ospf network broadcast" \
    -c "no ip ospf passive" \
    -c "exit" \
    -c "do write" 




echo -e "subnet 172.16.100.0 netmask 255.255.255.240 {\n  range 172.16.100.2 172.16.100.14;\n  option routers 172.16.100.1;\n  default-lease-time 600;\n  max-lease-time 7200;\n}\nhost hq-srv {\n\thardware ethernet BC:24:11:FD:81:60;\n\tfixed-address 172.16.100.2;\n\toption domain-name-servers 8.8.8.8;\n}" >> /etc/dhcp/dhcpd.conf
echo -e "DHCPDARGS=ens19" >>/etc/sysconfig/dhcpd
systemctl restart dhcpd
systemctl enable --now dhcpd

useradd -c "Admin" Admin -U
echo "Admin:P@ssw0rd" | chpasswd
useradd -c "Network Admin" Network_admin -U
echo "Network_admin:P@ssw0rd" | chpasswd

mkdir /var/{backup,backup-script}
echo -e '#!/bin/bash\n\ndata=$(date +%d.%m.%Y-%H:%M:%S)\nmkdir /var/backup/$data\ncp -r /etc/frr /var/backup/$data\ncp -r /etc/nftables /var/backup/$data\ncp -r /etc/NetworkManager/system-connections /var/backup/$data\ncp -r /etc/dhcp /var/backup/$data\ncd /var/backup\ntar czfv "./$data.tar.gz" ./$data\nrm -r /var/backup/$data' > /var/backup-script/backup.sh
chmod +x /var/backup-script/backup.sh
/var/backup-script/backup.sh

sed -i '3s/^/#/' /etc/chrony.conf
sed -i '4s/^/#/' /etc/chrony.conf
sed -i '5s/^/#/' /etc/chrony.conf
sed -i '6s/^/#/' /etc/chrony.conf
sed -i '7a\server 127.0.0.1 iburst prefer' /etc/chrony.conf
sed -i '8a\hwtimestamp *' /etc/chrony.conf
sed -i '9a\local stratum 6' /etc/chrony.conf
sed -i '10a\allow 0/0' /etc/chrony.conf
sed -i '11a\allow ::/0' /etc/chrony.conf

systemctl enable --now chronyd
systemctl restart chronyd
chronyc sources

hostnamectl set-hostname HQ-R; exec bash







