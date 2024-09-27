#!/usr/bin/env bash

repoName="archlinux-ansible"
branchName="testing"
playbookName="playbook"
playbookDir="$HOME/${repoName}/ansible"
tagName="${2}"

error(){ >&2 echo "Failed to change directory to $1"; exit 1; }
changeDirectory(){ cd "$1" &> /dev/null; $SHELL ; }
removeAurFont(){ sed -i "64d" group_vars/all/vars.yml ; }

fixParu(){
  local options=("init" "refresh" "updatedb" "populate")

  for op in "${options[@]}"; do
    if [[ "${op}" != "populate" ]]; then 
	   sudo pacman-key --"${op}"
    fi 
  done 
  sudo pacman-key --"${options[3]}" archlinux
  sudo trust extract-compat
}

main(){
  local repoUrl="https://github.com/DHDcc/${repoName}.git"
  local dependencies=("base-devel" "ansible" "git" "python-psutil")

  for dep in "${dependencies[@]}"; do
      if ! command -v "${dep}" &> /dev/null; then
	     sudo pacman -Syu --noconfirm --needed "${dep}"
      fi
  done
  
  changeDirectory "$HOME" || error "$HOME"
  if ! git clone -b "${branchName}" "${repoUrl}"; then 
         >&2 echo "Failed to clone repo: ${repoName}"
	 exit 1
  fi

  changeDirectory "${playbookDir}" || error "${playbookDir}"
  ansible-galaxy collection install -r requirements.yml
  removeAurFont 
}

case "$1" in
	--tags) main && ansible-playbook --tags "${tagName}" --ask-become-pass "${playbookName}".yml
		;;

        *) main && ansible-playbook --ask-become-pass "${playbookName}".yml
	   ;;

esac


            
