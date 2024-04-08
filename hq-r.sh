#!/bin/bash
nmcli con modify ens18 ipv6.method manual ipv6.addresses 2024:1::2/64
nmcli con modify ens18 ipv6.gateway 2024:1::1
nmcli con modify ens18 ipv4.method manual ipv4.addresses 1.1.1.2/30
nmcli con modify ens18 ipv4.gateway 1.1.1.1

nmcli con modify Проводное\ подключение\ 1 ipv6.method manual ipv6.addresses FD24:172::1/122
nmcli con modify Проводное\ подключение\ 1 ipv4.method manual ipv4.addresses 172.16.100.1/26

nmcli con modify Проводное\ подключение\ 2 ipv6.method manual ipv6.addresses 2024:4::1/64
nmcli con modify Проводное\ подключение\ 2 ipv6.gateway 2024:4::2
nmcli con modify Проводное\ подключение\ 2 ipv4.method manual ipv4.addresses 4.4.4.1/30



