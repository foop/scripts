#!/bin/sh

# Author:  Dominik Danter
#
# Purpose: Clones or downloads git repository from GitHub
#
#          If git is installed and "--readonly ist not specifed" repository 
#          is cloned. If git is not installed and "--readonly" is specified 
#          the repository will be downloaded using either wget or curl.
#          If the project already exists, it will get updatet
#
# Warning: There is a difference in behaviour depending on whether this
#          script can use git. If git is *not* installed and there is a 
#          directory $target/$reponame to which can be changed and written, 
#          all files therein will be deleted, before intending to get the 
#          repo. If git is installed, this script will intend to change to 
#          this directory and execute git pull.
#
# Bugs:    if project was fetched readonly, it will be updated readonly
#          and gets not promoted, even if "--readonly" was not specified
#
###########################################################################

### CONSTANTS ###
# Usage
readonly USAGE="$0: Usage: $0 <repository_name> [<directory>] [<--readonly>]"
# Messages
readonly MSG_TARGZ="$0: tar and gzip required"
readonly MSG_NO_GIT="$0: No git installed and not readonly (\"-r\" \"--readonly\") specified" 
readonly MSG_REPO_NAME_COLLISON="$0: $repo already exists and is not a writable directory"
# Config
readonly GIT_USERNAME="foop"
readonly URL_PREFIX="https://github.com/${GIT_USERNAME}/"
readonly TAR_COMMAND="tar xz --strip-components=1"
#readonly TAR_OPTIONS="xz --strip-components=1"
readonly TAR_FILE_SUFFIX="/archive/master.tar.gz"
readonly GIT_PREFIX="git@github.com:${GIT_USERNAME}/"
readonly GIT_SUFFIX=".git"
readonly GIT_READ_ONLY_PREFIX="git://github.com/${GIT_USERNAME}/"
# Error Codes
readonly EXIT_ERROR_NO_DOWNLOAD_TOOLS=255
readonly EXIT_ERROR_NO_TAR=254
readonly EXIT_ERROR_NO_GZIP=253
readonly EXIT_ERROR_NO_GIT=252
readonly EXIT_ERROR_ARG=127
readonly EXIT_ERROR_TARGET_DIR=126
readonly EXIT_ERROR_NAME_COLLISON=125
readonly EXIT_ERROR_GIT=1
readonly EXIT_ERROR_WGET=2
readonly EXIT_ERROR_CURL=3
readonly EXIT_ERROR_CHDIR=64
readonly EXIT_ERROR_MKDIR=65
readonly EXIT_ERROR_CLEAN=66 

### vars ###
#fetch_only=false
target_dir="$PWD"
repo="undefined"

### functions ###
# Am I getting paranoid? 
change_to_directory() {
    ctd_target_dir="$1" 
    cd "$ctd_target_dir"
    if [ ! "$?" = 0 ]; then
        echo "$0: Could not change to $ctd_target_dir" >&2;
        exit "$EXIT_ERROR_CHDIR"
    fi
}

make_directory() {
    mkd_target_dir="$1"
    mkdir "$mkd_target_dir"
    if [ ! "$?" = 0 ]; then
        echo "$0: Could not create $mkd_target_dir"
        exit "$EXIT_ERROR_MKDIR"
    fi
}

clean() {
    rm -rf *
    if [ ! "$?" = 0 ]; then
        echo "$0: Could not clean directory $PWD"
        exit "$EXIT_ERROR_CLEAN"
    fi
}

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

# ist there something else than a writable directory named $repo?
# can we cd into it?
if [ -e "$repo" ]; then 
    if [ ! -d "$repo" ] || [ ! -w "$repo" ] || [ ! -x "$repo" ]; then
        echo >&2 "$MSG_REPO_NAME_COLLISON"
        exit "$EXIT_ERROR_NAME_COLLISON"
    fi
fi

# what tools do we have?
#command -v git  >/dev/null 2>&1 &&  git_installed="true"
command -v wget >/dev/null 2>&1 && wget_installed="true"
command -v curl >/dev/null 2>&1 && curl_installed="true"
command -v gzip >/dev/null 2>&1 && gzip_installed="true"
command -v tar  >/dev/null 2>&1 &&  tar_installed="true"

# ERROR: No tools are installed
if [ ! git_installed ] && [ ! wget_installed ] && [ ! curl_installed ]; then
    echo >&2 "$0: I require either git, wget or curl to be installed" 
    exit "$EXIT_ERROR_NO_DOWNLOAD_TOOLS"
fi

change_to_directory $target_dir

### git ###
if [ "$git_installed" ]; then 
    # try update if repo already exists
    if [ -e "$repo" ]; then 
        change_to_directory "$repo"
        git pull
        [ $? -eq 0 ] && exit 
    else 
    # try clone
        prefix="$GIT_PREFIX"
        [ $fetch_only ] && prefix="$GIT_READ_ONLY_PREFIX"
        git clone >&2 "${prefix}${repo}${GIT_SUFFIX}"
        [ $? -eq 0 ] && exit 
    fi
    exit "$EXIT_ERROR_GIT"
fi

if [ ! $fetch_only ]; then
    echo >&2 "$MSG_NO_GIT"
    exit "$EXIT_ERROR_NO_GIT"
fi

### not git ###
# we will need tar and gzip

#TODO may be it is not such a good idea to clean and then fetch
#     what if we have no internet connection? Maybe we still want
#     to use the scripts even if we cannot update.
#     possible solutions include: make backup, test connection,
#                                 use tmp folder

if [ ! "$tar_installed" ]; then 
    echo >&2 "$MSG_TARGZ"
    exit "$EXIT_ERROR_NO_TAR"
fi

if [ ! "$gzip_installed" ]; then
    echo >&2 "$MSG_TARGZ"
    exit "$EXIT_ERROR_NO_GZIP"
fi

if [ -e "$repo" ]; then
    change_to_directory $repo     
    clean
else
    make_directory $repo
    change_to_directory $repo
fi 

### curl ###
if [ "$curl_installed" ]; then
    curl -L ${URL_PREFIX}${repo}${TAR_FILE_SUFFIX} | $TAR_COMMAND
    [ $? -eq 0 ] && exit
    exit "$EXIT_ERROR_CURL"
fi

### wget ###
if [ "$wget_installed" ]; then
    wget --no-check-certificate ${URL_PREFIX}${repo}${TAR_FILE_SUFFIX} -O - | tar $TAR_COMMAND
    [ $? -eq 0 ] && exit
    exit "$EXIT_ERROR_WGET"
fi
