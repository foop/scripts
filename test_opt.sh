#!/bin/sh

display_usage() {
    echo "usage bla"
}

readonly VERSION=0.01

while : ; do
    case $1 in
        -h | --help | -\?)
            show_usage;
            exit $EXIT_SUCCESS;
            ;;
        -u | --username | --user_name)
            git_username="$2"
            shift 2
            ;;
        -u=* | --username=*)
            git_username="${1#*=}"
            shift
            ;;
        -b | --bitbucket | --bit_bucket)
            bit_bucket="true"
            shift
            ;;

        -g | --github | --git_hub)
            git_hub="true"
            shift
            ;;

        -r | --readonly | --read_only)
            read_only="true"
            shift
            ;;

        -v | --version | --show_version)
            echo "$VERSION"
            exit $EXIT_SUCESS;
            ;;

        -y | --repository )
            if [ ! $repository_name ]; then
                repository_name="$2"
            else echo "I can only process one repository at a time"
                display_usage
                exit $EXIT_ERROR_ARG
            fi
            shift 2
            ;;
        -y=* | --repository=*)
            if [ ! $repository_name ]; then
                repository_name="${1#*=}"
            else echo "I can only process one repository at a time"
                display_usage
                exit $EXIT_ERROR_ARG
            fi
            shift
            ;;

        *)
            if [ $1 ]; then
                if [ ! $repository_name ]; then
                    repository_name="$1"
                elif [ ! $target_dir ]; then
                    target_dir="$1"
                else 
                    display_usage
                    exit $EXIT_ERROR_ARG # <---- SOMETHING IS WRONG
                fi
            else 
                break # <---- GET ON WITH IT
            fi
            shift
            ;;
    esac     
done
    [ $git_username ] && echo "user: $git_username"
    [ $repository_name ] && echo "repo: $repository_name"
    [ $target_dir ] && echo "target $target_dir"
    [ $bit_bucket ] && echo "bit_bucket is set"
    [ $git_hub ] && echo "git_hub is set"
