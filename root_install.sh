#!/bin/sh
set -e

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"

# Делаем все скрипты исполняемыми
chmod +x "$SCRIPT_DIR"/scripts/*.sh

# Устанавливаем базовую конфигурацию для текущего пользователя
"$SCRIPT_DIR"/scripts/install_packages.sh
"$SCRIPT_DIR"/scripts/configure_ssh.sh
"$SCRIPT_DIR"/scripts/update_motd.sh
"$SCRIPT_DIR"/scripts/install_for_current_user.sh

echo "✅ Базовая настройка завершена для вашей учётки."
