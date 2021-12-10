#!/bin/bash
# Run this script directly by:
# 	curl -s https://raw.githubusercontent.com/benipeled/my-tool-box/main/configurations/env_setup.sh | sudo bash


########### Variables #############

PACKAGES="wget vim ansible \
	git flameshot nmap \
	yakuake keepass gnome-tweaks \
	podman podman-compose buildah \
	awscli ipython telnet \
	vim-default-editor \
	npm gh vlc htop \
	terraform packer \
	google-chrome-stable \
	python3-pip python3-jinja2-cli \
	"
REMOVE_PACKAGES="nano-default-editor"
PIP_PACKAGES='black api4jenkins boto3'
NPM_PACKAGES='npm-groovy-lint'
REPO_FOLDER=~/repos
MY_GIT_REPOS="my-tool-box aws-cloudformation-templates scylla scylla-pkg scylla-machine-image scylla-cli"

RED="\033[1;31m"
GREEN="\033[1;32m"
NOCOLOR="\033[0m"


########## Functions #############

function run_command {
  # This function gets two arguments, `description` and `command`
  #
  # @description: a description of the command will be ran
  # @command: the actuall command to run
  #
  # Example:
  #   run_command "Install git" sudo dnf install git

        eval ${*:2} 1>/dev/null
        exit_status=$?
        if [ $exit_status -eq 0 ]; then
          echo -e "${GREEN}[  OK  ]${NOCOLOR} $1"
        else
          echo -e "${RED}[  FAILED  ]${NOCOLOR} $1"
          exit 1
        fi
}

########### Configurations #############

# Add repos
run_command "Add github RPM repository" sudo dnf config-manager --add-repo https://cli.github.com/packages/rpm/gh-cli.repo
run_command "Add hashicorp RPM repository" sudo dnf config-manager --add-repo https://rpm.releases.hashicorp.com/fedora/hashicorp.repo
run_command "Add rpmfusion RPM repository" sudo dnf install -y https://download1.rpmfusion.org/free/fedora/rpmfusion-free-release-$(rpm -E %fedora).noarch.rpm

# Add Google Chrome repo
echo '[google-chrome]
name=google-chrome
baseurl=http://dl.google.com/linux/chrome/rpm/stable/$basearch
enabled=1
gpgcheck=1
gpgkey=https://dl-ssl.google.com/linux/linux_signing_key.pub' | sudo tee /etc/yum.repos.d/google-chrome.repo >/dev/null


if ! grep -q "My bash modificatoins" ~/.bashrc
then
	run_command "Update .bashrc file" curl https://raw.githubusercontent.com/benipeled/my-tool-box/main/configurations/bashrc >> ~/.bashrc
fi


########### Installations #############

# Remove unwanted packages; Update; Install my packages
run_command "Remove unwanted packages" sudo dnf remove -y $REMOVE_PACKAGES
sudo dnf upgrade -y
run_command "Install packages" sudo dnf install -y $PACKAGES

# Install snapd
sudo dnf install -y snapd
sudo ln -s /var/lib/snapd/snap /snap

# Install pycharm
sudo snap install pycharm-community --classic

# Install pip packages
for package in $PIP_PACKAGES; do
  pip show -q $package && echo "pip: $package is already installed" || run_command "Install $package" pip install $package
done

# Install npm packages
for package in $NPM_PACKAGES; do
  sudo npm list --global npm-groovy-lint 1> /dev/null && echo "npm: npm-groovy-lint is already installed" || run_command "Install $package" sudo npm install --global npm-groovy-lint
done

########### GIT #############

# Create git repositories folder
mkdir $REPO_FOLDER

# Clone git repos
pushd $REPO_FOLDER "$@" > /dev/null
for repo in $MY_GIT_REPOS; do
  git clone git@github.com:benipeled/$repo.git
done
popd "$@" > /dev/null

run_command "Add flatpak repo (flathub)" flatpak remote-add --if-not-exists flathub https://flathub.org/repo/flathub.flatpakrepo
run_command "Install gnome extension (Extensions)" flatpak install -y flathub org.gnome.Extensions

# Configure global git user
run_command "Configure global git user" git config --global user.name "Beni Peled" && git config --global user.email benipeled@gmail.com

# Gnome Extensions
gnome-extensions disable background-logo@fedorahosted.org
gnome-extensions enable window-list@gnome-shell-extensions.gcampax.github.com
gnome-extensions enable places-menu@gnome-shell-extensions.gcampax.github.com

# Keyboard Shortcuts
# Note: for adding more shortcuts, make sure to increase the the 'custom' id, ex. custom1, custom2 etc.
# Flameshot
gsettings set org.gnome.settings-daemon.plugins.media-keys custom-keybindings "['/org/gnome/settings-daemon/plugins/media-keys/custom-keybindings/custom0/']"
gsettings set org.gnome.settings-daemon.plugins.media-keys.custom-keybinding:/org/gnome/settings-daemon/plugins/media-keys/custom-keybindings/custom0/ name "Flameshot"
gsettings set org.gnome.settings-daemon.plugins.media-keys.custom-keybinding:/org/gnome/settings-daemon/plugins/media-keys/custom-keybindings/custom0/ command "flameshot gui"
gsettings set org.gnome.settings-daemon.plugins.media-keys.custom-keybinding:/org/gnome/settings-daemon/plugins/media-keys/custom-keybindings/custom0/ binding "<Ctrl><Alt>Q"
