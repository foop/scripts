#!/bin/sh
#                                            get_repo.sh  Copyright (C) 2013
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
#          You even can update the repo where this very script lives with  <---- R E A D    T H I S !
#          this file. This must however be the last repository that you
#          specify if you create a batch file fetching or updating multiple
#          repos. 
#
#
# License:                                                                 <---- A N D      T H I S ! 
#          This program is free software: you can redistribute it and/or modify
#          it under the terms of the GNU General Public License as published by
#          the Free Software Foundation, either version 3 of the License, or
#          (at your option) any later version.
#
#          This program is distributed in the hope that it will be useful,
#          but WITHOUT ANY WARRANTY; without even the implied warranty of
#          MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
#          GNU General Public License for more details.
#
#          You should have received a copy of the GNU General Public License
#          along with this program. If not, see <http://www.gnu.org/licenses/>  
#
# Contact the author: 
#          http://foop.at
#          dominik@foop.at
#          
##############################################################################

### CONSTANTS ###
# Usage
readonly USAGE="$0: Usage: $0 <repository_name> [<directory>] [<--readonly>]"
# Messages
readonly MSG_TARGZRM="$0: rm, tar and gzip required"
readonly MSG_NO_GIT="$0: No git installed and not readonly (\"-r\" \"--readonly\") specified" 
readonly MSG_REPO_NAME_COLLISON="$0: $repo already exists and is not a writable directory"
## Config ##
# git all
readonly GIT_USERNAME="foop"
readonly GIT_SUFFIX=".git"
# git write access
readonly GIT_PREFIX="git@github.com:${GIT_USERNAME}/"
# git read access
readonly GIT_READ_ONLY_PREFIX="git://github.com/${GIT_USERNAME}/"
# curl/wget url
readonly URL_PREFIX="https://github.com/${GIT_USERNAME}/"
# tar
readonly TAR_COMMAND="tar --strip-components=1 -xzf"
readonly TAR_FILE_SUFFIX="/archive/master.tar.gz"
## Error Codes ##
readonly EXIT_ERROR_NO_DOWNLOAD_TOOLS=255
readonly EXIT_ERROR_NO_TAR=254
readonly EXIT_ERROR_NO_GZIP=253
readonly EXIT_ERROR_NO_GIT=252
readonly EXIT_ERROR_NO_RM=251
readonly EXIT_ERROR_NO_MV=250
readonly EXIT_ERROR_ARG=127
readonly EXIT_ERROR_TARGET_DIR=126
readonly EXIT_ERROR_NAME_COLLISON=125
readonly EXIT_ERROR_GIT=1
readonly EXIT_ERROR_WGET=2
readonly EXIT_ERROR_CURL=3
readonly EXIT_ERROR_CHDIR=64
readonly EXIT_ERROR_MKDIR=65
readonly EXIT_ERROR_CLEAN=66 
readonly EXIT_ERROR_CLEAN_TMP=67 
readonly EXIT_ERROR_MVDIR=68 
### vars ###
#fetch_only=false
target_dir="$PWD"
repo="undefined"
#output_tmp_filename="defined_after_args_parsing"

### check tools ###
command -v git  >/dev/null 2>&1 &&  git_installed="true"
command -v wget >/dev/null 2>&1 && wget_installed="true"
command -v curl >/dev/null 2>&1 && curl_installed="true"
command -v gzip >/dev/null 2>&1 && gzip_installed="true"
command -v tar  >/dev/null 2>&1 &&  tar_installed="true"
command -v rm   >/dev/null 2>&1 &&   rm_installed="true"
command -v mv   >/dev/null 2>&1 &&   mv_installed="true"

### functions ###
# Am I getting paranoid? 
change_to_directory() {
    ctd_target_dir="$1" 
    cd "$ctd_target_dir"
    if [ ! "$?" = 0 ]; then
        echo "$0: Could not change to $ctd_target_dir" >&2
        exit "$EXIT_ERROR_CHDIR"
    fi
}

make_directory() {
    mkd_target_dir="$1"
    mkdir "$mkd_target_dir"
    if [ ! "$?" = 0 ]; then
        echo "$0: Could not create $mkd_target_dir" >&2
        exit "$EXIT_ERROR_MKDIR"
    fi
}

clean() {
    clean_dir="$1"
    if [ "$rm_installed" ]; then
        rm -rf "${clean_dir}"
        if [ ! "$?" = 0 ]; then
            echo "$0: Could not clean directory ${clean_dir}" >&2
            exit "$EXIT_ERROR_CLEAN"
        fi
    else 
        echo "$0: rm is not installed" >&2
        exit "$EXIT_ERROR_NO_RM"
    fi
}

clean_tmp_file() {
    ctf_tmp_file="$1"
    if [ -e $ctf_tmp_file ]; then
        rm "$ctf_tmp_file"
        if [ ! "$?" = 0 ]; then
            echo "$0: Could not clear tmp file $ctf_tmp_file" >&2
            exit "$EXIT_ERROR_CLEAN_TMP"
        fi
    fi
}

mvdir() {
    mvdir_old="$1"
    mvdir_new="$2"
    if [ "$mv_installed" ]; then
        mv "$mvdir_old" "$mvdir_new"
        if [ ! "$?" = 0 ]; then
            echo "$0: Colud not mv $mvdir_old to $mvdir_new" >&2
            exit "$EXIT_ERROR_MVDIR"
        fi
    else
        echo "$0: No mv installed" >&2
        exit "$EXIT_ERROR_NO_MV" 
    fi
}

convert_to_git() {
    cvt_to_git="$1"
    cvt_to_git_clone_args="$2"
    cvt_to_git_tmp="${cvt_to_git}-tmp"
    mvdir "$cvt_to_git" "$cvt_to_git_tmp" 
    make_directory "$cvt_to_git" 
    clone "$cvt_to_git_clone_args"
    clean "$cvt_to_git_tmp"
}
        
clone() {
    clone_arg="$1"
    git clone >&2 "$clone_arg"
    if [ ! "$?" -eq 0 ]; then
        echo "$0: Could not glone: git clone $clone_arg"
        exit "$EXIT_ERROR_GIT"
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
output_tmp_filename="tmp-${GIT_USERNAME}-${repo}.tar.gz"

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


# ERROR: No tools are installed
if [ ! "$git_installed" ] && [ ! "$wget_installed" ] && [ ! "$curl_installed" ]; then
    echo >&2 "$0: I require either git, wget or curl to be installed" 
    exit "$EXIT_ERROR_NO_DOWNLOAD_TOOLS"
fi

change_to_directory $target_dir

### git ###
if [ "$git_installed" ]; then 
    prefix="$GIT_PREFIX"
    [ "$fetch_only" ] && prefix="$GIT_READ_ONLY_PREFIX"
    git_args="${prefix}${repo}${GIT_SUFFIX}"
    # try update if repo already exists
    if [ -e "$repo" ]; then 
        # is this a git folder?
        if [ -e "${repo}/.git" ]; then
            change_to_directory "$repo"
            git pull
            [ "$?" -eq 0 ] && exit
# or try using wget/curl
        else
            convert_to_git "$repo" "$git_args"
            exit
        fi
    else 
        # try clone
        clone "$git_args"
        exit;
    fi
    exit "$EXIT_ERROR_GIT"
fi

if [ ! "$fetch_only" ]; then
    echo >&2 "$MSG_NO_GIT"
    exit "$EXIT_ERROR_NO_GIT"
fi

### not git ###
# we will need rm, tar and gzip

if [ ! "$tar_installed" ]; then 
    echo >&2 "$MSG_TARGZRM"
    exit "$EXIT_ERROR_NO_TAR"
fi

if [ ! "$gzip_installed" ]; then
    echo >&2 "$MSG_TARGZRM"
    exit "$EXIT_ERROR_NO_GZIP"
fi

if [ -e "$repo" ]; then
    clean "$repo"
fi
make_directory "$repo"

# curl #
if [ "$curl_installed" ]; then
    curl -L ${URL_PREFIX}${repo}${TAR_FILE_SUFFIX} --output "$output_tmp_filename"
    if [ ! "$?" -eq 0 ]; then
        echo >&2 "$0: Could not download $repo using curl, maybe connection problems?"
        exit "$EXIT_ERROR_CURL"
    fi
    # wget #
elif [ "$wget_installed" ]; then
    wget --no-check-certificate ${URL_PREFIX}${repo}${TAR_FILE_SUFFIX} --output-document "$output_tmp_filename"
    if [ ! "$?" -eq 0 ]; then
        echo >&2 "$0: Could not download $repo using wget, maybe connection problems?"
        exit "$EXIT_ERROR_WGET"
    fi
fi


# tar #
$TAR_COMMAND "$output_tmp_filename" "--directory=$repo"
if [ ! "$?" -eq 0 ]; then
    echo >&2 "$0: Could not untar $repo using tar, no idea why :("
    clean_tmp_file "$output_tmp_filename"
    exit "$EXIT_ERROR_CLEAN_TMP";
fi
clean_tmp_file "$output_tmp_filename"
exit
