#!/bin/bash

# Задаём основные переменные
MYSQL_ROOT_PASSWORD="rootpass"
REPL_USER="repluser"
REPL_PASSWORD="replpass"
REPL_INFO_FILE="/root/repl_info.txt"
TEST_DB="test_repl"
MYSQL_CNF="/etc/mysql/mysql.conf.d/mysqld.cnf"

echo "Настройка MySQL master..."

# Удаляем возможные старые конфигурационные строки из файла my.cnf,
# чтобы избежать дублирования и конфликтов при повторном запуске скрипта
sudo sed -i '/^bind-address/d' $MYSQL_CNF       # Удаляет строку bind-address (если есть)
sudo sed -i '/^server-id/d' $MYSQL_CNF          # Удаляет строку server-id
sudo sed -i '/^log_bin/d' $MYSQL_CNF            # Удаляет строку log_bin
sudo sed -i '/^binlog_do_db/d' $MYSQL_CNF       # Удаляет строку binlog_do_db

# Добавляем новые настройки репликации в конфигурационный файл
sudo tee -a $MYSQL_CNF > /dev/null <<EOF

bind-address = 0.0.0.0               # Разрешаем подключения к MySQL по всем интерфейсам
server-id = 1                        # Уникальный ID для мастера
log_bin = mysql-bin                 # Включаем бинарные логи
binlog_do_db = $TEST_DB             # Логируем изменения только для указанной базы
EOF

# Перезапускаем MySQL для применения изменений
sudo systemctl restart mysql

# Устанавливаем плагин аутентификации и пароль для root-пользователя
mysql -u root -p"$MYSQL_ROOT_PASSWORD" <<EOF
ALTER USER 'root'@'localhost' IDENTIFIED WITH mysql_native_password BY '$MYSQL_ROOT_PASSWORD';
FLUSH PRIVILEGES;
EOF

# Создаём пользователя для репликации, если ещё не создан
mysql -u root -p"$MYSQL_ROOT_PASSWORD" -e "
CREATE USER IF NOT EXISTS '$REPL_USER'@'%' IDENTIFIED WITH mysql_native_password BY '$REPL_PASSWORD';
GRANT REPLICATION SLAVE ON *.* TO '$REPL_USER'@'%';
FLUSH PRIVILEGES;
"

# Создаём тестовую базу данных и таблицу, если они не существуют
mysql -u root -p"$MYSQL_ROOT_PASSWORD" -e "
CREATE DATABASE IF NOT EXISTS $TEST_DB;
USE $TEST_DB;
CREATE TABLE IF NOT EXISTS test_table (
  id INT PRIMARY KEY AUTO_INCREMENT,
  msg VARCHAR(255)
);
INSERT INTO test_table (msg) VALUES ('test');
"

# Получаем текущий бинарный лог и позицию для настройки slave-сервера
MASTER_LOG_FILE=$(mysql -u root -p"$MYSQL_ROOT_PASSWORD" -e "SHOW MASTER STATUS\G" | grep File | awk '{print $2}')
MASTER_LOG_POS=$(mysql -u root -p"$MYSQL_ROOT_PASSWORD" -e "SHOW MASTER STATUS\G" | grep Position | awk '{print $2}')

# Сохраняем параметры репликации в файл, чтобы потом использовать на slave
echo "MASTER_LOG_FILE=$MASTER_LOG_FILE" > $REPL_INFO_FILE
echo "MASTER_LOG_POS=$MASTER_LOG_POS" >> $REPL_INFO_FILE

echo "Настройка master завершена, информация для slave записана в $REPL_INFO_FILE"

# Опционально: автоматическое копирование файла с master на slave

SLAVE_USER="amoshkov"                 # Имя пользователя на slave
SLAVE_HOST="192.168.68.59"            # IP-адрес slave
REMOTE_PATH="/home/$SLAVE_USER/"      # Куда копировать

echo "Копирование информации о репликации на slave ($SLAVE_HOST)..."
scp $REPL_INFO_FILE "$SLAVE_USER@$SLAVE_HOST:$REMOTE_PATH" && \
echo "repl_info.txt успешно скопирован на $SLAVE_HOST:$REMOTE_PATH" || \
echo "Ошибка при копировании файла на slave. Проверьте SSH доступ."
