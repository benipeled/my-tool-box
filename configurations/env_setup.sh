#!/bin/bash
# Run this script directly by:
# 	curl -s https://raw.githubusercontent.com/benipeled/my-tool-box/main/configurations/env_setup.sh | sudo bash


########### Variables #############

PACKAGES="wget vim ansible git flameshot nmap \
	yakuake keepass gnome-tweaks \
	podman podman-compose awscli ipython telnet \
	vim-default-editor gh npm terraform python3-jinja2-cli \
	packer google-chrome-stable vlc python3-pip htop
	"
REMOVE_PACKAGES="nano-default-editor"
NPM_PACKAGES='npm-groovy-lint'
REPO_FOLDER=~/repos
MY_GIT_REPOS="my-tool-box aws-cloudformation-templates scylla scylla-pkg scylla-machine-image"


########### Configurations #############

# Add repos
sudo dnf config-manager --add-repo https://cli.github.com/packages/rpm/gh-cli.repo # add github repo
sudo dnf config-manager --add-repo https://rpm.releases.hashicorp.com/fedora/hashicorp.repo # add hashicorp repo
sudo dnf install -y https://download1.rpmfusion.org/free/fedora/rpmfusion-free-release-$(rpm -E %fedora).noarch.rpm # add rpmfusion repo

# Add Google Chrome repo
echo '[google-chrome]
name=google-chrome
baseurl=http://dl.google.com/linux/chrome/rpm/stable/$basearch
enabled=1
gpgcheck=1
gpgkey=https://dl-ssl.google.com/linux/linux_signing_key.pub' > /etc/yum.repos.d/google-chrome.repo


# Update .bashrc file (if not updated)
if ! grep -q "My bash modificatoins" ~/.bashrc
then
	curl https://raw.githubusercontent.com/benipeled/my-tool-box/main/configurations/bashrc >> ~/.bashrc
fi


########### Installations #############

# Remove unwanted packages; Update; Install my packages
sudo dnf remove -y $REMOVE_PACKAGES
sudo dnf upgrade -y
sudo dnf install -y $PACKAGES

# Install snapd
sudo dnf install -y snapd
sudo ln -s /var/lib/snapd/snap /snap

# Install pycharm
sudo snap install pycharm-community --classic

# Install npm packages
for package in $NPM_PACKAGES; do
  sudo npm list $package  && echo "$package is already installed" || sudo npm install $package
done

########### GIT #############

# Create git repositories folder
mkdir $REPO_FOLDER

# Clone git repos
pushd $REPO_FOLDER
for repo in $MY_GIT_REPOS; do
  git clone git@github.com:benipeled/$repo.git
done
popd

flatpak remote-add --if-not-exists flathub https://flathub.org/repo/flathub.flatpakrepo
flatpak install -y flathub org.gnome.Extensions

# Configure global git user

git config --global user.name "Beni Peled"
git config --global user.email benipeled@gmail.com

