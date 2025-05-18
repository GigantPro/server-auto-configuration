#!/bin/sh
set -e

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
. "$SCRIPT_DIR"/common.sh

# Целевая учётка: если через sudo — это SUDO_USER, иначе текущий
if [ -n "$SUDO_USER" ]; then
  user="$SUDO_USER"
else
  user="$(id -un)"
fi

# Домашняя папка
home="$(getent passwd "$user" | cut -d: -f6)"

echo "👉 Применяем конфигурацию для пользователя $user ($home)"
copy_configs "$home"

# Снова zsh
chsh -s "$(command -v zsh)" "$user"

# Права
chown -R "$user":"$user" "$home"
