#!/bin/bash

set -e

echo "Проверка установки prometheus-node-exporter"
if ! dpkg -s prometheus-node-exporter &>/dev/null; then
  echo "ERROR: Пакет prometheus-node-exporter не установлен. Установите его через: sudo apt install prometheus-node-exporter"
  exit 1
fi

echo "Включаем и запускаем node_exporter как systemd-сервис"
sudo systemctl enable prometheus-node-exporter
sudo systemctl restart prometheus-node-exporter

echo "Проверка, слушает ли порт 9100"
if sudo ss -nltp | awk '$4 ~ /:9100$/'; then
  echo "DONE: Порт 9100 прослушивается"
else
  echo "ERROR: Порт 9100 не прослушивается. Проверьте журнал: sudo journalctl -u prometheus-node-exporter"
  exit 1
fi

# Получаем IP-адрес
HOST_IP=$(ip -o -4 addr show scope global | awk '{print $4}' | cut -d/ -f1 | head -n1)

echo "DONE: node_exporter успешно запущен!"
echo "Метрики доступны по адресу: http://${HOST_IP}:9100/metrics"