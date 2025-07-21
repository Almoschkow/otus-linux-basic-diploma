#!/bin/bash
set -e

# Основные переменные
REPL_USER="repluser"                
REPL_PASSWORD="replpass"            
SLAVE_HOST="192.168.68.59"          
SLAVE_USER="amoshkov"               
TEST_DB="test_repl"                 
REPL_INFO_FILE="/tmp/repl_info.txt"
DUMP_FILE="/tmp/${TEST_DB}_init.sql" 
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

#  Удаляем возможные старые конфигурационные строки из файла my.cnf
sudo sed -i '/^\s*bind-address\s*=.*$/d' "$MYSQL_CNF"
sudo sed -i '/^\s*server-id\s*=.*$/d' "$MYSQL_CNF"
sudo sed -i '/^\s*log_bin\s*=.*$/d' "$MYSQL_CNF"

# Добавляем новые настройки репликации в конфигурационный файл
sudo tee -a "$MYSQL_CNF" >/dev/null <<EOF

bind-address = 0.0.0.0        # Слушать все интерфейсы, чтобы slave мог подключаться
server-id = 1                 # Уникальный номер сервера в репликации
log_bin = mysql-bin           # Имя файла бинарных логов

EOF

sudo systemctl restart mysql

# Создаём пользователя репликации, тестовую базу и таблицу
mysql -e "CREATE USER IF NOT EXISTS '$REPL_USER'@'%' IDENTIFIED WITH mysql_native_password BY '$REPL_PASSWORD';"
mysql -e "GRANT REPLICATION SLAVE ON *.* TO '$REPL_USER'@'%';"
mysql -e "FLUSH PRIVILEGES;"
mysql -e "CREATE DATABASE IF NOT EXISTS $TEST_DB;"
mysql -e "USE $TEST_DB; CREATE TABLE IF NOT EXISTS test_table (id INT PRIMARY KEY AUTO_INCREMENT, msg VARCHAR(255));"
mysql -e "USE $TEST_DB; INSERT INTO test_table (msg) VALUES ('test') ON DUPLICATE KEY UPDATE msg=msg;"

# Создаём дамп базы с позицией бинлога для slave
mysqldump --single-transaction --databases "$TEST_DB" --master-data=2 > "$DUMP_FILE"

# Получаем текущий бинарный лог и позицию для настройки slave-сервера
MASTER_LOG_FILE=$(awk '/^-- CHANGE MASTER TO/ { for (i=1; i<=NF; i++) if ($i ~ /MASTER_LOG_FILE/) print $i }' "$DUMP_FILE" | cut -d"=" -f2 | tr -d "',;")
MASTER_LOG_POS=$(awk '/^-- CHANGE MASTER TO/ { for (i=1; i<=NF; i++) if ($i ~ /MASTER_LOG_POS/) print $i }' "$DUMP_FILE" | cut -d"=" -f2 | tr -d "',;")
echo "MASTER_LOG_FILE=$MASTER_LOG_FILE" > "$REPL_INFO_FILE"
echo "MASTER_LOG_POS=$MASTER_LOG_POS" >> "$REPL_INFO_FILE"

if [[ -z "$MASTER_LOG_FILE" || -z "$MASTER_LOG_POS" ]]; then
    echo "ERROR: Не удалось определить бинлог и/или позицию"
    exit 1
fi

# Проверка, что файл создан и содержит данные
if [[ ! -f "$REPL_INFO_FILE" ]]; then
  echo "ERROR: файл $REPL_INFO_FILE не создан"
  exit 1
fi

# Проверка, что переменные внутри файла непустые
source $REPL_INFO_FILE
if [[ -z "$MASTER_LOG_FILE" || -z "$MASTER_LOG_POS" ]]; then
  echo "ERROR: файл $REPL_INFO_FILE пустой или содержит неверные данные"
  exit 1
fi

# Копируем дамп и файл с параметрами на slave
scp "$DUMP_FILE" "$SLAVE_USER@$SLAVE_HOST:/tmp/"
scp "$REPL_INFO_FILE" "$SLAVE_USER@$SLAVE_HOST:/tmp/"

echo "DONE: Настройка master завершена, информация для slave записана в $REPL_INFO_FILE"