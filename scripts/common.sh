#!/bin/sh
set -e

# SCRIPT_ROOT — корень репозитория
SCRIPT_ROOT="$(cd "$(dirname "$0")"/.. && pwd)"

copy_configs() {
  local dest="$1"

  # Копируем все ваши dot-файлы и папки (кроме .git, scripts, README.md и корневых скриптов)
  for item in "$SCRIPT_ROOT"/.[!.]* "$SCRIPT_ROOT"/*; do
    base="$(basename "$item")"
    case "$base" in
      .|..|README.md|root_install.sh|scripts|.git) continue ;;
    esac
    cp -r "$item" "$dest"/
  done

  # SSH-ключи
  mkdir -p "$dest"/.ssh
  cp "$SCRIPT_ROOT"/.ssh/authorized_keys "$dest"/.ssh/authorized_keys
  chmod 700 "$dest"/.ssh
  chmod 600 "$dest"/.ssh/authorized_keys

  # Кеш Z-sh
  mkdir -p "$dest"/.cache/zsh
  touch   "$dest"/.cache/zsh/histfile

  # ShaDa для Neovim
  # очищаем старые и создаём папку
  rm -rf "$dest"/.local/share/nvim/shada
  mkdir -p "$dest"/.local/share/nvim/shada
}
