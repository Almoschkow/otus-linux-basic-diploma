#!/bin/bash

set -e # прерываем при ошибке

echo "Проверка установки nginx"
if ! dpkg -s nginx &>/dev/null; then # &> stout и stderr сбрасываем "вникуда"
  echo "ERROR: Пакет nginx не установлен. Установите его через: sudo apt install nginx"
  exit 1
fi

# Путь к конфигурационному файлу nginx для балансировщика
CONF_AVAILABLE="/etc/nginx/sites-available/load_balancer"
CONF_ENABLED="/etc/nginx/sites-enabled/load_balancer"

echo "Создаём конфигурацию nginx для балансировщика"

# Создаём конфигурационный файл с настройками балансировщика
cat > "$CONF_AVAILABLE" << EOF
upstream backend {
    server 192.168.68.55;  # apache1
    server 192.168.68.57;  # apache2
}

server {
    listen 80;             # Прослушиваем порт 80
    server_name _;         # Обработка запросов на любой домен

    location / {
        proxy_pass http://backend;                     # Передаём запросы на upstream backend
        proxy_set_header Host \$host;                  # Передача оригинального заголовка Host
        proxy_set_header X-Real-IP \$remote_addr;      # Передача реального IP клиента
        proxy_set_header X-Forwarded-For \$proxy_add_x_forwarded_for; # Передача цепочки IP прокси
    }
}
EOF

echo "DONE: Конфигурация создана: $CONF_AVAILABLE"

# Проверяем, есть ли уже символическая ссылка в sites-enabled
if [ ! -L "$CONF_ENABLED" ]; then
    echo "Создаём символическую ссылку для активации конфигурации"
    ln -s "$CONF_AVAILABLE" "$CONF_ENABLED"
    echo "DONE: Символическая ссылка создана: $CONF_ENABLED -> $CONF_AVAILABLE"
else
    echo "Символическая ссылка уже существует: $CONF_ENABLED"
fi

echo "Проверяем синтаксис конфигурации nginx"
nginx -t

if [ $? -ne 0 ]; then
    echo "ERROR: Ошибка в конфигурации nginx! Проверьте файл $CONF_AVAILABLE"
    exit 1
fi

echo "Перезапускаем nginx для применения новой конфигурации"
systemctl reload nginx 

echo "DONE: nginx успешно перезапущен и готов к работе."
