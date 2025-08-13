PULL_SECRET=.pull-secret.json
USER_PASSWD=redhat02
IMAGE_NAME=microshift-4.19-bootc

podman build --authfile "${PULL_SECRET}" -t "${IMAGE_NAME}" \
    --build-arg USER_PASSWD="${USER_PASSWD}" \
    -f Containerfile.base
