#!/bin/sh
set -e

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
chmod +x "$SCRIPT_DIR"/scripts/*.sh

echo "👉 Устанавливаем пакеты…"
"$SCRIPT_DIR"/scripts/install_packages.sh

echo "👉 Настраиваем SSH…"
"$SCRIPT_DIR"/scripts/configure_ssh.sh
echo "✅ SSH настроен."

echo "👉 Устанавливаем и настраиваем MOTD…"
"$SCRIPT_DIR"/scripts/update_motd.sh
echo "✅ MOTD установлен."

echo "👉 Применяем конфигурацию для вашей учётки…"
"$SCRIPT_DIR"/scripts/install_for_current_user.sh
echo "✅ Базовая настройка завершена."
