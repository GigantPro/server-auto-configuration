#!/bin/sh
set -e

DEST="/etc/profile.d/99-custom_motd.sh"

cat << 'EOF' > "$DEST"
#!/bin/sh
# Этот скрипт срабатывает при каждом интерактивном входе через SSH или в консоли.

# Проверяем, что это вход в интерактивную оболочку
[ -n "$PS1" ] || exit 0

# Цвета
GREEN="\033[1;32m"
YELLOW="\033[1;33m"
BLUE="\033[1;34m"
NC="\033[0m"

HOSTNAME="$(hostname)"
width=$(tput cols 2>/dev/null || echo 80)

phrase="Добро пожаловать на сервер"
total_len=$(( ${#phrase} + 1 + ${#HOSTNAME} ))
pad=$(( (width - total_len) / 2 ))
[ $pad -lt 0 ] && pad=0
spaces=$(printf '%*s' $pad '')

# 1) Центрированный заголовок
echo -e "${BLUE}${spaces}${phrase} ${GREEN}${HOSTNAME}${NC}"
echo

# 2) 5 последних уникальных логинов с IP
echo -e "${GREEN}Последние логины:${NC}"
last -i | \
  awk '$1!="reboot" && $1!="wtmp" { print $1, $3 }' | \
  awk '!seen[$0]++' | \
  head -n 5 | \
  while read user ip; do
    printf " - %s from %s\n" "$user" "$ip"
  done
echo

# 3) Системная статистика
printf "${GREEN}Дата:     ${NC}%s\n" "$(date '+%A, %d %B %Y %T')"
printf "${GREEN}Uptime:   ${NC}%s\n" "$(uptime -p)"
printf "${GREEN}Load avg: ${NC}%s\n" "$(awk '{print $1,$2,$3}' /proc/loadavg)"
printf "${GREEN}Пользов.: ${NC}%d\n" "$(who | wc -l)"

root_fs=$(df -h / | awk 'NR==2 {printf "%s used, %s free (%s)", $3, $4, $5}')
printf "${GREEN}Disk /:   ${NC}%s\n" "$root_fs"

mem_used=$(free -h | awk '/^Mem:/ {print $3}')
mem_total=$(free -h | awk '/^Mem:/ {print $2}')
printf "${GREEN}Memory:   ${NC}%s / %s\n" "$mem_used" "$mem_total"

updates=$(apt list --upgradable 2>/dev/null | tail -n +2 | wc -l)
if [ "$updates" -gt 0 ]; then
  printf "${YELLOW}Updates:  ${NC}%d пакетов доступно\n" "$updates"
else
  printf "${GREEN}Updates:  ${NC}нет обновлений\n"
fi
echo

# 4) Fastfetch в самом низу
fastfetch
EOF

# даём права
chmod 755 "$DEST"
