#!/bin/sh
set -e

# 0) Удаляем всё, что могло печатать старый MOTD
rm -f /etc/motd /etc/motd.tail
if [ -d /etc/update-motd.d ]; then
  rm -f /etc/update-motd.d/[0-9][0-9]-*
fi

# Отключаем PAM-модуль motd, чтобы он не подхватывал статику
for svc in sshd login; do
  pamf="/etc/pam.d/${svc}"
  [ -f "$pamf" ] || continue
  sed -i.bak '/pam_motd\.so/ s/^/# disabled by custom MOTD: /' "$pamf"
done

# 1) Пишем наш скрипт-единственный в /etc/profile.d
DEST="/etc/profile.d/99-custom_motd.sh"
cat << 'EOF' > "$DEST"
#!/bin/sh
# Только для интерактивных входов
[ -n "$PS1" ] || exit 0

GREEN="\033[1;32m"; YELLOW="\033[1;33m"; BLUE="\033[1;34m"; NC="\033[0m"
HOST="$(hostname)"; width=$(tput cols 2>/dev/null||echo80)
phrase="Добро пожаловать на сервер"
pad=$(( (width - ${#phrase} - ${#HOST}) / 2 )); [ $pad -lt 0 ]&&pad=0
spaces=$(printf '%*s' $pad '')

echo -e "${BLUE}${spaces}${phrase} ${GREEN}${HOST}${NC}"
echo
echo -e "${GREEN}Последние логины:${NC}"
last -i | awk '$1!="reboot"&&$1!="wtmp"{print $1,$3}' \
  | awk '!seen[$0]++' | head -n5 | while read u ip; do
      printf " - %s from %s\n" "$u" "$ip"
  done
echo
printf "${GREEN}Дата:     ${NC}%s\n" "$(date '+%A, %d %B %Y %T')"
printf "${GREEN}Uptime:   ${NC}%s\n" "$(uptime -p)"
printf "${GREEN}Load avg: ${NC}%s\n" "$(awk '{print $1,$2,$3}' /proc/loadavg)"
printf "${GREEN}Пользов.: ${NC}%d\n" "$(who|wc -l)"
root_fs=$(df -h / | awk 'NR==2{printf "%s used, %s free (%s)", $3,$4,$5}')
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
fastfetch
EOF

chmod 755 "$DEST"
