#!/bin/bash
set -eux -o pipefail
while IFS="," read -r img sha ; do

   skopeo copy --preserve-digests "dir:/usr/lib/containers/storage/${sha}" "containers-storage:${img}"

done < "/usr/lib/containers/storage/image-list.txt"
