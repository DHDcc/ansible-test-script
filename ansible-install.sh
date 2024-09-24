#!/usr/bin/env bash

repoName="archlinux-ansible"
branchName="testing"
playbookName="playbook"
playbookDir="$HOME/${repoName}/ansible"
tagName="${2}"

fixParu(){
  sudo pacman-key --init
  sudo pacman-key --populate archlinux
  sudo pacman-key --refresh
  sudo pacman-key --updatedb
  #sudo timedatectl set-ntp true 
  sudo trust extract-compat
}

main(){
  local repoUrl="https://github.com/DHDcc/${repoName}.git"
  local dependencies=("base-devel" "ansible" "git" "python-psutil")

  changeDirectory(){ cd "$1" &> /dev/null; $SHELL ; }

  for dep in "${dependencies[@]}"; do
      if ! command -v "${dep}" &> /dev/null; then
	     sudo pacman -Syu --noconfirm --needed "${dep}"
      fi
  done
  
  changeDirectory "$HOME"
  if ! git clone -b "${branchName}" "${repoUrl}"; then 
         >&2 echo "Failed to clone repo: ${repoName}"
	 exit 1
  fi

  changeDirectory "${playbookDir}" || { >&2 echo "Failed to change directory to ${playbookDir}"; exit 1; }
  ansible-galaxy collection install -r requirements.yml
}
  
removeForVm(){ sed -i "64d" group_vars/all/vars.yml && sed -i "20,24d" roles/hypervisor/tasks/hypervisor.yml ; }

case "$1" in
	--tags) main && removeForVm && ansible-playbook --tags "${tagName}" --ask-become-pass "${playbookName}".yml
		;;

        *) main && removeForVm && ansible-playbook --ask-become-pass "${playbookName}".yml
	   ;;

esac


            
