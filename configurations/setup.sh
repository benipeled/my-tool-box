#!/bin/bash

# This script will automatically set up various configurations and
# install packages. Use the --help option to see available command
# line options.
#
# Run the following command to download and execute the script:
# curl -s https://raw.githubusercontent.com/benipeled/my-tool-box/main/configurations/setup.sh | sudo bash

PACKAGES="wget vim ansible \
    git flameshot nmap keepassxc gnome-tweaks \
    telnet vim npm vlc htop google-chrome-stable \
    python3-pip python3-jinja2"
    
REMOVE_PACKAGES="nano"
PIP_PACKAGES='black api4jenkins ipython'

PYCHARM_VERSION="2024.2.3"
PYCHARM_URL="https://download.jetbrains.com/python/pycharm-community-$PYCHARM_VERSION.tar.gz"
PYCHARM_INSTALL_DIR="/opt"
PYCHARM_ICON_PATH="/usr/share/applications/pycharm.desktop"
PYCHARM_FILETYPES_DIR="$PYCHARM_INSTALL_DIR/pycharm-community-$PYCHARM_VERSION/filetypes"
PYCHARM_FILETYPE_URL="https://raw.githubusercontent.com/benipeled/my-tool-box/main/configurations/Jenkinsfile.xml"

GIT_REPO_FOLDER=~/repos
GIT_REPO_LIST=(
  git@github.com:benipeled/my-tool-box.git
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
  #   run_command "Install git" "sudo apt install git"

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


install_pycharm() {
  if [ -d "$PYCHARM_INSTALL_DIR/pycharm-community-$PYCHARM_VERSION" ]; then
      return
  fi

  run_command "Downloading PyCharm $PYCHARM_VERSION" "wget \"$PYCHARM_URL\" -O /tmp/pycharm-$PYCHARM_VERSION.tar.gz"
  run_command "Installing PyCharm $PYCHARM_VERSION" "sudo tar -xzf /tmp/pycharm-$PYCHARM_VERSION.tar.gz -C \"$PYCHARM_INSTALL_DIR\""
  run_command "Removing downloaded archive" "rm /tmp/pycharm-$PYCHARM_VERSION.tar.gz"

  if [ ! -d "$PYCHARM_FILETYPES_DIR" ]; then
      run_command "Creating filetypes directory" "sudo mkdir -p \"$PYCHARM_FILETYPES_DIR\""
  fi

  run_command "Downloading Jenkinsfile support" "sudo wget \"$PYCHARM_FILETYPE_URL\" -O \"$PYCHARM_FILETYPES_DIR/jenkinsfile.xml\""
  run_command "Updating PyCharm app icon" "sudo tee $PYCHARM_ICON_PATH > /dev/null <<EOL
[Desktop Entry]
Version=$PYCHARM_VERSION
Type=Application
Name=PyCharm Community
Exec=$PYCHARM_INSTALL_DIR/pycharm-community-$PYCHARM_VERSION/bin/pycharm.sh
Icon=$PYCHARM_INSTALL_DIR/pycharm-community-$PYCHARM_VERSION/bin/pycharm.png
Comment=Integrated Development Environment
Categories=Development;IDE;
Terminal=false
StartupWMClass=jetbrains-pycharm
EOL"
}


# Add repos
run_command "Add Google Chrome repo" "wget -q -O - https://dl.google.com/linux/linux_signing_key.pub | sudo apt-key add - && echo 'deb [arch=amd64] http://dl.google.com/linux/chrome/deb/ stable main' | sudo tee /etc/apt/sources.list.d/google-chrome.list"
run_command "Add HashiCorp repo" "wget -O- https://apt.releases.hashicorp.com/gpg | gpg --dearmor | sudo tee /usr/share/keyrings/hashicorp-archive-keyring.gpg > /dev/null  && echo 'deb [signed-by=/usr/share/keyrings/hashicorp-archive-keyring.gpg] https://apt.releases.hashicorp.com $(lsb_release -cs) main' | sudo tee /etc/apt/sources.list.d/hashicorp.list"
run_command "Add Microsoft repo" "wget -q https://packages.microsoft.com/keys/microsoft.asc -O- | sudo apt-key add -&& echo 'deb [arch=amd64] https://packages.microsoft.com/repos/vscode stable main' | sudo tee /etc/apt/sources.list.d/vscode.list"
#run_command "Add Docker repo" "sudo apt-get update && sudo apt-get install apt-transport-https ca-certificates curl gnupg-agent software-properties-common && curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo apt-key add - && sudo add-apt-repository 'deb [arch=amd64] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable'"

# Update .bashrc file if it doesn't already include custom modifications
if ! grep -q "My bash modifications" ~/.bashrc; then
  run_command "Updating .bashrc file with custom settings" "wget -q -O - https://raw.githubusercontent.com/benipeled/my-tool-box/main/configurations/bashrc >> ~/.bashrc"
fi

run_command "Update package index files" "sudo apt-get update"
run_command "Remove unnecessary packages" "sudo apt-get remove -y $REMOVE_PACKAGES"
run_command "Upgrading packages" "sudo apt-get upgrade -y"
run_command "Installing packages" "sudo apt-get install -y $PACKAGES"

run_command "Installing fstail" "sudo wget -O /usr/local/bin/fstail https://github.com/alexellis/fstail/releases/download/0.1.0/fstail && sudo chmod +x /usr/local/bin/fstail"

# Install pip packages if they are not already installed
for package in $PIP_PACKAGES; do
  if ! pip show -q $package > /dev/null; then
    run_command "Install $package" "pip install --break-system-packages $package"
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
  run_command "Configuring git diff-highlight symlink" "sudo ln -s '/usr/share/doc/git/contrib/diff-highlight/diff-highlight' '/usr/local/bin/diff-highlight'"
  run_command "Configuring git diff-highlight" "git config --global pager.diff 'diff-highlight'"
  run_command "Configuring git diff-highlight" "git config --global pager.show 'diff-highlight'"
fi

# Add flathub repo if it doesn't exist
#if ! flatpak remotes | grep -q flathub; then
#  run_command "Add flathub repo" "flatpak remote-add --if-not-exists flathub https://flathub.org/repo/flathub.flatpakrepo"
#fi

# Enable flathub repo if it's not enabled
#if ! flatpak remotes | grep -q 'flathub'; then
#  run_command "Enable flathub repo" "flatpak remote-modify --enable flathub"
#fi

# Install Extensions from flathub if it's not already installed
#if ! flatpak list | grep -q org.gnome.Extensions; then
#  run_command "Install Extensions" "flatpak install -y flathub org.gnome.Extensions"
#fi

#gnome-extensions disable background-logo@fedorahosted.org
#gnome-extensions enable window-list@gnome-shell-extensions.gcampax.github.com
#gnome-extensions enable places-menu@gnome-shell-extensions.gcampax.github.com

# Keyboard Shortcuts
# Note: for adding more shortcuts, make sure to increase the the 'custom' id, ex. custom1, custom2 etc.
gsettings set org.gnome.settings-daemon.plugins.media-keys custom-keybindings "['/org/gnome/settings-daemon/plugins/media-keys/custom-keybindings/custom0/']"
gsettings set org.gnome.settings-daemon.plugins.media-keys.custom-keybinding:/org/gnome/settings-daemon/plugins/media-keys/custom-keybindings/custom0/ name "Flameshot"
gsettings set org.gnome.settings-daemon.plugins.media-keys.custom-keybinding:/org/gnome/settings-daemon/plugins/media-keys/custom-keybindings/custom0/ command "flameshot gui"
gsettings set org.gnome.settings-daemon.plugins.media-keys.custom-keybinding:/org/gnome/settings-daemon/plugins/media-keys/custom-keybindings/custom0/ binding "<Ctrl><Alt>Q"

gsettings set org.gnome.desktop.wm.keybindings switch-windows "['<Alt>Tab']"

# Enable minimize and maximize buttons
run_command "Enable minimize and maximize buttons" "gsettings set org.gnome.desktop.wm.preferences button-layout ':minimize,maximize,close'"

# Add startup applications
run_command "Add Firefox to startup applications" "cat <<EOF > ~/.config/autostart/firefox.desktop
[Desktop Entry]
Type=Application
Name=Firefox
Exec=firefox
Hidden=false
NoDisplay=false
X-GNOME-Autostart-enabled=true
X-GNOME-Autostart-Delay=0
EOF"

run_command "Add Yakuake to startup applications" "cat <<EOF > ~/.config/autostart/yakuake.desktop
[Desktop Entry]
Type=Application
Name=Yakuake
Exec=yakuake
Hidden=false
NoDisplay=false
X-GNOME-Autostart-enabled=true
X-GNOME-Autostart-Delay=0
EOF"

install_pycharm
