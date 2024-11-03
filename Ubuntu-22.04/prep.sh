#!/bin/bash

UTILS_LIST="whiptail|whiptail awk|awk screen|screen pwgen|pwgen argon2|argon2 dig|dnsutils htpasswd|apache2-utils sshpass|sshpass wg|wireguard-tools qrencode|qrencode openssl|openssl faketime|faketime bc|bc sipcalc|sipcalc jq|jq git|git http|httpie sqlite3|sqlite3 curl|curl awk|awk sha1sum|sha1sum nano|nano cron|cron ping|iputils-ping route|net-tools grepcidr|grepcidr networkd-dispatcher|networkd-dispatcher certutil|libnss3-tools gpg|gnupg python3|python3 pip3|python3-pip unzip|unzip hwinfo|hwinfo netplan|netplan.io avahi-daemon|avahi-daemon"
APT_REMOVE_LIST="vim vim-tiny vim-common xxd binutils"

function main()
{
  installDependencies
}

function installDependencies()
{
  apt update && apt upgrade -y
  for util in $UTILS_LIST; do
    if [[ "$(isProgramInstalled $util)" = "false" ]]; then
      lib_name=$(echo $util | cut -d"|" -f2)
      echo "Installing $lib_name, please wait..."
      performAptInstall $lib_name
    fi
  done
  for rem_util in $APT_REMOVE_LIST; do
    if [[ "$(isProgramInstalled $util)" = "true" ]]; then
      DEBIAN_FRONTEND=noninteractive apt remove -y $rem_util
    fi
  done
}

function isProgramInstalled()
{
  bin_name=$(echo $1 | cut -d"|" -f1)
  lib_name=$(echo $1 | cut -d"|" -f2)
  if [[ -z $(which ${bin_name}) ]]; then
    echo "false"
  else
    echo "true"
  fi
}

function performAptInstall()
{
  DEBIAN_FRONTEND=noninteractive apt install -y -o Dpkg::Options::='--force-confdef' -o Dpkg::Options::='--force-confold' $1
}

main "$@"
