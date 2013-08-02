#!/usr/bin/env bash
hostname=$(hostname)
globDir="/home/dominik/scripts/synx/data/"
persDir="${globDir}$hostname/"

echo $persDir
echo $globDir
echo $hostname

# packets
sudo dpkg --get-selections | awk '!/deinstall|purge|hold/ {print $1}' > "${persDir}debs.list"


