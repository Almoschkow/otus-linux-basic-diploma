#!/bin/bash

# Скрипт настройки Filebeat для отправки логов Nginx в Logstash

set -e # Прерываем скрипт при ошибке

echo "Проверка установки filebeat"
if ! dpkg -s filebeat &>/dev/null; then
  echo "Пакет filebeat не установлен. Установите его через: sudo apt install filebeat"
  exit 1
fi

# Определяем IP Logstash-хоста
LOGSTASH_IP="192.168.68.61"

# Проверяем наличие filebeat.yml
if [ ! -f /etc/filebeat/filebeat.yml ]; then
  echo "[!] Конфигурационный файл /etc/filebeat/filebeat.yml не найден."
  exit 1
fi

# Создаем резервную копию оригинального файла
cp /etc/filebeat/filebeat.yml /etc/filebeat/filebeat.yml.bak

# Обновим конфигурацию filebeat.yml
cat > /etc/filebeat/filebeat.yml <<EOF
filebeat.inputs:
- type: filestream
  paths:
    - /var/log/nginx/*.log
  enabled: true
  exclude_files: ['.gz$']
  prospector.scanner.exclude_files: ['.gz$']

filebeat.config.modules:
  path: \${path.config}/modules.d/*.yml
  reload.enabled: false

setup.template.settings:
  index.number_of_shards: 1

setup.kibana:

output.logstash:
  hosts: ["$LOGSTASH_IP:5400"]

processors:
  - add_host_metadata:
      when.not.contains.tags: forwarded
  - add_cloud_metadata: ~
  - add_docker_metadata: ~
  - add_kubernetes_metadata: ~
EOF

# Перезапускаем Filebeat
systemctl enable filebeat
systemctl restart filebeat
sleep 3

# Проверка
if systemctl is-active --quiet filebeat; then
  echo "[OK] Filebeat работает и отправляет логи на $LOGSTASH_IP:5400"
else
  echo "[!] Filebeat не запущен. Проверьте журнал: journalctl -u filebeat"
fi
