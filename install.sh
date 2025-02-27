#/bin/sh

echo "Installing dependencies"
sudo apt update && sudo apt upgrade -y
sudo apt install htop ranger zsh neofetch neovim ibus procps exa highlight zoxide git -y

echo "Removing all files"
find ../ -mindepth 1 -maxdepth 1 ! -name "server-auto-configuration" ! -name ".ssh" -exec rm -rf {} +

echo "Copeing all config files"
find ./ -mindepth 1 -maxdepth 1 ! -name ".ssh" -exec cp -r {} ../
rm -rf ../README.md ../install.sh ../.git

echo "Switch to zsh"
chsh -s $(which zsh)

echo "Creating history file"
mkdir ~/.cache
mkdir ~/.cache/zsh
touch ~/.cache/zsh/histfile
#reboot
