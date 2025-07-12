#!/bin/bash

# Переменные
REPL_USER="repluser"
REPL_PASSWORD="replpass"
TEST_DB="test_repl"
DATE=$(date +"%Y-%m-%d_%H-%M-%S")
TMP_DIR="/tmp/${TEST_DB}_backup_${DATE}"
ARCHIVE_NAME="${TEST_DB}_backup_${DATE}.tar.gz"
POSITION_FILE="repl_position.txt"
GIT_REPO_DIR="/home/amoshkov/otus-linux-basic-diploma"
BACKUPS_DIR="backups"

echo "Создаём временную директорию для бэкапа: $TMP_DIR"
mkdir -p "$TMP_DIR"

echo "Делаем потабличный дамп базы данных '$TEST_DB' с помощью mysqldump --tab"
# Ключи:
# --tab=DIR  — сохраняет дампы каждой таблицы в отдельные файлы в указанной папке (структура: .sql и .txt для данных)
# --user, --password — аутентификация
mysqldump -u "$REPL_USER" -p"$REPL_PASSWORD" --tab="$TMP_DIR" "$TEST_DB"

echo "Получаем текущую позицию бинарного лога для репликации"
# Записываем имя текущего бинарного лога и позицию в файл repl_position.txt
mysql -u "$REPL_USER" -p"$REPL_PASSWORD" -e "SHOW MASTER STATUS\G" | grep -E "File|Position" | awk '{print $1 "=" $2}' > "$TMP_DIR/$POSITION_FILE"

echo "Создаём архив бэкапа: $ARCHIVE_NAME"
# Ключи tar:
# -c — создать архив
# -v — показать имена файлов при архивировании (verbose)
# -z — сжать архив с помощью gzip
# -f — указать имя файла архива
tar -czvf "$TMP_DIR/$ARCHIVE_NAME" -C "$TMP_DIR" .

echo "Копируем архив и файл позиции в папку backups репозитория"

mkdir -p "$GIT_REPO_DIR/$BACKUPS_DIR"
cp "$TMP_DIR/$ARCHIVE_NAME" "$GIT_REPO_DIR/$BACKUPS_DIR/"
cp "$TMP_DIR/$POSITION_FILE" "$GIT_REPO_DIR/$BACKUPS_DIR/"

echo "DONE: Резервная копия успешно создана в $GIT_REPO_DIR/$BACKUPS_DIR/"

# --- Блок для коммитов и пуша в git ---

#: <<'GITBLOCK'
#cd "$GIT_REPO_DIR" || { echo "[!] Ошибка: не могу перейти в директорию репозитория"; exit 1; }
#git add "$BACKUPS_DIR/$ARCHIVE_NAME" "$BACKUPS_DIR/$POSITION_FILE"
#git commit -m "Backup DB slave and replication position on $DATE"
#git push origin main
#GITBLOCK

echo "Скрипт завершён."