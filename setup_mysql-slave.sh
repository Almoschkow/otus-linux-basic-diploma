#!/bin/bash

# Настройки
REPL_USER="repluser"
REPL_PASSWORD="replpass"
REPL_INFO_FILE="/tmp/repl_info.txt"
MASTER_HOST="192.168.68.58"  # Замените на фактический IP master-сервера
MYSQL_CNF="/etc/mysql/mysql.conf.d/mysqld.cnf"

echo "[+] Настройка MySQL slave..."

# Удаляем старые настройки (если повторный запуск)
sudo sed -i '/^bind-address/d' $MYSQL_CNF
sudo sed -i '/^server-id/d' $MYSQL_CNF
sudo sed -i '/^relay-log/d' $MYSQL_CNF
sudo sed -i '/^log_bin/d' $MYSQL_CNF
sudo sed -i '/^binlog_do_db/d' $MYSQL_CNF
sudo sed -i '/^binlog_ignore_db/d' $MYSQL_CNF


# Добавляем новые параметры в конфигурацию
sudo tee -a $MYSQL_CNF > /dev/null <<EOF

bind-address = 0.0.0.0             # Принимаем подключения
server-id = 2                      # Уникальный ID для slave
relay-log = mysql-relay-bin        # Relay лог

EOF

# Перезапускаем MySQL
sudo systemctl restart mysql

# Считываем параметры из файла, полученного от master
if [[ ! -f "$REPL_INFO_FILE" ]]; then
  echo "[!] Файл $REPL_INFO_FILE не найден. Убедитесь, что он скопирован со master."
  exit 1
fi

# Импортируем значения лог-файла и позиции
source $REPL_INFO_FILE

# Настраиваем параметры подключения к мастеру
mysql -u root -e "
STOP SLAVE;
CHANGE MASTER TO
  MASTER_HOST='$MASTER_HOST',
  MASTER_USER='$REPL_USER',
  MASTER_PASSWORD='$REPL_PASSWORD',
  MASTER_LOG_FILE='$MASTER_LOG_FILE',
  MASTER_LOG_POS=$MASTER_LOG_POS;
START SLAVE;
"

# Проверка статуса репликации
SLAVE_IO=$(mysql -u root -e "SHOW SLAVE STATUS\G" | grep 'Slave_IO_Running:' | awk '{print $2}')
SLAVE_SQL=$(mysql -u root -e "SHOW SLAVE STATUS\G" | grep 'Slave_SQL_Running:' | awk '{print $2}')

if [[ "$SLAVE_IO" == "Yes" && "$SLAVE_SQL" == "Yes" ]]; then
  echo "[✓] Репликация настроена успешно. Slave_IO и Slave_SQL работают."
else
  echo "[!] Внимание: Репликация не работает должным образом."
  echo "    Slave_IO_Running: $SLAVE_IO"
  echo "    Slave_SQL_Running: $SLAVE_SQL"
  echo "Полный статус репликации:"
  mysql -u root -e "SHOW SLAVE STATUS\G"
fi
