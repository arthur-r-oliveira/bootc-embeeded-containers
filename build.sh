#!/bin/bash
set -e

REGISTRY_URL=quay.io
TAG=$1

if [ -z "$TAG" ]; then
    echo "Error: a tag must be provided."
    echo "Usage: $0 <tag>"
    exit 1
fi

# Set IMAGE_NAME and BASE_IMAGE_NAME based on TAG (case-insensitive)
TAG_LOWER=$(echo "$TAG" | tr '[:upper:]' '[:lower:]')
case "$TAG_LOWER" in
    4.19)
        IMAGE_NAME=microshift-bootc-embeeded
        BASE_IMAGE_NAME=microshift-bootc:base
        ;;
    4.20)
        IMAGE_NAME=microshift-bootc-embeeded
        BASE_IMAGE_NAME=microshift-bootc:4.19
        ;;
    *)
        echo "Error: TAG must be either 4.19 or 4.20"
        exit 1
        ;;
esac

#REGISTRY_IMG="rhn_support_arolivei/${IMAGE_NAME}"

# For 4.20, configure dnf repositories
if [ "$TAG_LOWER" = "4.20" ]; then
    echo "#### Configuring dnf repositories for 4.20"
    sudo dnf config-manager \
        --set-enabled rhocp-4.20-for-rhel-9-$(uname -m)-rpms \
        --set-enabled fast-datapath-for-rhel-9-$(uname -m)-rpms
    sudo dnf config-manager \
        --set-disabled rhocp-4.18-for-rhel-9-$(uname -m)-rpms \
        --set-disabled rhocp-4.19-for-rhel-9-$(uname -m)-rpms
    cp /etc/yum.repos.d/redhat.repo /home/lab-user/bootc-embeeded-containers
fi

echo "#### Building a new bootc image with MicroShift and application Container images embeeded to it"
sudo podman build -t "${IMAGE_NAME}:${TAG}" \
    --volume /etc/rhsm:/etc/rhsm:ro,z \
    --volume /etc/pki/entitlement:/etc/pki/entitlement:ro,z \
    --volume /etc/containers/registries.d/registry-5000.yaml:/etc/containers/registries.d/registry-5000.yaml:ro,z \
    --volume /etc/yum.repos.d:/etc/yum.repos.d:ro,z \
    --volume /etc/containers/registries.conf.d/99-mirrors.conf:/etc/containers/registries.conf.d/99-mirrors.conf:ro,z \
    --volume /etc/containers/policy.json:/etc/containers/policy.json:ro,z \
    --build-arg USHIFT_BASE_IMAGE_NAME="${BASE_IMAGE_NAME}" \
    --build-arg USHIFT_BASE_IMAGE_TAG=${TAG} \
    -f Containerfile.${TAG}

#echo "#### pushing bootc image to a registry"
#podman push "localhost/${IMAGE_NAME}:${TAG}" "${REGISTRY_URL}/${REGISTRY_IMG}:${TAG}"

# Only create ISO for 4.19
if [ "$TAG_LOWER" = "4.19" ]; then
    sudo mkdir -p /var/tmp/bootc-images
    echo "#### creating ISO from bootc image"
    sudo podman run --rm -it --privileged --security-opt label=type:unconfined_t \
       -v /var/lib/containers/storage:/var/lib/containers/storage \
       -v /var/tmp/bootc-images:/output \
       --volume /etc/rhsm:/etc/rhsm:ro \
       --volume /etc/pki/entitlement:/etc/pki/entitlement:ro \
       --volume /etc/containers/registries.d/registry-5000.yaml:/etc/containers/registries.d/registry-5000.yaml:ro \
        registry.redhat.io/rhel9/bootc-image-builder:latest \
        --progress=verbose --local --type iso localhost/${IMAGE_NAME}:${TAG}

    cp -v /var/tmp/bootc-images/bootiso/install.iso microshift-bootc-embeeded-4.19.iso
fi
