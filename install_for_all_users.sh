#!/bin/sh

# -------------------------------
# server-auto-configuration v2
# -------------------------------

set -e

# 1) Определяем папку скрипта
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"

# 2) Обновляем систему и ставим зависимости
apt update && apt upgrade -y
apt install -y \
    htop ranger fzf zsh neofetch neovim ibus procps exa highlight \
    zoxide git tmux wget nala python3 python3-pip python3-venv fd-find \
    kitty-terminfo

# 3) Симлинк для fd (fdfind -> fd)
if command -v fdfind >/dev/null 2>&1; then
    ln -sf "$(command -v fdfind)" /usr/local/bin/fd
fi

# 4) Настройка SSH-демона
sed -i 's/^#\?PasswordAuthentication .*/PasswordAuthentication no/' /etc/ssh/sshd_config
sed -i 's/^#\?PubkeyAuthentication .*/PubkeyAuthentication yes/' /etc/ssh/sshd_config
sed -i 's/^#\?ChallengeResponseAuthentication .*/ChallengeResponseAuthentication no/' /etc/ssh/sshd_config
systemctl reload sshd

# 5) Подготовка /etc/skel для новых пользователей
echo "👉 Копируем конфиги в /etc/skel для новых пользователей"
# удаляем старые скелеты (если нужно)
# rm -rf /etc/skel/*

# Копируем всё, кроме ненужного
for item in "$SCRIPT_DIR"/.[!.]* "$SCRIPT_DIR"/*; do
  base="$(basename "$item")"
  case "$base" in
    .|..|README.md|root_install.sh|.git) continue ;;
  esac
  cp -r "$item" /etc/skel/
done

# SSH-ключи в скелет
mkdir -p /etc/skel/.ssh
cp "$SCRIPT_DIR"/.ssh/authorized_keys /etc/skel/.ssh/authorized_keys
chmod 700 /etc/skel/.ssh
chmod 600 /etc/skel/.ssh/authorized_keys

# 6) Применяем конфигурацию для всех существующих пользователей
echo "👉 Распространяем конфиги на всех пользователей в /home"
for home in /home/*; do
  [ -d "$home" ] || continue
  user="$(basename "$home")"
  echo "   • $user"

  # копируем dot-файлы
  for item in "$SCRIPT_DIR"/.[!.]* "$SCRIPT_DIR"/*; do
    base="$(basename "$item")"
    case "$base" in
      .|..|README.md|root_install.sh|.git) continue ;;
    esac
    cp -r "$item" "$home"/
  done

  # SSH-ключи
  mkdir -p "$home"/.ssh
  cp "$SCRIPT_DIR"/.ssh/authorized_keys "$home"/.ssh/
  chmod 700 "$home"/.ssh
  chmod 600 "$home"/.ssh/authorized_keys

  # shell → zsh
  chsh -s "$(command -v zsh)" "$user"

  # кеш Z-sh
  mkdir -p "$home"/.cache/zsh
  touch   "$home"/.cache/zsh/histfile

  # ShaDa для Neovim
  rm -f "$home"/.local
  mkdir -p "$home"/.local/share/nvim/shada

  # выставляем права
  chown -R "$user":"$user" "$home"
done

echo "✅ Готово! Новые пользователи при создании получат вашу конфигурацию автоматически."
