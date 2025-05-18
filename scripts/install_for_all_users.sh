#!/bin/sh
set -e

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
. "$SCRIPT_DIR"/common.sh

echo "👉 Копируем конфиги в /etc/skel для новых пользователей"
copy_configs /etc/skel

echo "👉 Применяем конфиги ко всем существующим пользователям:"
for home in /home/*; do
  [ -d "$home" ] || continue
  user="$(basename "$home")"
  echo "   • $user"
  copy_configs "$home"
  chsh -s "$(command -v zsh)" "$user"
  chown -R "$user":"$user" "$home"
done

echo "✅ Конфигурация развернута для всех пользователей."
