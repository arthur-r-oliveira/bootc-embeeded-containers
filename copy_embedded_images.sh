#!/bin/bash
set -eux -o pipefail
while IFS="," read -r img sha ; do
    #  The LVMS image is "special" because it's a multi-arch manifest, so --all tries copy all platforms and fails. Also using target as sha doesn't work. 
    if [[ $img == *"lvm"* ]]; then
       aux=$(echo $img|cut -d\@ -f1)
       skopeo copy --preserve-digests "dir:/usr/lib/containers/storage/${sha}" "containers-storage:${aux}"
    else
       skopeo copy --preserve-digests "dir:/usr/lib/containers/storage/${sha}" "containers-storage:${img}"
    fi
done < "/usr/lib/containers/storage/image-list.txt"
