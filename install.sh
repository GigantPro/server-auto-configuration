#!/bin/bash

set -euo pipefail

# ===== 1. Проверка прав =====
if [[ $(id -u) -ne 0 ]]; then
  echo "Этот скрипт нужно запускать от root."
  exit 1
fi

# ===== 2. Определяем старого пользователя и его группу =====
OLD_USER=$(awk -F: '$3 >= 1000 && $3 < 60000 && $1 != "nobody" {print; exit}' /etc/passwd | cut -d: -f1)
if [[ -z "$OLD_USER" ]]; then
  echo "Не удалось найти обычного пользователя для переименования."
  exit 1
fi
OLD_GROUP=$(id -gn "$OLD_USER")
echo "Найден пользователь: $OLD_USER (группа: $OLD_GROUP)"

# ===== 3. Запрос нового имени и проверка =====
read -p "Введите новое имя пользователя: " NEW_USER
if id "$NEW_USER" &>/dev/null; then
  echo "Пользователь $NEW_USER уже существует."
  exit 1
fi

# ===== 4. Переименовываем группу =====
if getent group "$OLD_GROUP" &>/dev/null; then
  echo "Переименовываю группу $OLD_GROUP → $NEW_USER"
  groupmod -n "$NEW_USER" "$OLD_GROUP"
else
  echo "Группа $OLD_GROUP не найдена, пропускаем её переименование."
fi

# ===== 5. Переименовываем пользователя и домашнюю папку =====
echo "Переименовываю пользователя $OLD_USER → $NEW_USER и перемещаю /home/$OLD_USER → /home/$NEW_USER"
usermod -l "$NEW_USER" -d "/home/$NEW_USER" -m -g "$NEW_USER" "$OLD_USER"

# ===== 6. Установка пароля для нового пользователя =====
read -s -p "Введите пароль для $NEW_USER: " PASS_USER
echo
echo "$NEW_USER:$PASS_USER" | chpasswd
echo "Пароль для $NEW_USER установлен."

# ===== 7. Установка пароля для root =====
read -s -p "Введите пароль для root: " PASS_ROOT
echo
echo "root:$PASS_ROOT" | chpasswd
echo "Пароль для root установлен."

# ===== 8. Переименование хоста =====
read -p "Введите новый hostname для машины: " NEW_HOST
echo "$NEW_HOST" > /etc/hostname
hostnamectl set-hostname "$NEW_HOST"

# Обновим строку 127.0.1.1 в /etc/hosts
if grep -qE '^127\.0\.1\.1\b' /etc/hosts; then
  sed -i "s/^127\.0\.1\.1.*/127.0.1.1\t$NEW_HOST/" /etc/hosts
else
  echo -e "127.0.1.1\t$NEW_HOST" >> /etc/hosts
fi

echo "Hostname изменён на $NEW_HOST."

echo "Инициализация завершена. Рекомендуется перезагрузить систему."
