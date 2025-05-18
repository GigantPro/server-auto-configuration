#!/bin/sh
set -e

# 0) Полностью удаляем старую статику и скрипты update-motd.d
rm -f /etc/motd /etc/motd.tail
if [ -d /etc/update-motd.d ]; then
  rm -f /etc/update-motd.d/[0-9][0-9]-*
fi

# Отключаем обработку PAM-mod-motd, чтобы не выводились старые сообщения
for svc in sshd login; do
  pamf="/etc/pam.d/${svc}"
  if grep -q 'pam_motd.so' "$pamf"; then
    sed -i.bak '/pam_motd.so/s|^|# disabled by custom MOTD: |' "$pamf"
  fi
done

# 1) Пишем новый скрипт в /etc/profile.d — он будет единственным источником MOTD
DEST="/etc/profile.d/99-custom_motd.sh"
cat << 'EOF' > "$DEST"
#!/bin/sh
[ -n "$PS1" ] || exit 0   # только интерактивный режим

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

# Заголовок
echo -e "${BLUE}${spaces}${phrase} ${GREEN}${HOSTNAME}${NC}"
echo

# 5 последних уникальных логинов с IP
echo -e "${GREEN}Последние логины:${NC}"
last -i | \
  awk '$1!="reboot" && $1!="wtmp" { print $1, $3 }' | \
  awk '!seen[$0]++' | \
  head -n 5 | \
  while read user ip; do
    printf " - %s from %s\n" "$user" "$ip"
  done
echo

# Статистика системы
printf "${GREEN}Дата:     ${NC}%s\n" "$(date '+%A, %d %B %Y %T')"
printf "${GREEN}Uptime:   ${NC}%s\n" "$(uptime -p)"
printf "${GREEN}Load avg: ${NC}%s\n" "$(awk '{print $1,$2,$3}' /proc/loadavg)"
printf "${GREEN}Пользов.: ${NC}%d\n" "$(who | wc -l)"
root_fs=$(df -h / | awk 'NR==2 {printf "%s used, %s free (%s)", $3,$4,$5}')
printf "${GREEN}Disk /:   ${NC}%s\n" "$root_fs"
mem_used=$(free -h | awk '/^Mem:/ {print $3}'); mem_total=$(free -h | awk '/^Mem:/ {print $2}')
printf "${GREEN}Memory:   ${NC}%s / %s\n" "$mem_used" "$mem_total"
updates=$(apt list --upgradable 2>/dev/null | tail -n +2 | wc -l)
if [ "$updates" -gt 0 ]; then
  printf "${YELLOW}Updates:  ${NC}%d пакетов доступно\n" "$updates"
else
  printf "${GREEN}Updates:  ${NC}нет обновлений\n"
fi
echo

# fastfetch в самом низу
fastfetch
EOF

# 2) Делаем исполняемым
chmod 755 "$DEST"
