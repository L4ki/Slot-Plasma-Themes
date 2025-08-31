#! /bin/bash
basedir=$1
for x in 32 48
do
    while read -r line; do
        read -r -a file <<< "$line"
        ln -sf ${file[0]} "${basedir}/apps/$x/${file[1]}"
    done <<< `grep -v '^#' ${x}.files`
done
