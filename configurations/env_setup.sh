#!/bin/bash
# Run this script directly by:
# 	curl -s https://raw.githubusercontent.com/benipeled/my-tool-box/main/configurations/env_setup.sh | bash

# Add repos
sudo dnf config-manager --add-repo https://cli.github.com/packages/rpm/gh-cli.repo


PACKAGES="wget vim ansible git flameshot \
	yakuake keepass gnome-tweaks \
	podman podman-compose awscli ipython telnet vim-default-editor gh
	"


# Install my packages
sudo dnf install -y $PACKAGES

# Update .bashrc file (if not updated)
if ! grep -q "My Bashrc Modificatoins" ~/.bashrc
then
	curl https://raw.githubusercontent.com/benipeled/my-tool-box/main/configurations/bashrc >> ~/.bashrc
fi

# Create git repositories folder
mkdir ~/repos

# Install snapd
sudo dnf install -y snapd
sudo ln -s /var/lib/snapd/snap /snap


# Install pycharm
sudo snap install pycharm-community --classic
