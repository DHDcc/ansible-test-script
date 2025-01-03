#!/usr/bin/env bash

repoName="archlinux-ansible"
branchName="testing"
defaultPlaybookName="playbooks"
playbookDir="$HOME/${repoName}/ansible"
tagName="${3}" 

error(){ >&2 echo "Failed to change directory to $1"; exit 1; }
ansibleOptions(){
  local changeOptions=false
  local ansibleOptionsFile="${playbookDir}/group_vars/all/options.yml"
  local options=(
          "hypervisor"
          "gaming_packages" 
  )

  if [[ "${changeOptions}" ]]; then
       for op in "${Options[@]}"; do
           local lineNumber=$(grep -n "${op}" "${ansibleOptionsFile}" | awk -F':' '{print $1}')
           sed -i "${lineNumber}s/false/true/" "${ansibleOptionsFile}"
       done
  fi
}

usage() {
    local scriptName="${0##*/}"
    cat << EOF
usage: ${scriptName} [options] <tag_name>

    -t	add a tag
    -r  run all the playbooks
    -h	Show this help
EOF
}

fixSystem(){
  local options=("init" "refresh" "updatedb" "populate")

  for op in "${options[@]}"; do
    if [[ "${op}" != "populate" ]]; then 
	   sudo pacman-key --"${op}"
    else
           sudo pacman-key --"${op}" archlinux
    fi 
  done

  sudo pacman-key --populate archlinux
  sudo trust extract-compat
}

otherPlaybook(){ # fix fonction 
     local helperName="paru-bin"
     local defaultPlaybookName=${tagName}
     git clone https://aur.archlinux.org/"${helperName}".git
     ( cd "${helperName}" && makepkg -si )
     mv inventory/ ansible.cfg "${defaultPlaybookName}"
     cd  "${defaultPlaybookName}" || error "${defaultPlaybookName}"
}

  
main(){
  local repoUrl="https://github.com/DHDcc/${repoName}.git"
  local dependencies=("base-devel" "ansible" "git" "python-psutil")

  for dep in "${dependencies[@]}"; do
      if ! command -v "${dep}" &> /dev/null; then
	     sudo pacman -S --noconfirm --needed "${dep}"
      fi
  done
  
  cd "$HOME" || error "$HOME"
  if ! git clone -b "${branchName}" "${repoUrl}"; then 
         >&2 echo "Failed to clone repo: ${repoName}"
	 exit 1
  fi

  cd  "${playbookDir}" || error "${playbookDir}"
  ansible-galaxy collection install -r requirements.yml
  ansibleOptions
}
	  
case "$1" in
	-t) main && otherPlaybook && ansible-playbook --tags "${tagName}" --ask-become-pass main.yml && exit ;;

        -r) main && ansible-playbook --ask-become-pass playbooks.yml && exit ;;
 
        *) usage && exit 1 ;;       

esac
