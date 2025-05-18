#!/bin/sh
set -e

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"

# 1) Обновляем репозитории и ставим зависимости из списка
apt update && apt upgrade -y
xargs apt install -y < "$SCRIPT_DIR"/dependencies.txt

# 2) Symlink для fd (если он установлен как fdfind)
if command -v fdfind >/dev/null 2>&1; then
  ln -sf "$(command -v fdfind)" /usr/local/bin/fd
fi

# 3) Устанавливаем fastfetch из GitHub, если нет пакета в системе
if ! command -v fastfetch >/dev/null 2>&1; then
  echo "👉 fastfetch не найден в репозиториях – устанавливаем из GitHub…"
  # Получаем последнюю версию
  latest=$(wget -qO- \
    https://api.github.com/repos/LinusDierheimer/fastfetch/releases/latest \
    | grep -Po '"tag_name": "\K.*?(?=")')
  arch=$(dpkg --print-architecture)
  pkg="fastfetch_${latest}_${arch}.deb"
  tmp="/tmp/$pkg"
  # Скачиваем и ставим
  wget -qO "$tmp" "https://github.com/LinusDierheimer/fastfetch/releases/download/${latest}/${pkg}"
  dpkg -i "$tmp"
  rm -f "$tmp"
fi
