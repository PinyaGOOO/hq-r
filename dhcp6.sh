#!/bin/bash
mv /etc/dhcp/dhcpd6.conf /etc/dhcp/dhcpd6.conf.bak
cp /usr/share/doc/dhcp-server/dhcpd6.conf.example /etc/dhcp/dhcpd6.conf

echo -e "default-lease-time 2592000;\npreferred-lifetime 604800;\noption dhcp-renewal-time 3600;\noption dhcp-rebinding-time 7200;\n\nallow leasequery;\n\noption dhcp6.preference 255;\noption dhcp6.info-refresh-time 21600;\n\nsubnet6 FD24:172::/122 {\n\trange6 FD24:172::2 FD24:172::12;\n}\n" > /etc/dhcp/dhcpd6.conf

systemctl enable --now dhcpd6
echo -e "на hq-srv\nзаходим в nmtui ens18\nставим ipv6 автоматически(только dhcp)\nперезагружаем сетевой интерфейс(systemctl restart NetworkManager)\nнажмите любую клавишу для продолжения скрипта <3"
read -n 1 -s -r -p ""

echo -e "host hq-srv {\n\thost-identifier option\n\t\tdhcp6.client-id 00:04:17:06:02:ee:33:c3:7b:49:af:a0:d9:a5:44:b1:67:f1;\n\tfixed-address6 FD24:172::2;\n\tfixed-prefix6 FD24:172::/122;\n\toption dhcp6.name-servers FD24:172::2;\n}" >> /etc/dhcp/dhcpd6.conf
systemctl restart dhcpd6

sed -i '6,$d' /etc/radvd.conf
echo -e "interface ens19\n{\n\tAdvSendAdvert on;\n\tAdvManagedFlag on;\n\tAdvOtherConfigFlag on;\n\tprefix FD24:172::/122\n\t{\n\t\tAdvOnLink on;\n\t\tAdvAutonomous on;\n\t\tAdvRouterAddr on;\n\t};\n};" >> /etc/radvd.conf

systemctl restart radvd
systemctl enable --now radvd



