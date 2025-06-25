#!/bin/bash

IFACE="enp0s3"
STATIC_IP="192.168.68.57/22"
GATEWAY="192.168.68.1"
DNS1="8.8.8.8"
DNS2="1.1.1.1"
NETPLAN_FILE="/etc/netplan/01-netcfg.yaml"

echo "[+] Создание Netplan-конфига для nginx"
sudo tee $NETPLAN_FILE > /dev/null <<EOL
network:
  version: 2
  renderer: networkd
  ethernets:
    $IFACE:
      dhcp4: no
      addresses: [$STATIC_IP]
      gateway4: $GATEWAY
      nameservers:
        addresses: [$DNS1, $DNS2]
EOL

sudo netplan apply

echo "[✓] IP настроен:"
ip a show $IFACE | grep inet