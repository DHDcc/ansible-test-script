#!/usr/bin/env bash

repoName="archlinux-ansible"
branchName="testing"
defaultPlaybookName="playbooks"
NewPlaybookName="${2}"
playbookDir="$HOME/${repoName}/ansible"

error(){ >&2 echo "Failed to change directory to $1"; exit 1; }
changeDirectory(){ cd "$1" &> /dev/null; $SHELL ; }
noHypervisor(){ sed -i "16,20d" hypervisor/hypervisor.yml ; }

fixParu(){
  local options=("init" "refresh" "updatedb" "populate")

  for op in "${options[@]}"; do
    if [[ "${op}" != "populate" ]]; then 
	   sudo pacman-key --"${op}"
    else
           sudo pacman-key --"${op}" archlinux
    fi 
  done

  sudo trust extract-compat
}

NewPlaybook(){
     git clone https://aur.archlinux.org/paru-bin.git
     ( cd paru-bin && makepkg -si )
     mv inventory/ ansible.cfg "${NewPlaybookName}"
     changeDirectory "${NewPlaybookName}" || error "${NewPlaybookName}"
}

  
main(){
  local repoUrl="https://github.com/DHDcc/${repoName}.git"
  local dependencies=("base-devel" "ansible" "git" "python-psutil")

  for dep in "${dependencies[@]}"; do
      if ! command -v "${dep}" &> /dev/null; then
	     sudo pacman -S --noconfirm --needed "${dep}"
      fi
  done
  
  changeDirectory "$HOME" || error "$HOME"
  if ! git clone -b "${branchName}" "${repoUrl}"; then 
         >&2 echo "Failed to clone repo: ${repoName}"
	 exit 1
  fi

  changeDirectory "${playbookDir}" || error "${playbookDir}"
  ansible-galaxy collection install -r requirements.yml
  noHypervisor
  [[ -n "${NewPlaybookName}" ]] && NewPlaybook

}

main && [[ -n "${NewPlaybookName}" ]] && ansible-playbook --ask-become-pass "${defaultPlaybookName}".yml || ansible-playbook --ask-become-pass main.yml
	  


            
