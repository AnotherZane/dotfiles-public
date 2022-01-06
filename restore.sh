#!/bin/bash

RECURSIVE=false
LINK_FOLDER="./files"
FOLDERS="./folders.txt"

# FUNCTIONS
help()
{
  # Display help
  echo "A simple script to restore dotfiles from their hardlink."
  echo
  echo "Syntax: ./restore.sh [-r|h] <path>"
  echo
  echo "Arguments:"
  echo "path  Path of the file or folder to restore."
  echo "      This path must be in ./files."
  echo
  echo "Options:"
  echo "r     Restore recursively, if the path is a folder."
  echo "h     Print this help menu."
  echo
}

restore_file() {
  file=${2##*/}
  dir=${2%/*}

  if [[ $dir != $2 ]]; then
    if [ ! -d $HOME/$dir ]; then
      echo "Creating directory $HOME/$dir for file $file to be restored"
      mkdir -p $HOME/$dir
    else
      echo "Found existing directory $HOME/$dir for file $file to be restored"
    fi
  fi

  if [ -f $HOME/$2 ]; then
    echo "Found existing file $2, backing up..."
    mv $HOME/$2 $HOME/$2.bak
    echo "Backed up to $HOME/$2.bak"
  fi
    
  echo "Restoring file: $HOME/$2"
  ln $1 $HOME/$2
}

restore_dir() {
  if [ ! -d $HOME/$dir ]; then
    echo "Creating directory $HOME/$dir"
    mkdir -p $HOME/$dir
  else
    echo "Found existing directory $HOME/$dir"
  fi

  files="$1/*"
  for file in $files
  do
    rel=${file#$LINK_FOLDER_PATH/}

    if [ -f $file ]; then
      restore_file $file $rel true
    elif [ $3 = true ]; then
      restore_dir $file $rel true
    fi
  done
}

# MAIN SCRIPT

LINK_FOLDER=`dirname $0`
LINK_FOLDER=`readlink -f $LINK_FOLDER`
LINK_FOLDER=$LINK_FOLDER/files

while getopts "hr" opt; do
  case $opt in
    h) help; exit ;;
    r) RECURSIVE=true ;;
    :) echo "Missing argument for option -$OPTARG"; exit 1;;
    \?) echo "Unknown option -$OPTARG"; exit 1;;
  esac
done

shift $(( OPTIND - 1 ))

for arg in "$@"
do
  if [[ $arg == "" ]]; then
    echo "No path provided. Use ./link.sh -h to see valid syntax."
    exit 1
  fi

  LINK_FOLDER_PATH=`readlink -f $LINK_FOLDER`
  LINK_PATH=`readlink -f $arg`

  if [[ $LINK_PATH != $LINK_FOLDER_PATH* ]]; then
    echo "$LINK_PATH: Provided path is not in the $LINK_FOLDER directory."
    exit 1
  elif [[ $LINK_PATH == $LINK_FOLDER_PATH ]]; then
    echo "Provided path is the $LINK_FOLDER directory. Exiting to prevent files be unnecessarily linked."
    exit 1
  fi

  if [ -f $LINK_PATH ]; then
    is_file=true
  elif [ -d $LINK_PATH ]; then
    is_file=false
  else
    echo "$LINK_PATH: No such file or directory."
    exit 1
  fi

  REL_PATH=${LINK_PATH#$LINK_FOLDER_PATH/}

  if [ $is_file = true ]; then
    restore_file $LINK_PATH $REL_PATH false
  else
    restore_dir $LINK_PATH $REL_PATH $RECURSIVE
  fi
done

echo "Done"
