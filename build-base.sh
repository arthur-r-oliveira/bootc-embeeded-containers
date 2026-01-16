#!/bin/bash
USER_PASSWD=redhat02
IMAGE_NAME=microshift-bootc:base

dnf config-manager \
        --set-enabled rhocp-4.19-for-rhel-9-$(uname -m)-rpms \
        --set-enabled fast-datapath-for-rhel-9-$(uname -m)-rpms
dnf config-manager --set-disabled rhocp-4.18-for-rhel-9-$(uname -m)-rpms --set-disabled rhocp-4.20-for-rhel-9-$(uname -m)-rpms
cp /etc/yum.repos.d/redhat.repo /home/lab-user/bootc-embedded-containers

# Run podman build as root to allow for :z relabeling
#
# Mount the host subscription data
#
# In this lab there is no need for --authfile / pullsecret as we are pulling from a disconnected unsecure registry
sudo podman build -t ${IMAGE_NAME} \
    --build-arg USER_PASSWD=${USER_PASSWD} \
    --volume /etc/rhsm:/etc/rhsm:ro,z \
    --volume /etc/pki/entitlement:/etc/pki/entitlement:ro,z \
    --volume /etc/yum.repos.d:/etc/yum.repos.d:ro,z \
    -f Containerfile.base
