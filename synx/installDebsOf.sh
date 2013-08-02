#!/usr/bin/env bash

desiredHost="$1"

list="/home/dominik/scripts/synx/data/${desiredHost}/debs.list"
sudo apt-get update
xargs -a "$list" sudo apt-get install
