#!/bin/bash

url="http://fileserver/service/rest/beta/search/assets?repository=maven-releases&name=dot-files"

artifact=( $(curl -s -X GET --header 'Accept: application/json' \
    "$url" | grep -Po '"downloadUrl" : ".*?[^\\]*.(zip.sha1|zip)",' | \
    awk -F '"' '{print $4}' | sort -Vr | head -n2) )

((${#artifact[@]})) || echo "ERROR! No artifacts found at provided url!"

for i in "${artifact[@]}"; do
    if [[ $i =~ (sha1) ]]; then
        checksum=$(curl -s "$i" | awk '{print $1}')
    else
        file="$(echo "$i" | awk -F "/" '{print $NF}')"
        curl -sO "$i" || { echo "ERROR: Download failed!"; exit 1; }

        if [ "$(sha1sum "$file" | awk '{print $1}')" != "$checksum" ]; then
            echo "ERROR: Checksum validation on $file failed!"; exit 1;
        else
            printf "Downloaded : %s\nChecksum   : %s\n" "$file" "$checksum"
        fi
    fi
done
#EOF