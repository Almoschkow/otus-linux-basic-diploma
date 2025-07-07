#!/bin/bash

IFACE="enp0s3"
STATIC_IP="192.168.68.57/22"
GATEWAY="192.168.68.1"
DNS1="8.8.8.8"
DNS2="1.1.1.1"
NETPLAN_FILE="/etc/netplan/01-netcfg.yaml"

echo "Создание Netplan-конфига для nginx"
sudo tee $NETPLAN_FILE > /dev/null <<EOF
network:                # Корневой блок настройки сети
  version: 2            # Версия формата конфигурационного файла netplan (на данный момент используется 2)
  renderer: networkd    # Используем systemd-networkd для применения настроек сети (альтернативный вариант — NetworkManager)
  ethernets:            # Определяем настройки для Ethernet-интерфейсов
    $IFACE:             # Имя сетевого интерфейса, например enp0s3 (переменная в скрипте)
      dhcp4: no         # Отключаем автоматическое получение IPv4 адреса через DHCP
      addresses: [$STATIC_IP]  # Указываем статический IPv4 адрес с маской подсети (например 192.168.68.57/22)
      gateway4: $GATEWAY       # Задаем шлюз по умолчанию для IPv4 (например 192.168.68.1)
      nameservers:             # Конфигурация DNS-серверов
        addresses: [$DNS1, $DNS2]  # IP адреса DNS серверов (например 8.8.8.8, 1.1.1.1)
EOF

# Отключаем автоматическую настройку сети через cloud-init,
# чтобы netplan не перезаписывал наши статические настройки.
# Создаем директорию, если ее нет, и создаем файл с конфигурацией,
# которая отключает сетевую конфигурацию cloud-init.
sudo mkdir -p /etc/cloud/cloud.cfg.d
echo "network: {config: disabled}" | sudo tee /etc/cloud/cloud.cfg.d/99-disable-network-config.cfg > /dev/null

sudo netplan apply

echo "IP настроен:"
ip a show $IFACE | grep inet