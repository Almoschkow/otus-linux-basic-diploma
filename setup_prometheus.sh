#!/bin/bash
set -e  # Прерываем выполнение при ошибке

echo "[INFO] Установка и настройка Prometheus..."

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

echo "[INFO] Перезапуск Prometheus с новой конфигурацией..."
sudo systemctl restart prometheus
sudo systemctl enable prometheus

# Определение IP-адреса для справочного вывода
HOST_IP=$(ip -o -4 addr show scope global | awk '{print $4}' | cut -d/ -f1 | head -n1)

echo "[OK] Prometheus настроен и запущен"
echo "Интерфейс доступен по адресу: http://$HOST_IP:9090"
echo "Проверьте статус: sudo systemctl status prometheus"