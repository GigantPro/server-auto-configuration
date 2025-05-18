#!/bin/sh
set -e

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"

# 1) Обновляем репозитории и ставим пакеты из списка
apt update && apt upgrade -y
xargs apt install -y < "$SCRIPT_DIR"/dependencies.txt

# 2) Symlink для fd (fdfind → fd)
if command -v fdfind >/dev/null 2>&1; then
  ln -sf "$(command -v fdfind)" /usr/local/bin/fd
fi

# 3) Если fastfetch по-старому не появился — ставим из GitHub
if ! command -v fastfetch >/dev/null 2>&1; then
  echo "👉 fastfetch не найден — устанавливаем из GitHub…"

  # Берём последний тег из API
  latest=$(wget -qO- \
    https://api.github.com/repos/fastfetch-cli/fastfetch/releases/latest \
    | grep -Po '"tag_name": "\K.*?(?=")')

  # Определяем архитектуру и мэппим на имена релиза
  arch=$(dpkg --print-architecture)
  case "$arch" in
    amd64)   mapped="amd64"    ;;  # fastfetch-linux-amd64.deb :contentReference[oaicite:0]{index=0}
    arm64)   mapped="aarch64"  ;;  # fastfetch-linux-aarch64.deb :contentReference[oaicite:1]{index=1}
    armhf)   mapped="armv7l"   ;;
    armel)   mapped="armv6l"   ;;
    ppc64el) mapped="ppc64le"  ;;
    riscv64) mapped="riscv64"  ;;
    s390x)   mapped="s390x"    ;;
    *)       mapped="$arch"    ;;
  esac

  asset="fastfetch-linux-${mapped}.deb"
  url="https://github.com/fastfetch-cli/fastfetch/releases/download/${latest}/${asset}"
  tmp="/tmp/${asset}"

  echo "   Скачиваем ${asset}…"
  if ! wget -qO "$tmp" "$url"; then
    echo "❌ Не удалось скачать $url"
    exit 1
  fi

  echo "   Устанавливаем ${asset}…"
  dpkg -i "$tmp" || apt -f install -y
  rm -f "$tmp"
fi
