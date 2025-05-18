#!/bin/sh
set -e

# — 0) Чистим всё старое —
rm -f /etc/motd /etc/motd.tail
[ -d /etc/update-motd.d ] && rm -f /etc/update-motd.d/[0-9][0-9]-*
# Восстанавливаем pam_motd (если вы ранее его отключали)
for svc in sshd login; do
  pamf="/etc/pam.d/${svc}"
  [ -f "$pamf" ] || continue
  sed -i.bak '/^# disabled by custom MOTD: *pam_motd.so/ s|^# disabled by custom MOTD: *||' "$pamf"
done

# — 1) Пишем скрипт в update-motd.d —
DEST="/etc/update-motd.d/99-custom"
cat << 'EOF' > "$DEST"
#!/bin/sh
# Цвета
GREEN="\033[1;32m"; YELLOW="\033[1;33m"; BLUE="\033[1;34m"; NC="\033[0m"

# Центрированный заголовок
HOST="$(hostname)"
phrase="Добро пожаловать на сервер"
width=$(tput cols 2>/dev/null||echo 80)
pad=$(( (width - ${#phrase} - ${#HOST})/2 )); [ $pad -lt 0 ]&&pad=0
spaces=$(printf '%*s' $pad '')
echo -e "${BLUE}${spaces}${phrase} ${GREEN}${HOST}${NC}"
echo

# 5 последних уникальных логинов
echo -e "${GREEN}Последние логины:${NC}"
last -i | awk '$1!="reboot"&&$1!="wtmp"{print $1,$3}' \
  | awk '!seen[$0]++' | head -n5 \
  | while read u ip; do printf " - %s from %s\n" "$u" "$ip"; done
echo

# Статистика
printf "${GREEN}Дата:     ${NC}%s\n" "$(date '+%A, %d %B %Y %T')"
printf "${GREEN}Uptime:   ${NC}%s\n" "$(uptime -p)"
printf "${GREEN}Load avg: ${NC}%s\n" "$(awk '{print $1,$2,$3}' /proc/loadavg)"
printf "${GREEN}Пользов.: ${NC}%d\n" "$(who|wc -l)"
root_fs=$(df -h / | awk 'NR==2{printf "%s used, %s free (%s)",$3,$4,$5}')
printf "${GREEN}Disk /:   ${NC}%s\n" "$root_fs"
mem_used=$(free -h|awk '/^Mem:/{print $3}'); mem_total=$(free -h|awk '/^Mem:/{print $2}')
printf "${GREEN}Memory:   ${NC}%s / %s\n" "$mem_used" "$mem_total"
updates=$(apt list --upgradable 2>/dev/null|tail -n+2|wc -l)
if [ "$updates" -gt 0 ]; then
  printf "${YELLOW}Updates:  ${NC}%d пакетов доступно\n" "$updates"
else
  printf "${GREEN}Updates:  ${NC}нет обновлений\n"
fi
echo

# Fastfetch внизу
fastfetch
EOF
chmod +x "$DEST"
