#!/bin/sh
set -e

# корень папки scripts
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"

# обновляем систему и ставим пакеты из dependencies.txt
apt update && apt upgrade -y
xargs apt install -y < "$SCRIPT_DIR"/dependencies.txt

# symlink для fd (если установлен как fdfind)
if command -v fdfind >/dev/null 2>&1; then
  ln -sf "$(command -v fdfind)" /usr/local/bin/fd
fi
