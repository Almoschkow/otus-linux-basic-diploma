#!/bin/bash

set -e 
# Параметры
REPO_DIR="/home/amoshkov/otus-linux-basic-diploma"
BACKUPS_DIR="$REPO_DIR/backups"
DB_NAME="test_repl_final"
ARCHIVE_NAME="$1"

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