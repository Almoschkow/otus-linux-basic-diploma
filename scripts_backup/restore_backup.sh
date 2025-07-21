#!/bin/bash

set -e

mysql -e "STOP REPLICA;"

# Параметры
REPO_DIR="/home/amoshkov/otus-linux-basic-diploma"
BACKUPS_DIR="$REPO_DIR/backups"
DB_NAME="test_repl"
ARCHIVE_NAME="$1"

# Остановка реплики
mysql -e "STOP REPLICA;"

# Пересоздание чисто DB
mysql -e "DROP DATABASE IF EXISTS $DB_NAME;"
mysql -e "CREATE DATABASE $DB_NAME;"

if [ -z "$ARCHIVE_NAME" ]; then
    echo "Использование: $0 <имя_архива_бэкапа.tar.gz>"
    echo "Пример: $0 test_repl_final_backup_2025-07-13_17-35-16.tar.gz"
    exit 1
fi

if [ ! -f "$BACKUPS_DIR/$ARCHIVE_NAME" ]; then
    echo "ERROR: Архив не найден: $BACKUPS_DIR/$ARCHIVE_NAME"
    exit 2
fi

TMP_RESTORE=$(mktemp -d)

echo "Распаковываем архив"
tar -xzf "$BACKUPS_DIR/$ARCHIVE_NAME" -C "$TMP_RESTORE"

echo "Восстанавливаем структуру и данные таблиц"
for sql in "$TMP_RESTORE"/*.sql; do
    echo "Восстановление: $(basename "$sql")"
    mysql "$DB_NAME" < "$sql"
done

for txt in "$TMP_RESTORE"/*.txt; do
    table=$(basename "$txt" .txt)
    # Пропускаем файлы с позицией репликации
    [[ "$table" == repl_position* ]] && continue
    echo "Импорт данных в таблицу: $table"
    mysqlimport --local "$DB_NAME" "$txt"
done

rm -rf "$TMP_RESTORE"
echo "DONE: Восстановление базы $DB_NAME завершено."

# Восстановление репликации
# Пути до файла позиций
REPL_POS_FILE="$TMP_RESTORE/repl_position.txt"

if [ -f "$REPL_POS_FILE" ]; then
    source "$REPL_POS_FILE"
    echo "Настраиваем репликацию на $MASTER_LOG_FILE:$MASTER_LOG_POS"

    mysql -e "
    CHANGE MASTER TO
      MASTER_HOST='192.168.68.58',
      MASTER_USER='repluser',
      MASTER_PASSWORD='replpass',
      MASTER_LOG_FILE='$MASTER_LOG_FILE',
      MASTER_LOG_POS=$MASTER_LOG_POS;
    START REPLICA;"
fi

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
