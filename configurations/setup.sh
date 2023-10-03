#!/bin/bash

# This script will automatically set up various configurations and
# install packages. Use the --help option to see available command
# line options.
#
# Run the following command to download and execute the script:
# curl -s https://raw.githubusercontent.com/benipeled/my-tool-box/main/configurations/setup.sh | sudo bash

PACKAGES="wget vim ansible \
	git flameshot nmap \
	yakuake keepassxc gnome-tweaks \
	podman podman-compose buildah \
	awscli ipython telnet \
	vim-default-editor \
	npm gh vlc htop \
	terraform packer \
	google-chrome-stable \
	python3-pip python3-jinja2-cli golang \
	pycharm-community google-cloud-cli \
	"
REMOVE_PACKAGES="nano-default-editor"
PIP_PACKAGES='black api4jenkins boto3 prettytable'

GIT_REPO_FOLDER=~/repos
GIT_REPO_LIST=(
  git@github.com:benipeled/my-tool-box.git
  git@github.com:benipeled/scylla.git
  git@github.com:benipeled/scylla-pkg.git
  git@github.com:benipeled/scylla-machine-image.git
  git@github.com:benipeled/scylla-manager.git
)

# For more colors see https://dev.to/ifenna__/adding-colors-to-bash-scripts-48g4
GREEN="\e[32m"
GRAY="\e[90m"
RED="\e[31m"
CYAN="\e[36m"
NOCOLOR="\e[0m"


print_start() {
  printf "         Starting %s\n" "$1"
}

print_finish() {
  printf "[$GREEN  OK  $NOCOLOR] %s\n" "$1"
}

print_fail() {
  printf "[$RED Fail $NOCOLOR] %s\n" "$1"
}

print_skip() {
  printf "[$CYAN Skip $NOCOLOR] %s\n" "$1"
}

print_output() {
  echo "-------------- $1 - output: -------------------"
  echo ""
  echo "$2"
  echo ""
  echo "-----------------------------------------------"
}

run_command() {
  # @description: the description of the command will be ran
  # @command: the command to run
  #
  # Example:
  #   run_command "Install git" "sudo dnf install git"

  cmd_message="$1"
  print_start "$cmd_message"
  cmd_output=$(eval "$2" 2>&1)
  cmd_return_code=$?
  if [[ $cmd_return_code -ne 0 ]]; then
    print_fail "$cmd_message"
    print_output "$cmd_message" "$cmd_output"
    exit 1
  fi
  if [[ $DEBUG ]]; then
    print_output "$cmd_message" "$cmd_output"
  fi
  print_finish "$cmd_message"
}

# Parse command-line options
for arg in "$@"; do
  case $arg in
    --debug)
    DEBUG=true
    shift
    ;;
    --help)
    echo -e "  --debug   Enable debug mode (print command output)\n  --help    Print help message"
    exit 0
    shift
    ;;
    *)
    echo "Error: Unknown option '$arg'. Use --help for a list of valid options."
    exit 1
    ;;
  esac
done


# Add repos
run_command "Add github RPM repository" "sudo dnf config-manager --add-repo https://cli.github.com/packages/rpm/gh-cli.repo"
run_command "Add hashicorp RPM repository" "sudo dnf config-manager --add-repo https://rpm.releases.hashicorp.com/fedora/hashicorp.repo"
run_command "Add rpmfusion RPM repository" "sudo dnf install -y https://download1.rpmfusion.org/free/fedora/rpmfusion-free-release-$(rpm -E %fedora).noarch.rpm # required for VLC"

run_command "Add Google Chrome repo" "echo '[google-chrome]
name=google-chrome
baseurl=https://dl.google.com/linux/chrome/rpm/stable/$basearch
enabled=1
gpgcheck=1
gpgkey=https://dl.google.com/linux/linux_signing_key.pub' | sudo tee /etc/yum.repos.d/google-chrome.repo"

run_command "Add PyCharm repo" "echo '[phracek-PyCharm]
name=Copr repo for PyCharm owned by phracek
baseurl=https://copr-be.cloud.fedoraproject.org/results/phracek/PyCharm/fedora-$releasever-$basearch/
skip_if_unavailable=True
gpgcheck=1
gpgkey=https://copr-be.cloud.fedoraproject.org/results/phracek/PyCharm/pubkey.gpg
enabled=1' | sudo tee /etc/yum.repos.d/pycharm-phracek-copr.repo"

run_command "Add gCloud CLI repo" "'[google-cloud-cli]
name=Google Cloud CLI
baseurl=https://packages.cloud.google.com/yum/repos/cloud-sdk-el8-x86_64
enabled=1
gpgcheck=1
repo_gpgcheck=0
gpgkey=https://packages.cloud.google.com/yum/doc/rpm-package-key.gpg' | sudo tee /etc/yum.repos.d/google-cloud-sdk.repo"

# Update .bashrc file if it doesn't already include custom modifications
if ! grep -q "My bash modifications" ~/.bashrc; then
  run_command "Updating .bashrc file with custom settings" "curl -sSL https://raw.githubusercontent.com/benipeled/my-tool-box/main/configurations/bashrc >> ~/.bashrc"
fi

run_command "Remove unnecessary packages" "sudo dnf remove -y $REMOVE_PACKAGES"
run_command "Upgrading installed packages" "sudo dnf upgrade -y"
run_command "Installing required packages" "sudo dnf install -y $PACKAGES"

# Install pip packages if they are not already installed
for package in $PIP_PACKAGES; do
  if ! pip show -q $package > /dev/null; then
    run_command "Install $package" "pip install $package"
  fi
done

# Create git repositories folder if it doesn't exist
if [ ! -d $GIT_REPO_FOLDER ]; then
  run_command "Create $GIT_REPO_FOLDER folder" "mkdir $GIT_REPO_FOLDER"
fi

# Clone each repo if it doesn't exist already
for REPO_URL in "${GIT_REPO_LIST[@]}"; do
  REPO_NAME=$(basename "$REPO_URL" .git)
  REPO_PATH=$GIT_REPO_FOLDER/$REPO_NAME

  if [ ! -d "$REPO_PATH" ]; then
    run_command "Clone $REPO_NAME" "git clone $REPO_URL $REPO_PATH"
  else
    print_skip "$REPO_NAME already exists, skipping clone"
  fi
done

# Configure global git user
run_command "Configuring global git user" "git config --global user.name 'Beni Peled'"
run_command "Configuring global git email" "git config --global user.email benipeled@gmail.com"

# Configure git diff-highlight
if [ ! -h '/usr/local/bin/diff-highlight' ]; then
  run_command "Configuring git diff-highlight symlink" "sudo ln -s '/usr/share/git-core/contrib/diff-highlight' '/usr/local/bin/diff-highlight'"
  run_command "Configuring git diff-highlight" "git config --global pager.diff 'diff-highlight | less'"
  run_command "Configuring git diff-highlight" "git config --global pager.show 'diff-highlight | less'"
fi

# Add flathub repo if it doesn't exist
if ! flatpak remotes | grep -q flathub; then
  run_command "Add flathub repo" "flatpak remote-add --if-not-exists flathub https://flathub.org/repo/flathub.flatpakrepo"
fi

# Enable flathub repo if it's not enabled
if ! flatpak remotes | grep -q 'flathub'; then
  run_command "Enable flathub repo" "flatpak remote-modify --enable flathub"
fi

# Install Extensions from flathub if it's not already installed
if ! flatpak list | grep -q org.gnome.Extensions; then
  run_command "Install Extensions" "flatpak install -y flathub org.gnome.Extensions"
fi

gnome-extensions disable background-logo@fedorahosted.org
gnome-extensions enable window-list@gnome-shell-extensions.gcampax.github.com
gnome-extensions enable places-menu@gnome-shell-extensions.gcampax.github.com

# Keyboard Shortcuts
# Note: for adding more shortcuts, make sure to increase the the 'custom' id, ex. custom1, custom2 etc.
gsettings set org.gnome.settings-daemon.plugins.media-keys custom-keybindings "['/org/gnome/settings-daemon/plugins/media-keys/custom-keybindings/custom0/']"
gsettings set org.gnome.settings-daemon.plugins.media-keys.custom-keybinding:/org/gnome/settings-daemon/plugins/media-keys/custom-keybindings/custom0/ name "Flameshot"
gsettings set org.gnome.settings-daemon.plugins.media-keys.custom-keybinding:/org/gnome/settings-daemon/plugins/media-keys/custom-keybindings/custom0/ command "flameshot gui"
gsettings set org.gnome.settings-daemon.plugins.media-keys.custom-keybinding:/org/gnome/settings-daemon/plugins/media-keys/custom-keybindings/custom0/ binding "<Ctrl><Alt>Q"

gsettings set org.gnome.desktop.wm.keybindings switch-windows "['<Alt>Tab']"
