#!/bin/sh

readonly GET_SCRIPT="$HOME/scripts/get_repo.sh"

$GET_SCRIPT wiki    $HOME --readonly
$GET_SCRIPT config  $HOME --readonly
$GET_SCRIPT scripts $HOME --readonly # <- This *must* be the last one
