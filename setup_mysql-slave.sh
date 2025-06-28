#!/bin/bash

# Основные переменные
MYSQL_ROOT_PASSWORD="rootpass"
REPL_USER="replica"
REPL_PASSWORD="replpass"
MASTER_HOST="192.168.68.58"
REPL_INFO_FILE="/tmp/repl_info.txt"
TEST_DB="test_repl"
TEST_TABLE="test_tabl"

#echo "Установка MySQL Server (Slave)..."
#sudo apt update && sudo apt install -y mysql-server

echo "Настройка /etc/mysql/mysql.conf.d/mysqld.cnf..."
sudo sed -i 's/^bind-address\s*=.*/bind-address = 0.0.0.0/' /etc/mysql/mysql.conf.d/mysqld.cnf

sudo tee -a /etc/mysql/mysql.conf.d/mysqld.cnf > /dev/null <<EOF

# Настройки для slave
server-id = 2
relay-log = /var/log/mysql/mysql-relay-bin.log
log_bin = /var/log/mysql/mysql-bin.log
binlog_do_db = $TEST_DB
EOF

echo "Перезапуск MySQL..."
sudo systemctl restart mysql

echo "Настройка root-пароля..."
sudo mysql -u root -p"$MYSQL_ROOT_PASSWORD"<<EOF
ALTER USER 'root'@'localhost' IDENTIFIED WITH mysql_native_password BY '$MYSQL_ROOT_PASSWORD';
FLUSH PRIVILEGES;
EOF

echo "Получение лог-файла и позиции с мастера..."
ssh -o StrictHostKeyChecking=no amoshkov@$MASTER_HOST "cat /home/amoshkov/repl_info.txt" > $REPL_INFO_FILE

LOG_FILE=$(grep 'File:' $REPL_INFO_FILE | awk '{print $2}')
LOG_POS=$(grep 'Position:' $REPL_INFO_FILE | awk '{print $2}')

echo "Получено:"
echo "  Лог-файл: $LOG_FILE"
echo "  Позиция:  $LOG_POS"

echo "Настройка SLAVE на подключение к MASTER..."
mysql -u root -p"$MYSQL_ROOT_PASSWORD" <<EOF
STOP SLAVE;
CHANGE MASTER TO
  MASTER_HOST='$MASTER_HOST',
  MASTER_USER='$REPL_USER',
  MASTER_PASSWORD='$REPL_PASSWORD',
  MASTER_LOG_FILE='$LOG_FILE',
  MASTER_LOG_POS=$LOG_POS;
START SLAVE;
EOF

echo "Проверка репликации..."
echo "SHOW SLAVE STATUS\G" | mysql -u root -p"$MYSQL_ROOT_PASSWORD" > /tmp/slave_status.txt

if grep -q "Slave_IO_Running: Yes" /tmp/slave_status.txt && grep -q "Slave_SQL_Running: Yes" /tmp/slave_status.txt; then
  echo "Репликация работает"
else
  echo "Репликация НЕ работает"
  cat /tmp/slave_status.txt
  exit 1
fi

echo "Проверка: выводим строки из таблицы '$TEST_DB.$TEST_TABLE'..."
mysql -u root -p"$MYSQL_ROOT_PASSWORD" -e "SELECT * FROM $TEST_DB.$TEST_TABLE;"
