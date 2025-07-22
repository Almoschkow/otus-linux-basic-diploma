#!/bin/bash

set -e

ROLE="$1"
if [[ -z "$ROLE" ]]; then
  echo "Usage: $0 {nginx|apache1|apache2|mysql-master|mysql-slave|monitoring|elk}"
  exit 1
fi

echo "Установка для роли: $ROLE"

case "$ROLE" in
  nginx)
    ./scripts_netplan/set_ip_nginx.sh
    ./setup_nginx.sh
    ./setup_iptables.sh nginx
    ./setup_node_exporter.sh  
    ./setup_filebeat.sh
    ;;
  apache1)
    ./scripts_netplan/set_ip_apache1.sh
    ./setup_apache1.sh
    ./setup_iptables.sh apache
    ./setup_node_exporter.sh
    ;;
  apache2)
    ./scripts_netplan/set_ip_apache2.sh
    ./setup_apache2.sh
    ./setup_iptables.sh apache
    ./setup_node_exporter.sh
    ;;
  mysql-master)
    ./scripts_netplan/set_ip_mysql_master.sh
    ./setup_mysql-master.sh
    ./setup_iptables.sh mysql
    ;;
  mysql-slave)
    ./scripts_netplan/set_ip_mysql_slave.sh
    ./setup_mysql-slave.sh
    ./setup_iptables.sh mysql
    ;;
  monitoring)
    ./scripts_netplan/set_ip_monitoring.sh
    ./setup_prometheus.sh
    ./setup_grafana.sh
    ./setup_iptables.sh monitoring
    ;;
  elk)
    ./scripts_netplan/set_ip_elk.sh
    ./setup_elk.sh
    ./setup_iptables.sh elk
    ;;
  *)
    echo "ERROR: Неизвестная роль: $ROLE"
    exit 1
    ;;
esac

echo "DONE: Конфигурации для роли $ROLE установлены успешно"