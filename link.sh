#!/bin/bash

RECURSIVE=false
LINK_FOLDER="./files"
FOLDERS="./folders.txt"

# FUNCTIONS
help()
{
  # Display help
  echo "A simple script to create a hardlink to a dotfile."
  echo
  echo "Syntax: ./link.sh [-r|h] <path>"
  echo
  echo "Arguments:"
  echo "path  Path of the file or folder to create a link to."
  echo
  echo "Options:"
  echo "r     Create links recursively, if the path is a folder."
  echo "h     Print this help menu."
  echo
}

link_file() {
  file=${2##*/}
  dir=${2%/*}

  if [[ $dir != $2 ]]; then
    if [ ! -d $LINK_FOLDER/$dir ]; then
      echo "Creating directory $LINK_FOLDER/$dir for link file $file"
      mkdir -p $LINK_FOLDER/$dir
      echo $dir >> $FOLDERS
    else
      echo "Found existing directory $LINK_FOLDER/$dir for link file $file"
    fi
  fi

  if [ -f $LINK_FOLDER/$2 ]; then
    echo "Found existing link for $1"

    # File from link_dir?
    if [ $3 = false ]; then
      exit 1;
    fi
  else
    echo "Creating link file: $LINK_FOLDER/$2"
    ln $1 $LINK_FOLDER/$2
  fi
}

link_dir() {
  if [ ! -d $LINK_FOLDER/$dir ]; then
    echo "Creating directory $LINK_FOLDER/$dir"
    mkdir -p $LINK_FOLDER/$dir
    echo $dir >> $FOLDERS
  else
    echo "Found existing directory $LINK_FOLDER/$dir"
  fi

  files="$1/*"
  for file in $files
  do
    rel=${file#$HOME/}

    if [ -f $file ]; then
      link_file $file $rel true
    elif [ $3 = true ]; then
      link_dir $file $rel false
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

  LINK_PATH=`readlink -f $arg`

  if [[ $LINK_PATH != $HOME* ]]; then
    echo "$LINK_PATH: Provided path is not in the home directory."
    exit 1
  elif [[ $LINK_PATH == $HOME ]]; then
    echo "Provided path is the home directory. Exiting to prevent files be unnecessarily linked."
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

  REL_PATH=${LINK_PATH#$HOME/}

  if [ $is_file = true ]; then
    link_file $LINK_PATH $REL_PATH false
  else
    link_dir $LINK_PATH $REL_PATH $RECURSIVE
  fi
done

echo "Done"
