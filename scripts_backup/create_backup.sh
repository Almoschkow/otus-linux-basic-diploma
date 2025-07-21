#!/bin/bash

set -e

# Переменные
BACKUP_DIR="/var/backups/mysql"
DATE=$(date +%F_%H-%M-%S)
TEST_DB="test_repl"
REPL_INFO_FILE="/tmp/repl_info.txt"
ARCHIVE_NAME="${TEST_DB}_backup_${DATE}.tar.gz"
GIT_REPO_DIR="/home/amoshkov/otus-linux-basic-diploma"
GIT_BACKUPS_DIR="$GIT_REPO_DIR/backups"

# Создаем директорию для бэкапа
mkdir -p "$BACKUP_DIR"
TMP_DIR=$(mktemp -d)

echo "Создаем потабличный дамп базы $TEST_DB"

# Получаем список таблиц из базы
TABLES=$(mysql -N -e "SHOW TABLES FROM $TEST_DB;")
if [[ -z "$TABLES" ]]; then
    echo "ERROR: Нет таблиц в базе $TEST_DB"
    exit 1
fi

for TABLE in $TABLES; do
  echo "Дампим таблицу $TABLE"
  mysqldump --skip-lock-tables --single-transaction --quick --lock-tables=false "$TEST_DB" "$TABLE" > "$TMP_DIR/${TABLE}.sql"
done

# Получаем текущую позицию бинарного лога для восстановления репликации
MASTER_LOG_FILE=$(mysql -e "SHOW SLAVE STATUS\G" | grep Relay_Master_Log_File | awk '{print $2}')
MASTER_LOG_POS=$(mysql -e "SHOW SLAVE STATUS\G" | grep Exec_Master_Log_Pos | awk '{print $2}')

echo "Записываем позицию бинарного лога в файл"
cat > "$TMP_DIR/repl_position.txt" <<EOF
MASTER_LOG_FILE=$MASTER_LOG_FILE
MASTER_LOG_POS=$MASTER_LOG_POS
EOF

# Архивируем дампы и файл с позицией
echo "Архивируем бэкап"
tar czf "$BACKUP_DIR/$ARCHIVE_NAME" -C "$TMP_DIR" .

# Копируем архив в git-репозиторий
mkdir -p "$GIT_BACKUPS_DIR"
cp "$BACKUP_DIR/$ARCHIVE_NAME" "$GIT_BACKUPS_DIR/"
cp "$TMP_DIR/repl_position.txt" "$GIT_BACKUPS_DIR/repl_position_${DATE}.txt"

# Удаляем временную папку
rm -rf "$TMP_DIR"

echo "DONE: Бекап базы $TEST_DB создан: $BACKUP_DIR/$ARCHIVE_NAME"
echo "Позиция бинарного лога:"
echo "MASTER_LOG_FILE=$MASTER_LOG_FILE"
echo "MASTER_LOG_POS=$MASTER_LOG_POS"

# Гит блок
cd "$GIT_REPO_DIR" || { echo "ERROR: Не могу перейти в директорию репозитория"; exit 1; }
git add "backups/$ARCHIVE_NAME" "backups/repl_position_${DATE}.txt"
git commit -m "Backup $TEST_DB on $DATE"
git push origin main

echo "DONE: Бекап отправлен в git-репозиторий ($GIT_REPO_DIR/backups/)"