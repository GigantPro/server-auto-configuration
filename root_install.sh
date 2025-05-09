 #!/bin/sh
 echo "Обновляем систему и ставим зависимости"
 sudo apt update && sudo apt upgrade -y
 sudo apt install \
     htop \
     ranger \
     fzf \
     zsh \
     neofetch \
     neovim \
     ibus \
     procps \
     exa \
     highlight \
     zoxide \
     git \
     tmux \
     wget \
     nala \
     python3 \
     python3-pip \
     python3-venv \
     fd-find \
+    kitty-terminfo \
   -y

 # Симлинк для fd
 if [ -x "$(command -v fdfind)" ]; then
   sudo ln -sf "$(command -v fdfind)" /usr/local/bin/fd
 fi

+echo "Отключаем PasswordAuthentication и гарантируем PubkeyAuthentication"
+sudo sed -i 's/^#\?PasswordAuthentication .*/PasswordAuthentication no/' /etc/ssh/sshd_config
+sudo sed -i 's/^#\?PubkeyAuthentication .*/PubkeyAuthentication yes/' /etc/ssh/sshd_config
+sudo sed -i 's/^#\?ChallengeResponseAuthentication .*/ChallengeResponseAuthentication no/' /etc/ssh/sshd_config
+sudo systemctl reload sshd

 echo "Удаляем всё в домашней папке, кроме .ssh и папки с этим скриптом"
 find ../ -mindepth 1 -maxdepth 1 \
      ! -name "server-auto-configuration" \
      ! -name ".ssh" \
   -exec rm -rf {} +

 echo "Копируем все конфиги в домашнюю папку"
 find ./ -mindepth 1 -maxdepth 1 \
      ! -name ".ssh" \
   -exec cp -r {} ../ \;
 rm -rf ../README.md ../root_install.sh ../.git

 echo "Меняем shell на zsh"
 chsh -s "$(which zsh)"

 echo "Создаём кеш для Z-sh"
 mkdir -p ~/.cache/zsh
 touch ~/.cache/zsh/histfile

 echo "Устанавливаем ваш SSH-ключ"
 mkdir -p ~/.ssh
 cp ./.ssh/authorized_keys ~/.ssh/authorized_keys
 chmod 700 ~/.ssh
 chmod 600 ~/.ssh/authorized_keys

 echo "Готово! Перезайдите по SSH — теперь только по ключам, и терминал Kitty на сервере больше не даст багов с повторяющимся вводом."
