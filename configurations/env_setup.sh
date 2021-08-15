#!/bin/bash
# Run this script directly by:
# 	curl -s https://raw.githubusercontent.com/benipeled/my-tool-box/main/configurations/env_setup.sh | bash

PACKAGES="wget vim ansible git flameshot \
	yakuake keepass gnome-tweaks \
	podman podman-compose awscli ipython telnet vim-default-editor gh
	"

REPO_FOLDER=~/repos



# Add repos
sudo dnf config-manager --add-repo https://cli.github.com/packages/rpm/gh-cli.repo

# Update; Install my packages
sudo dnf upgrade -y
sudo dnf install -y $PACKAGES

# Update .bashrc file (if not updated)
if ! grep -q "My Bashrc Modificatoins" ~/.bashrc
then
	curl https://raw.githubusercontent.com/benipeled/my-tool-box/main/configurations/bashrc >> ~/.bashrc
fi

# Install snapd
sudo dnf install -y snapd
sudo ln -s /var/lib/snapd/snap /snap

# Install pycharm
sudo snap install pycharm-community --classic

# Create git repositories folder
mkdir $REPO_FOLDER

# Clone git repos
cd $REPO_FOLDER
git clone git@github.com:benipeled/my-tool-box.git
git clone git@github.com:benipeled/scylla-pkg.git
git clone git@github.com:benipeled/scylla-machine-image.git
git clone git@github.com:awslabs/aws-cloudformation-templates.git
