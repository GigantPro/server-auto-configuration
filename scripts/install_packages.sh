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

# 3) Устанавливаем fastfetch из GitHub, если он не появился в системе
if ! command -v fastfetch >/dev/null 2>&1; then
  echo "👉 fastfetch не найден в репозиториях – устанавливаем из GitHub…"
  # вытаскиваем тег последнего релиза, например "2.41.0"
  latest=$(wget -qO- \
    https://api.github.com/repos/fastfetch-cli/fastfetch/releases/latest \
    | grep -Po '"tag_name": "\K.*?(?=")')
  # архитектура, например "amd64" → совпадает с fastfetch-linux-amd64
  arch=$(dpkg --print-architecture)
  asset_dir="fastfetch-linux-${arch}"
  asset="fastfetch-linux-${arch}.deb"
  url="https://github.com/fastfetch-cli/fastfetch/releases/download/${latest}/${asset_dir}/${asset}"
  tmp="/tmp/${asset}"
  # скачиваем и устанавливаем
  echo "   Скачиваем ${asset}…"
  wget -qO "$tmp" "$url" || { echo "❌ Не удалось скачать $url"; exit 1; }
  echo "   Устанавливаем $asset…"
  dpkg -i "$tmp" || apt -f install -y
  rm -f "$tmp"
fi
