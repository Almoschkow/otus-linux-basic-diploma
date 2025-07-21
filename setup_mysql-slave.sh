#!/bin/bash
set -e

TEST_DB="test_repl"                     
REPL_USER="repluser"                    
REPL_PASSWORD="replpass"                
MASTER_HOST="192.168.68.58"             
DUMP_FILE="/tmp/${TEST_DB}_init.sql"    
REPL_INFO_FILE="/tmp/repl_info.txt"     
MYSQL_CNF="/etc/mysql/mysql.conf.d/mysqld.cnf"

# Проверка установки mysql-server-8.0
if ! dpkg -s mysql-server-8.0 &>/dev/null; then
    echo "ERROR: Установите mysql-server-8.0"
    exit 1
fi

# Создаем резервную копию оригинального файла
if [ ! -f "$MYSQL_CNF.bak" ]; then
    sudo cp "$MYSQL_CNF" "$MYSQL_CNF.bak"
    echo "DONE: Резервная копия создана: $MYSQL_CNF.bak"
else
    echo "Резервная копия уже существует"
fi

# Чистим старые параметры репликации в конфиге
sudo sed -i '/^\s*bind-address\s*=.*$/d' "$MYSQL_CNF"
sudo sed -i '/^\s*server-id\s*=.*$/d' "$MYSQL_CNF"
sudo sed -i '/^\s*relay-log\s*=.*$/d' "$MYSQL_CNF"
sudo sed -i '/^\s*log_bin\s*=.*$/d' "$MYSQL_CNF"
sudo sed -i '/^\s*binlog_ignore_db\s*=.*$/d' "$MYSQL_CNF"

# Добавляем новые параметры в конфигурацию
sudo tee -a "$MYSQL_CNF" >/dev/null <<EOF

bind-address = 0.0.0.0        # Слушать все интерфейсы
server-id = 2                 # Уникальный server-id (отличный от master)
relay-log = mysql-relay-bin   # Локальный relay-log файла slave

EOF

sudo systemctl restart mysql

# Стоп реплику, считываем dump
mysql -e "STOP SLAVE;" || true
mysql < "$DUMP_FILE"

# Получаем параметры master log
source "$REPL_INFO_FILE"
if [[ -z "$MASTER_LOG_FILE" || -z "$MASTER_LOG_POS" ]]; then
    echo "ERROR: Не найдены MASTER_LOG_FILE или MASTER_LOG_POS"
    exit 1
fi

# Настраиваем репликацию по Log/pos
mysql -e "
CHANGE MASTER TO
  MASTER_HOST='$MASTER_HOST',
  MASTER_USER='$REPL_USER',
  MASTER_PASSWORD='$REPL_PASSWORD',
  MASTER_LOG_FILE='$MASTER_LOG_FILE',
  MASTER_LOG_POS=$MASTER_LOG_POS;
START SLAVE;
"
sleep 5

# Чек статуса репликации
SLAVE_IO=$(mysql -Nse "SHOW SLAVE STATUS\G" | grep 'Slave_IO_Running:' | awk '{print $2}')
SLAVE_SQL=$(mysql -Nse "SHOW SLAVE STATUS\G" | grep 'Slave_SQL_Running:' | awk '{print $2}')
LAST_ERROR=$(mysql -Nse "SHOW SLAVE STATUS\G" | grep 'Last_SQL_Error:' | cut -d: -f2-)

if [[ "$SLAVE_IO" == "Yes" && "$SLAVE_SQL" == "Yes" ]]; then
    echo "DONE: Репликация запущена успешно"
else
    echo "ERROR: Репликация не стартовала"
    echo "$LAST_ERROR"
    echo "Статус репликации:"
    mysql -e "SHOW SLAVE STATUS\G"
    exit 1
fi

echo "DONE: Скрипт завершен. Проверка успешной работы репликации: Insert данных внутрь тестовой таблицы на Master"