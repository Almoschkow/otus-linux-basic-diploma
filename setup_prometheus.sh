#!/bin/bash
set -e  # Прерываем выполнение при ошибке

echo "Проверка установки prometheus"
if ! dpkg -s prometheus &>/dev/null; then
  echo "ERROR: Пакет prometheus не установлен. Установите его через: sudo apt install prometheus"
  exit 1
fi

echo "Установка и настройка Prometheus"

# Создаем резервную копию оригинального файла
cp /etc/prometheus/prometheus.yml /etc/prometheus/prometheus.yml.bak

# Создаём базовую конфигурацию Prometheus
sudo tee /etc/prometheus/prometheus.yml > /dev/null <<EOF
global:
  scrape_interval: 15s
  evaluation_interval: 15s

scrape_configs:
  - job_name: 'node_exporters'
    static_configs:
      - targets:
          - '192.168.56.102:9100'  # nginx
          - '192.168.56.103:9100'  # apache1
          - '192.168.56.104:9100'  # apache2
EOF

echo "Перезапуск Prometheus с новой конфигурацией"
sudo systemctl restart prometheus
sudo systemctl enable prometheus

# Определение IP-адреса для справочного вывода
HOST_IP=$(ip -o -4 addr show scope global | awk '{print $4}' | cut -d/ -f1 | head -n1)

echo "DONE: Prometheus настроен и запущен"
echo "Интерфейс доступен по адресу: http://$HOST_IP:9090"
echo "Проверьте статус: sudo systemctl status prometheus"