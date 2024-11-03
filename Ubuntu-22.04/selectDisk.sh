#!/bin/bash

set +e

function init()
{
  AUTOINSTALL_FILE=/autoinstall.yaml
  MENU_WIDTH=65
  MENU_HEIGHT=25
  MENU_INT_HEIGHT=10

  #Change to tty3 to display the dialog
  chvt 3 &>/dev/null
  export TERM=linux
  export NCURSES_NO_UTF8_ACS=1
  printf "\ec"
  export NEWT_COLORS='
  root=,black
  window=white,blue
  title=white,blue
  border=white,blue
  textbox=white,blue
  acttextbox=black,yellow
  listbox=white,blue
  sellistbox=black,yellow
  actlistbox=black,yellow
  actsellistbox=black,yellow
  button=black,yellow
  actbutton=black,yellow
  compactbutton=white,blue
  checkbox=white,blue
  actcheckbox=black,yellow
  '
  menuheader=$(cat << EOF

                #============================#
                        Disk Selection        
                #============================#

EOF
  )
}

function main()
{
  echo "SELECT_DISK_DEBUG: begin init"
  init
  echo "SELECT_DISK_DEBUG: begin selectDisk"
  selectDisk
  echo "SELECT_DISK_DEBUG: begin terminate"
  terminate
  echo "SELECT_DISK_DEBUG: end"
}

function selectDisk()
{
  OLDIFS=$IFS
  IFS=$(echo -en "\n\b")
  diskarr=($(hwinfo --disk --short | tail +2))
  IFS=$OLDIFS
  echo "SELECT_DISK_DEBUG: after diskarr"
  numDisk=${#diskarr[@]}
  echo "SELECT_DISK_DEBUG: numDisk is $numDisk"
  if [ $numDisk -le 0 ] || [ $numDisk -ge 20 ]; then
    # Something went wrong, just do interactive
    showMessageBox "Interactive Storage" "There was an unknown error detecting your hardware disks. You will be prompted later in the setup for storage configuration."
    setStorageInteractive
    return
  fi
  echo "SELECT_DISK_DEBUG: begin show menu"
  dbackmenu=$(cat << EOF

$menuheader

EOF
)
  OLDIFS=$IFS
  IFS=$(echo -en "\n\b")
  curListNum=1
  scsbm_menu_items=( --title "Select Disk" --radiolist "$dbackmenu" $MENU_HEIGHT $MENU_WIDTH $MENU_INT_HEIGHT )
  scsbm_menu_items+=( "Manual - Configure Disk Installation Manually" )
  scsbm_menu_items+=( "|" )
  scsbm_menu_items+=( "on" )
  ((curListNum++))
  for curDisk in "${diskarr[@]}"
  do
    curDiskID=$(echo "$curDisk" | xargs | cut -d" " -f1)
    curDiskName=$(echo "$curDisk" | xargs | cut -d" " -f2-)
    curDiskSize=$(lsblk -o SIZE --noheadings --raw -d $curDiskID)
    curDiskParts=$(partx -g $curDiskID 2> /dev/null | wc -l)
    scsbm_menu_items+=( "$curDiskID  $curDiskSize  ($curDiskParts Partitions)  $curDiskName" )
    scsbm_menu_items+=( "|" )
    scsbm_menu_items+=( "off" )
    ((curListNum++))
  done
  IFS=$OIFS
  selDiskItem=$(whiptail "${scsbm_menu_items[@]}" 3>&1 1>&2 2>&3)
  retVal=$?
  echo "SELECT_DISK_DEBUG: end show menu"
  if [ $retVal -ne 0 ]; then
    showMessageBox "Interactive Storage" "You selected to cancel this request. You will be prompted later in the setup for storage configuration."
    setStorageInteractive
    return
  fi
  selDisk=$(echo "$selDiskItem" | cut -d" " -f1)
  echo "SELECT_DISK_DEBUG: disk selected"
  if [ "$selDisk" = "Manual" ]; then
    showMessageBox "Interactive Storage" "You have selected interactive storage. You will be prompted later in the setup for storage configuration."
    setStorageInteractive
  else
    sed -i "s|REPLACE_DRIVE|$selDisk|" $AUTOINSTALL_FILE
    showMessageBox "Disk Selected" "You selected the disk: $selDisk. The OS will be installed on this disk. You will be prompted for confirmation at the end of the setup."
  fi
  echo "SELECT_DISK_DEBUG: end main"
}

function setStorageInteractive()
{
  sed -i "/- identity/a\- storage" $AUTOINSTALL_FILE
  sed -i "s|REPLACE_DRIVE|/dev/sda|" $AUTOINSTALL_FILE
}

function showMessageBox()
{
  msgmenu=$(cat << EOF

$menuheader

$2
EOF
  )
  whiptail --title "$1" --msgbox "$msgmenu" $MENU_HEIGHT $MENU_WIDTH
}

function terminate()
{
  chvt 1 &>/dev/null
}

main "$@"
