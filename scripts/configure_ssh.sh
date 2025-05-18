#!/bin/sh
set -e

# Отключаем парольный логин, включаем pubkey-only
sed -i 's/^#\?PasswordAuthentication .*/PasswordAuthentication no/' /etc/ssh/sshd_config
sed -i 's/^#\?PubkeyAuthentication .*/PubkeyAuthentication yes/' /etc/ssh/sshd_config
sed -i 's/^#\?ChallengeResponseAuthentication .*/ChallengeResponseAuthentication no/' /etc/ssh/sshd_config

# Перезапускаем sshd
systemctl reload sshd

echo "✅ SSH настроен."