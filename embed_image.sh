#!/bin/bash

set -euxo pipefail

image=$1
additional_copy_args="${2:-""} ${3:-""}"

mkdir -p /usr/lib/containers/storage
sha=$(echo "$image" | sha256sum | awk '{ print $1 }')
skopeo copy $additional_copy_args --preserve-digests docker://$image dir:/usr/lib/containers/storage/$sha
echo "$image,$sha" >> /usr/lib/containers/storage/image-list.txt
