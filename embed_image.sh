#!/bin/bash

set -euxo pipefail

image=$1
additional_copy_args="${2:-""} ${3:-""}"

mkdir -p /usr/lib/containers/storage
sha=$(echo "$image" | sha256sum | awk '{ print $1 }')

#  The LVMS image is "special" because it's a multi-arch manifest, so --all tries copy all platforms and fails. Also using target as sha doesn't work. 
if [[ $image == *"lvm"* ]]; then
   aux=$(echo $image|cut -d\@ -f1)
   skopeo copy --all $additional_copy_args docker://$image dir:/usr/lib/containers/storage/$sha
else
   skopeo copy $additional_copy_args docker://$image dir:/usr/lib/containers/storage/$sha
fi

echo "$image,$sha" >> /usr/lib/containers/storage/image-list.txt
