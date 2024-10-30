#!/bin/bash

# Check if the script is being run as root or with sudo
if [[ $EUID -ne 0 ]]; then
  echo "This script must be run as root or with sudo privileges."
  exit 1
fi

shopt -s nullglob

pause(){
  read -p "press [ENTER] key to continue" fakeenter
}

assignmodules(){
    set -- modules/*
    modules=(0 "${@/#./modules/}")
    unset 'modules[0]'
    declare -p modules # Optionally show result
}

menu(){
  echo -e "ubuntool"
  echo -e "by nobody65534"
  echo -e ""
  (( i % 2 )) && echo
  echo -e "\e[0m"
}

assignmodules

read_options(){
  echo "Choose a module to run:"
  select module in $(ls ./modules)
  do
      if [ -f "./modules/$module" ]; then
          echo "Running $module..."
          ./modules/$module
          break
      else
          echo "Invalid option. Please try again."
      fi
  done
}

while true
do
  clear
  menu
  read_options
done