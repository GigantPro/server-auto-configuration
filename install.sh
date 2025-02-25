#/bin/sh

echo "Installing dependencies"
sudo apt update && sudo apt upgrade -y
sudo apt install htop ranger zsh neofetch neovim ibus procps exa highlight zoxide git -y

echo "Removing all files"
find ../ -mindepth 1 -maxdepth 1 ! -name "server-auto-configuration" -exec rm -rf {} +

echo "Copeing all config files"
cp -r ./ ../
rm -rf ../README.md ../install.sh ../.git

echo "Switch to zsh"
chsh -s $(which zsh)

reboot
