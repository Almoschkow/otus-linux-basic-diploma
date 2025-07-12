#!/bin/bash

set -e  # Прерываем скрипт при ошибке

echo "Проверка установки apache2"
if ! dpkg -s apache2 &>/dev/null; then
  echo "ERROR: Пакет apache2 не установлен. Установите его через: sudo apt install apache2"
  exit 1
fi

# Включаем автозапуск и запускаем сервис
systemctl enable apache2
systemctl start apache2

# Создаём простой index.html с указанием имени сервера
echo "Создаём тестовую страницу"
cat > /var/www/html/index.html <<EOF
<html>
  <head>
    <title>Apache Web Server</title>
  </head>
  <body>
    <h1>Hello from Apache2</h1>
  </body>
</html>
EOF

# Открываем порт 80 в iptables
# iptables -C INPUT -p tcp --dport 80 -j ACCEPT 2>/dev/null || iptables -A INPUT -p tcp --dport 80 -j ACCEPT

echo "DONE: Apache установлен, страница создана, порт 80 открыт."