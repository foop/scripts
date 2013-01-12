#!/bin/sh

# Author:  Dominik Danter
#
# Purpose: Clones or downloads git repository from GitHub
#
#          If git is installed and "--readonly ist not specifed" repository 
#          is cloned. If git is not installed and "--readolny" is specified 
#          the repository will be downloaded using either wget or curl.
#
# Bugs:    The repository may be named differently depending on wheter it 
#          is fetched by git or (wget or curl). If repo "foo" is fetched by
#          wget or curl the folder will be named foo-master
#
###########################################################################

### CONSTANTS ###
# Usage
readonly USAGE="$0: Usage: $0 <repository_name> [<directory>] [<--readonly>]"
# Messages
readonly MSG_TARGZ="$0: tar and gzip required"
readonly MSG_NO_GIT="$0: No git installed and not readonly (\"-r\" \"--readonly\") specified" 
# Config
readonly GIT_USERNAME="foop"
readonly URL_PREFIX="https://github.com/${GIT_USERNAME}/"
readonly TAR_SUFFIX="/archive/master.tar.gz"
readonly GIT_PREFIX="git@github.com:${GIT_USERNAME}/"
readonly GIT_SUFFIX=".git"
readonly GIT_READ_ONLY_PREFIX="git://github.com/${GIT_USERNAME}/"
# Error Codes
readonly EXIT_ERROR_NO_DOWNLOAD_TOOLS=255
readonly EXIT_ERROR_NO_TAR=254
readonly EXIT_ERROR_NO_GZIP=253
readonly EXIT_ERROR_NO_GIT=253
readonly EXIT_ERROR_ARG=127
readonly EXIT_ERROR_TARGET_DIR=126
readonly EXIT_ERROR_GIT=1
readonly EXIT_ERROR_WGET=2
readonly EXIT_ERROR_CURL=3

### vars ###
#fetch_only=false
target_dir="$PWD"
repo="undefined"

###########################################################################

### args parsing ###
if [ "$#" -gt 3 ] || [ "$#" -lt 1 ]; then
    echo "$USAGE" >&2
    echo "You have not provided the correct amount of arguments" >&2;
    exit "$EXIT_ERROR_ARG"
fi

if [ "$1" = "-h" ] || [ "$1" = "--help" ]; then
    echo "$USAGE"
    exit
fi

if [ "$#" -eq 3 ]; then
    if [ ! -d "$2" ] ; then
        echo "$USAGE" >&2
        echo "$0: $2 is not a directory">&2
        exit "$EXIT_ERROR_ARG"
    fi
    if [ ! "$3" = "--readonly" ] && [ ! "$3" = "-r" ]; then
        echo "$USAGE" >&2
        echo "$0: \"$3\" must be \"--readonly\" or \"-r\""
        exit "$EXIT_ERROR_ARG"
    fi
    target_dir="$2"
    fetch_only="true"
fi 

if [ "$#" -eq 2 ]; then
    if [ -d $2 ]; then
        target_dir="$2"
    elif [ "$2" = "-r" ] || [ "$2" = "--readonly" ]; then
        fetch_only="true"
    else 
        echo "$USAGE" >&2
        echo "$0: $2 must be a directory or \"--readonly\" or \"-r\""
        exit "$EXIT_ERROR_ARG"
    fi
fi

repo="$1"

### checks ###
# check if we can write to target directory
if [ ! -w "$target_dir" ]; then
    echo >&2 "$0: $target_dir is not writable"
    exit "$EXIT_ERROR_TARGET_DIR"
fi
if [ ! -x "$target_dir" ]; then
    echo >&2 "$0; $target_dir is not executable"
    exit "$EXIT_ERROR_TARGET_DIR"
fi

# what tools do we have?
command -v git  >/dev/null 2>&1 &&  git_installed="true"
command -v wget >/dev/null 2>&1 && wget_installed="true"
command -v curl >/dev/null 2>&1 && curl_installed="true"
command -v gzip >/dev/null 2>&1 && gzip_installed="true"
command -v tar  >/dev/null 2>&1 &&  tar_installed="true"

# ERROR: No tools are installed
if [ ! git_installed ] && [ ! wget_installed ] && [ ! curl_installed ]; then
    echo >&2 "$0: I require either git, wget or curl to be installed" 
    exit "$EXIT_ERROR_NO_DOWNLOAD_TOOLS"
fi

cd $target_dir

### git ###
if [ "$git_installed" ]; then 
    prefix="$GIT_PREFIX"
    [ $fetch_only ] && prefix="$GIT_READ_ONLY_PREFIX"
    git clone "${prefix}${repo}${GIT_SUFFIX}"
    [ $? -eq 0 ] && exit 
    exit "$EXIT_ERROR_GIT"
fi

if [ ! $fetch_only ]; then
    echo >&2 "$MSG_NO_GIT"
    exit "$EXIT_ERROR_NO_GIT"
fi

### not git ###
# we will need tar and gzip
if [ ! "$tar_installed" ]; then 
    echo >&2 "$MSG_TARGZ"
    exit "$EXIT_ERROR_NO_TAR"
fi

if [ ! "$gzip_installed" ]; then
    echo >&2 "$MSG_TARGZ"
    exit "$EXIT_ERROR_NO_GZIP"
fi

### curl ###
if [ "$curl_installed" ]; then
    curl -L ${URL_PREFIX}${repo}${TAR_SUFFIX} | tar xz
    [ $? -eq 0 ] && exit
    exit "$EXIT_ERROR_CURL"
fi

### wget ###
if [ "$wget_installed" ]; then
    wget --no-check-certificate ${URL_PREFIX}${repo}${TAR_SUFFIX} -O - | tar xz
    [ $? -eq 0 ] && exit
    exit "$EXIT_ERROR_WGET"
fi
