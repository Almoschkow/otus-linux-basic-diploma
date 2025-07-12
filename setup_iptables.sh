#!/bin/bash

# Требует: iptables-persistent для автозагрузки правил

set -e

# Проверка наличия iptables-persistent
if ! dpkg -s iptables-persistent &>/dev/null; then
  echo "ERROR: Пакет iptables-persistent не установлен."
  echo "Установите его командой: sudo apt install iptables-persistent"
  exit 1
fi

ROLE="$1"
if [ -z "$ROLE" ]; then
  echo "Использование: $0 {nginx|apache|mysql|monitoring|elk|reset|restore}"
  exit 1
fi

# Путь для резервного копирования
BACKUP_DIR="/etc/iptables"
BACKUP_FILE="$BACKUP_DIR/rules.v4.bak.$(date +%F-%H%M%S)"
mkdir -p "$BACKUP_DIR"

# Откат к последнему бэкапу
if [ "$ROLE" = "restore" ]; then
  LATEST_BAK=$(ls -1t $BACKUP_DIR/rules.v4.bak.* 2>/dev/null | head -n1)
  if [ -z "$LATEST_BAK" ]; then
    echo "ERROR: Нет резервных копий для восстановления."
    exit 1
  fi
  iptables-restore < "$LATEST_BAK"
  echo "DONE: Восстановлены правила из $LATEST_BAK"
  exit 0
fi

# Сброс всех правил
if [ "$ROLE" = "reset" ]; then
  iptables -F
  iptables -X
  iptables -t nat -F
  iptables -t nat -X
  iptables -P INPUT ACCEPT
  iptables -P OUTPUT ACCEPT
  echo "DONE: Все правила iptables сброшены и политики по умолчанию восстановлены"
  exit 0
fi

# Резервное копирование текущих правил
iptables-save > "$BACKUP_FILE"
echo "DONE: Текущие правила сохранены в $BACKUP_FILE"

# --- Базовые политики ---
iptables -P INPUT DROP
iptables -P OUTPUT ACCEPT

# --- Базовые разрешения ---
# Loopback
iptables -C INPUT -i lo -j ACCEPT 2>/dev/null || \
iptables -A INPUT -i lo -j ACCEPT -m comment --comment "Loopback (localhost)"
iptables -C OUTPUT -o lo -j ACCEPT 2>/dev/null || \
iptables -A OUTPUT -o lo -j ACCEPT -m comment --comment "Loopback (localhost)"

# ESTABLISHED,RELATED
iptables -C INPUT -m conntrack --ctstate ESTABLISHED,RELATED -j ACCEPT 2>/dev/null || \
iptables -A INPUT -m conntrack --ctstate ESTABLISHED,RELATED -j ACCEPT -m comment --comment "ESTABLISHED,RELATED"
iptables -C OUTPUT -m conntrack --ctstate ESTABLISHED,RELATED -j ACCEPT 2>/dev/null || \
iptables -A OUTPUT -m conntrack --ctstate ESTABLISHED,RELATED -j ACCEPT -m comment --comment "ESTABLISHED,RELATED"

# SSH
iptables -C INPUT -p tcp --dport 22 -j ACCEPT 2>/dev/null || \
iptables -A INPUT -p tcp --dport 22 -j ACCEPT -m comment --comment "SSH (администрирование и git, порт 22)"

# HTTPS и HTTP
iptables -C OUTPUT -p tcp --dport 443 -j ACCEPT 2>/dev/null || \
iptables -A OUTPUT -p tcp --dport 443 -j ACCEPT -m comment --comment "HTTPS (порт 443)"
iptables -C OUTPUT -p tcp --dport 80 -j ACCEPT 2>/dev/null || \
iptables -A OUTPUT -p tcp --dport 80 -j ACCEPT -m comment --comment "HTTP (порт 80)"

# DNS
iptables -C OUTPUT -p udp --dport 53 -j ACCEPT 2>/dev/null || \
iptables -A OUTPUT -p udp --dport 53 -j ACCEPT -m comment --comment "DNS-запросы (UDP 53)"
iptables -C OUTPUT -p tcp --dport 53 -j ACCEPT 2>/dev/null || \
iptables -A OUTPUT -p tcp --dport 53 -j ACCEPT -m comment --comment "DNS-запросы (TCP 53)"

# --- Разрешения по ролям ---
case "$ROLE" in
  nginx)
    iptables -C INPUT -p tcp --dport 80 -j ACCEPT 2>/dev/null || \
    iptables -A INPUT -p tcp --dport 80 -j ACCEPT -m comment --comment "HTTP (nginx, порт 80)"
    iptables -C INPUT -p tcp --dport 9100 -j ACCEPT 2>/dev/null || \
    iptables -A INPUT -p tcp --dport 9100 -j ACCEPT -m comment --comment "node-exporter (порт 9100)"
    iptables -C OUTPUT -p tcp --dport 5400 -j ACCEPT 2>/dev/null || \
    iptables -A OUTPUT -p tcp --dport 5400 -j ACCEPT -m comment --comment "Filebeat -> Logstash (порт 5400)"
    ;;
  apache)
    iptables -C INPUT -p tcp --dport 80 -j ACCEPT 2>/dev/null || \
    iptables -A INPUT -p tcp --dport 80 -j ACCEPT -m comment --comment "HTTP (Apache, порт 80)"
    iptables -C INPUT -p tcp --dport 9100 -j ACCEPT 2>/dev/null || \
    iptables -A INPUT -p tcp --dport 9100 -j ACCEPT -m comment --comment "node-exporter (порт 9100)"
    ;;
  mysql)
    iptables -C INPUT -p tcp --dport 3306 -j ACCEPT 2>/dev/null || \
    iptables -A INPUT -p tcp --dport 3306 -j ACCEPT -m comment --comment "MySQL (порт 3306)"
    ;;
  monitoring)
    iptables -C INPUT -p tcp --dport 9090 -j ACCEPT 2>/dev/null || \
    iptables -A INPUT -p tcp --dport 9090 -j ACCEPT -m comment --comment "Prometheus (порт 9090)"
    iptables -C INPUT -p tcp --dport 3000 -j ACCEPT 2>/dev/null || \
    iptables -A INPUT -p tcp --dport 3000 -j ACCEPT -m comment --comment "Grafana (порт 3000)"
    ;;
  elk)
    iptables -C INPUT -p tcp --dport 9200 -j ACCEPT 2>/dev/null || \
    iptables -A INPUT -p tcp --dport 9200 -j ACCEPT -m comment --comment "Elasticsearch (порт 9200)"
    iptables -C INPUT -p tcp --dport 5601 -j ACCEPT 2>/dev/null || \
    iptables -A INPUT -p tcp --dport 5601 -j ACCEPT -m comment --comment "Kibana (порт 5601)"
    iptables -C INPUT -p tcp --dport 5400 -j ACCEPT 2>/dev/null || \
    iptables -A INPUT -p tcp --dport 5400 -j ACCEPT -m comment --comment "Logstash (порт 5400)"
    ;;
  *)
    echo "Неизвестная роль: $ROLE"
    echo "Использование: $0 {nginx|apache|mysql|monitoring|elk|reset|restore}"
    exit 1
    ;;
esac

echo "DONE: iptables правила применены для роли $ROLE"

# --- Сохранение правил ---
iptables-save > /etc/iptables/rules.v4
echo "DONE: Текущие правила сохранены в /etc/iptables/rules.v4 для автозагрузки"