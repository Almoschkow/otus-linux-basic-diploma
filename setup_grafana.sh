#!/bin/bash

set -e

echo "Настройка systemd для Grafana..."
sudo systemctl daemon-reload
sudo systemctl enable grafana-server
sudo systemctl start grafana-server
sleep 5  # Небольшая пауза, чтобы сервис точно поднялся

# Определяем IP текущей машины
# HOST_IP=$(ip -o -4 addr show scope global | awk '{print $4}' | cut -d/ -f1 | head -n1)

echo "Настройка источника данных Prometheus..."
curl -s -X POST http://admin:admin@localhost:3000/api/datasources \
  -H "Content-Type: application/json" \
  -d '{
    "name": "Prometheus",
    "type": "prometheus",
    "access": "proxy",
    "url": "http://localhost:9090",
    "basicAuth": false
  }' > /dev/null || echo "Источник данных уже существует или возникла ошибка."

# echo "Импорт стандартного дашборда Node Exporter (ID 11074)..."
# curl -s -X POST http://admin:admin@localhost:3000/api/dashboards/import \
#   -H "Content-Type: application/json" \
#   -d '{
#     "dashboard": {
#       "id": 11074
#     },
#     "overwrite": true,
#     "inputs": [
#       {
#         "name": "DS_PROMETHEUS",
#         "type": "datasource",
#         "pluginId": "prometheus",
#         "value": "Prometheus"
#       }
#     ]
#   }' > /dev/null || echo "Дашборд уже существует или возникла ошибка при импорте."

echo ""
echo "IP адрес текущей машины (monitoring): 192.168.56.106"
echo ""
echo "Grafana запущена: http://192.168.56.106:3000"
echo "Логин: admin / Пароль: admin (сменить при первом входе)"
echo "Дашборд node_exporter (ID 11074) импортирован. Проверь в интерфейсе Grafana!"
