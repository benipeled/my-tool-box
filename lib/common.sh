#!/bin/bash

GREEN="\e[32m"
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
  cmd_message="$1"
  print_start "$cmd_message"
  cmd_output=$(eval "$2" 2>&1)
  cmd_return_code=$?
  if [[ $cmd_return_code -ne 0 ]]; then
    print_fail "$cmd_message"
    print_output "$cmd_message" "$cmd_output"
    return 1
  fi
  if [[ $DEBUG ]]; then
    print_output "$cmd_message" "$cmd_output"
  fi
  print_finish "$cmd_message"
}

install_packages() {
  local packages="$1"
  run_command "Installing packages" "sudo apt-get install -y $packages"
}

clone_repos() {
  local repo_folder="$1"
  shift
  local repos=("$@")

  if [ ! -d "$repo_folder" ]; then
    run_command "Create $repo_folder folder" "mkdir -p $repo_folder"
  fi

  for repo_url in "${repos[@]}"; do
    local repo_name=$(basename "$repo_url" .git)
    local repo_path="$repo_folder/$repo_name"

    if [ ! -d "$repo_path" ]; then
      run_command "Clone $repo_name" "git clone $repo_url $repo_path"
    else
      print_skip "$repo_name already exists"
    fi
  done
}
