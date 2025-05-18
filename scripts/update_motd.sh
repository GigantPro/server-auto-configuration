#!/bin/sh
set -e

# — 0) Чистим всё старое —
rm -f /etc/motd /etc/motd.tail
[ -d /etc/update-motd.d ] && rm -f /etc/update-motd.d/[0-9][0-9]-*

# Восстанавливаем pam_motd (если ранее был отключен)
for svc in sshd login; do
    sed -i.bak '/pam_motd.so/s/^#//g' /etc/pam.d/"$svc"
done

# — 1) Пишем наш кастомный скрипт в update-motd.d —
DEST="/etc/update-motd.d/99-custom"
cat << 'EOF' > "$DEST"
#!/bin/sh

# определяем цвета
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
NC='\033[0m'

# заголовок
printf "${GREEN}Добро пожаловать на сервер ${NC}%s

" "$(hostname)"

# использование памяти
mem_used=$(free -h | awk '/^Mem:/{print $3}')
mem_total=$(free -h | awk '/^Mem:/{print $2}')
printf "${GREEN}Memory:   ${NC}%s / %s
" "$mem_used" "$mem_total"

# обновления пакетов
updates=$(apt list --upgradable 2>/dev/null | tail -n+2 | wc -l)
if [ "$updates" -gt 0 ]; then
    printf "${YELLOW}Updates:  ${NC}%d пакетов доступно
" "$updates"
else
    printf "${GREEN}Updates:  ${NC}нет обновлений
"
fi

echo

# Fastfetch внизу
fastfetch
EOF
chmod +x "$DEST"
