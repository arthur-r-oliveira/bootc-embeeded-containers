
- [Building Appliances for self-contained and disconnected environments with RHEL Image Mode (bootc)](#building-appliances-for-self-contained-and-disconnected-environments-with-rhel-image-mode-bootc)
  - [Embedding Containers \& Physically-bound images: ship it with the bootc image](#embedding-containers--physically-bound-images-ship-it-with-the-bootc-image)
  - [General instructions:](#general-instructions)
    - [Procedures](#procedures)
      - [Download your redhat pull secrets](#download-your-redhat-pull-secrets)
      - [Build the base image](#build-the-base-image)
      - [Build the embedded image](#build-the-embedded-image)
      - [Create a test environment (KVM based, isolated network)](#create-a-test-environment-kvm-based-isolated-network)
      - [Build an updated image](#build-an-updated-image)
      - [Bootc switch \& upgrade](#bootc-switch--upgrade)
      - [Sample](#sample)
      - [Experimental - "Delta Updates" with tar-diff](#experimental---delta-updates-with-tar-diff)
        - [Updating our Bootc image with latest updates.](#updating-our-bootc-image-with-latest-updates)
        - [Export Images to .tar](#export-images-to-tar)
        - [Installing tar-diff and tar-patch from source (to raise a issue to the repo):](#installing-tar-diff-and-tar-patch-from-source-to-raise-a-issue-to-the-repo)
        - [Generate Delta Using Tar-Diff](#generate-delta-using-tar-diff)
        - [Reconstruct v2 from the delta On the Local Registry](#reconstruct-v2-from-the-delta-on-the-local-registry)
        - [Patching Host](#patching-host)


# Building Appliances for self-contained and disconnected environments with RHEL Image Mode (bootc)

[About image mode for Red Hat Enterprise Linux (RHEL)](https://docs.redhat.com/en/documentation/red_hat_build_of_microshift/4.18/html-single/installing_with_rhel_image_mode/index#microshift-bootc-conc_microshift-about-rhel-image-mode): _Image mode for Red Hat Enterprise Linux (RHEL) is a Technology Preview deployment method that uses a container-native approach to build, deploy, and manage the operating system as a bootc image. By using bootc, you can build, deploy, and manage the operating system as if it is any other container._

## Embedding Containers & Physically-bound images: ship it with the bootc image
[Some use cases require the entire boot image to be fully self contained. That means that everything needed to execute the workloads is shipped with the bootc image, including container images of the application containers and Quadlets. Such images are also referred to as “physically-bound images”.](https://docs.fedoraproject.org/en-US/bootc/embedding-containers/#_physically_bound_images_ship_it_with_the_bootc_image)

## General instructions: 

Get started within MicroShift and image-mode (bootc) first https://docs.redhat.com/en/documentation/red_hat_build_of_microshift/4.18/html-single/installing_with_rhel_image_mode/index
- Then, embeed MicroShift and Application Container Images for offline deployments based on this:
  - https://github.com/openshift/microshift/blob/main/docs/contributor/image_mode.md#appendix-b-embedding-container-images-in-bootc-builds
  - https://gitlab.com/fedora/bootc/examples/-/tree/main/physically-bound-images
  - https://developers.redhat.com/articles/2025/05/29/how-embed-containers-image-mode-rhel#embed_quadlets_into_a_bootc_image

### Procedures

#### Download your redhat pull secrets

To get access to Red Hat registries, download your redhat pull secrets from https://console.redhat.com/openshift/downloads#tool-pull-secret and place as local file `.pull-secret.json`.

#### Build the base image

Based on these [procedures](https://github.com/openshift/microshift/blob/main/docs/contributor/image_mode.md#build-microshift-bootc-image), build the base microshift-bootc image: 

`bash -x build-base.sh`

#### Build the embedded image 

Based on these [procedures]https://github.com/openshift/microshift/blob/main/docs/contributor/image_mode.md#appendix-b-embedding-container-images-in-bootc-builds), using microshift-bootc image built in previous step, embeed the Container Images to your new microshift-bootc-embeed image:

  - `bash -x build.sh v1. 

This will include the MicroShift payload + an sample wordpress Container image to the bootc image. It also produces a ISO image, to be used to install RHDE. 

#### Create a test environment (KVM based, isolated network)

- Within your test environment, [create a isolated network](https://github.com/openshift/microshift/blob/main/docs/contributor/image_mode.md#configure-isolated-network).
- Create a test VM with `create-vm.sh`.
- Access VM with user `redhat` and set [kubeconfig access to microshift](https://docs.redhat.com/en/documentation/red_hat_build_of_microshift/4.18/html/configuring/microshift-kubeconfig#accessing-microshift-cluster-locally_microshift-kubeconfig)

#### Build an updated image

Build the second image with `bash -x build.sh v2`.
That will include RHEL updates + a sample mysql Container image to bootc image tagged as V2. It also produces a ISO image.

#### Bootc switch & upgrade

Upgrade live system to v2. 
See for additional context  https://docs.fedoraproject.org/en-US/bootc/disconnected-updates/ 

#### Sample
~~~
[redhat@localhost argocd-example-apps-wordpress-main]$ cd wordpress/
[redhat@localhost wordpress]$ ll
total 24
-rw-r--r--. 1 redhat redhat  315 May  7 14:41 clusterrolebind.yaml
-rw-r--r--. 1 redhat redhat  251 May  7 14:41 kustomization.yaml
-rw-r--r--. 1 redhat redhat 1550 May  7 14:41 mysql-deployment.yaml
-rw-r--r--. 1 redhat redhat  113 May  7 14:41 serviceaccount.yaml
-rw-r--r--. 1 redhat redhat 1790 May  7 14:41 wordpress-deployment.yaml
-rw-r--r--. 1 redhat redhat  115 May  7 14:41 wordpress-namespace.yaml
[redhat@localhost wordpress]$ oc apply -k .
namespace/example-apps-wordpress created
serviceaccount/example-apps-wordpress created
clusterrolebinding.rbac.authorization.k8s.io/system:openshift:scc:anyuid created
secret/mysql-pass-tmbk2k5m9f created
service/wordpress created
service/wordpress-mysql created
persistentvolumeclaim/mysql-pv-claim created
persistentvolumeclaim/wp-pv-claim created
deployment.apps/wordpress created
deployment.apps/wordpress-mysql created
route.route.openshift.io/example-apps-wordpress created
[redhat@localhost wordpress]$ oc get pods -A
NAMESPACE                  NAME                                      READY   STATUS             RESTARTS      AGE
example-apps-wordpress     wordpress-ff94c8dcf-5cfzx                 1/1     Running            0             6s
example-apps-wordpress     wordpress-mysql-84dd895d65-9rf27          0/1     ImagePullBackOff   0             6s
kube-system                csi-snapshot-controller-85ccb45d4-flzh8   1/1     Running            0             75m
openshift-dns              dns-default-pgh8w                         2/2     Running            0             75m
openshift-dns              node-resolver-r9822                       1/1     Running            0             75m
openshift-ingress          router-default-6ddbc959b9-vv6wr           1/1     Running            0             75m
openshift-ovn-kubernetes   ovnkube-master-qgchl                      4/4     Running            1 (75m ago)   75m
openshift-ovn-kubernetes   ovnkube-node-d72c8                        1/1     Running            1 (75m ago)   75m
openshift-service-ca       service-ca-7b964bd597-g2cvc               1/1     Running            0             75m
openshift-storage          lvms-operator-d6f9c9d4-m7cfr              1/1     Running            0             75m
openshift-storage          vg-manager-wx2bg                          1/1     Running            0             75m
[redhat@localhost wordpress]$ sudo podman images
REPOSITORY                                      TAG           IMAGE ID      CREATED        SIZE
quay.io/openshift-release-dev/ocp-v4.0-art-dev  <none>        78dffc9b208a  2 weeks ago    397 MB
quay.io/openshift-release-dev/ocp-v4.0-art-dev  <none>        cb6da2bc6850  3 weeks ago    496 MB
quay.io/openshift-release-dev/ocp-v4.0-art-dev  <none>        83647e00f538  3 weeks ago    464 MB
quay.io/openshift-release-dev/ocp-v4.0-art-dev  <none>        00c557191496  3 weeks ago    485 MB
quay.io/openshift-release-dev/ocp-v4.0-art-dev  <none>        43c9b1e23839  3 weeks ago    509 MB
quay.io/openshift-release-dev/ocp-v4.0-art-dev  <none>        b1bb5b8dc4f2  3 weeks ago    661 MB
quay.io/openshift-release-dev/ocp-v4.0-art-dev  <none>        aeeb36a3bc17  3 weeks ago    583 MB
quay.io/openshift-release-dev/ocp-v4.0-art-dev  <none>        73d85875785b  3 weeks ago    466 MB
registry.redhat.io/lvms4/lvms-rhel9-operator    <none>        2b9159626250  7 months ago   218 MB
docker.io/library/wordpress                     6.2.1-apache  b8ee07adfa91  24 months ago  629 MB
[redhat@localhost wordpress]$ 

[redhat@localhost wordpress]$ ping 8.8.8.8
ping: connect: Network is unreachable
[redhat@localhost wordpress]$ ping redhat.com
ping: redhat.com: Name or service not known
[redhat@localhost wordpress]$ 



[redhat@localhost wordpress]$ sudo bootc status
apiVersion: org.containers.bootc/v1alpha1
kind: BootcHost
metadata:
  name: host
spec:
  image:
    image: localhost/microshift-4.18-bootc-embedded
    transport: registry
  bootOrder: default
status:
  staged: null
  booted:
    image:
      image:
        image: localhost/microshift-4.18-bootc-embedded
        transport: registry
      version: 9.20250327.0
      timestamp: null
      imageDigest: sha256:a72864b9478f9d12bc7d5ddb7058d321eb508a340546908360b371e0c6379606
    cachedUpdate: null
    incompatible: false
    pinned: false
    store: ostreeContainer
    ostree:
      checksum: a8853cb9823a3d2c12bf5ed96415e9a76f79d0e865c1a5b44235ef1c0b1572f8
      deploySerial: 0
  rollback: null
  rollbackQueued: false
  type: bootcHost
[redhat@localhost wordpress]$ 


[redhat@localhost wordpress]$ sudo rpm-ostree status
State: idle
Deployments:
● ostree-unverified-registry:localhost/microshift-4.18-bootc-embedded
                   Digest: sha256:a72864b9478f9d12bc7d5ddb7058d321eb508a340546908360b371e0c6379606
                  Version: 9.20250327.0 (2025-05-07T11:54:42Z)
[redhat@localhost wordpress]$ 

[redhat@localhost wordpress]$  cat /etc/redhat-release 
Red Hat Enterprise Linux release 9.4 (Plow)
[redhat@localhost wordpress]$ uname -a
Linux localhost.localdomain 5.14.0-427.61.1.el9_4.x86_64 #1 SMP PREEMPT_DYNAMIC Fri Mar 14 15:21:35 EDT 2025 x86_64 x86_64 x86_64 GNU/Linux
[redhat@localhost wordpress]$ 
[redhat@localhost ~]$ sudo mkdir -p /var/bootc/updates/
[redhat@localhost ~]$ sudo chown -R redhat: /var/bootc/updates/
~~~

Offload the updated container image to the edge system: 
~~~
[root@rhel94-local microshift-4.18-bootc-embeeded-v2]# pwd
/root/output/microshift-4.18-bootc-embeeded-v2
[root@rhel94-local microshift-4.18-bootc-embeeded-v2]# podman images
REPOSITORY                                    TAG         IMAGE ID      CREATED         SIZE
localhost/microshift-4.18-bootc-embeeded      v2          6c4603c9450c  56 minutes ago  9.97 GB
localhost/microshift-4.18-bootc-embeeded      v1          d7873e43ed57  3 hours ago     5.69 GB
localhost/microshift-4.18-bootc               latest      e2a0d99624d8  3 hours ago     2.3 GB
registry.redhat.io/rhel9-eus/rhel-9.4-bootc   9.4         25bd5203da82  5 weeks ago     1.54 GB
registry.redhat.io/rhel9/bootc-image-builder  latest      bff4a9494770  4 months ago    541 MB
registry.redhat.io/rhel9/rhel-bootc           9.4         6b73e1d4ff64  6 months ago    1.48 GB
[root@rhel94-local microshift-4.18-bootc-embeeded-v2]# skopeo copy containers-storage:localhost/microshift-4.18-bootc-embeeded:v2 dir://root/output/microshift-4.18-bootc-embeeded-v2
INFO[0000] Not using native diff for overlay, this may cause degraded performance for building images: kernel has CONFIG_OVERLAY_FS_REDIRECT_DIR enabled 
Getting image source signatures
Copying blob a4dda694ae04 done   | 
Copying blob 7e2558927ccf done   | 
Copying blob 7e2558927ccf done   | 
Copying blob 7e2558927ccf done   | 
(...)
Copying blob 5f70bf18a086 skipped: already exists  
Copying blob b73069f4adb5 done   | 
Copying config 6c4603c945 done   | 
Writing manifest to image destination
[root@rhel94-local microshift-4.18-bootc-embeeded-v2]# 
[root@rhel94-local microshift-4.18-bootc-embeeded-v2]# ll
total 9735468
-rw-r--r--. 1 root root    4628992 May  7 15:29 00f2ea7601ccaf225d56861ba00d71c914b3dc6c347c70743c46f5b3f403a82f
-rw-r--r--. 1 root root    5727744 May  7 15:29 03a653bb5db34497d7543df3976080e68dd51db57ce294286ac0cd52ff1106b8
(...)
-rw-r--r--. 1 root root   21358592 May  7 15:29 fea802cbc345c65efd1bc1c56a3d06603f3310326c9e0741b94ea197dbca0ada
-rw-r--r--. 1 root root      14232 May  7 15:30 manifest.json
-rw-r--r--. 1 root root         33 May  7 15:29 version
[root@rhel94-local microshift-4.18-bootc-embeeded-v2]# 
[root@rhel94-local microshift-4.18-bootc-embeeded-v2]# du -sm .
9508	.
[root@rhel94-local microshift-4.18-bootc-embeeded-v2]# 
~~~

Then, get it updated!
~~~
[redhat@localhost wordpress]$ sudo bootc switch --transport dir /var/bootc/updates/microshift-4.18-bootc-embeeded-v2/
layers already present: 0; layers needed: 90 (10.0 GB)
Fetched layers: 9.28 GiB in 52 seconds (183.99 MiB/s)
Pruned images: 1 (layers: 0, objsize: 268 bytes)
Queued for next boot: ostree-unverified-image:dir:/var/bootc/updates/microshift-4.18-bootc-embeeded-v2/
  Version: 9.20250327.0
  Digest: sha256:aa8bf7098b61eae9a9a5bd59ea93bc83b538a281019f742a88bd24e24f6dd16e
[redhat@localhost wordpress]$ 

[redhat@localhost wordpress]$ sudo rpm-ostree status
State: idle
Deployments:
  ostree-unverified-image:dir:/var/bootc/updates/microshift-4.18-bootc-embeeded-v2/
                   Digest: sha256:aa8bf7098b61eae9a9a5bd59ea93bc83b538a281019f742a88bd24e24f6dd16e
                  Version: 9.20250327.0 (2025-05-07T13:33:04Z)
                     Diff: 20 upgraded, 4 added

● ostree-unverified-registry:localhost/microshift-4.18-bootc-embedded
                   Digest: sha256:a72864b9478f9d12bc7d5ddb7058d321eb508a340546908360b371e0c6379606
                  Version: 9.20250327.0 (2025-05-07T11:54:42Z)
[redhat@localhost wordpress]$ 
[redhat@localhost wordpress]$ sudo bootc status
apiVersion: org.containers.bootc/v1alpha1
kind: BootcHost
metadata:
  name: host
spec:
  image:
    image: /var/bootc/updates/microshift-4.18-bootc-embeeded-v2/
    transport: dir
  bootOrder: default
status:
  staged:
    image:
      image:
        image: /var/bootc/updates/microshift-4.18-bootc-embeeded-v2/
        transport: dir
      version: 9.20250327.0
      timestamp: null
      imageDigest: sha256:aa8bf7098b61eae9a9a5bd59ea93bc83b538a281019f742a88bd24e24f6dd16e
    cachedUpdate: null
    incompatible: false
    pinned: false
    store: ostreeContainer
    ostree:
      checksum: 3462eb777a42c9dd1fba65fe36b7f7d9d970f5178ecd0d09740941e41c0c92ce
      deploySerial: 0
  booted:
    image:
      image:
        image: localhost/microshift-4.18-bootc-embedded
        transport: registry
      version: 9.20250327.0
      timestamp: null
      imageDigest: sha256:a72864b9478f9d12bc7d5ddb7058d321eb508a340546908360b371e0c6379606
    cachedUpdate: null
    incompatible: false
    pinned: false
    store: ostreeContainer
    ostree:
      checksum: a8853cb9823a3d2c12bf5ed96415e9a76f79d0e865c1a5b44235ef1c0b1572f8
      deploySerial: 0
  rollback: null
  rollbackQueued: false
  type: bootcHost
[redhat@localhost wordpress]$ sudo bootc upgrade --apply
No changes in ostree-unverified-image:dir:/var/bootc/updates/microshift-4.18-bootc-embeeded-v2/ => sha256:aa8bf7098b61eae9a9a5bd59ea93bc83b538a281019f742a88bd24e24f6dd16e
Staged update present, not changed.
Rebooting system
Connection to 192.168.111.200 closed by remote host.
Connection to 192.168.111.200 closed.
arolivei@arolivei-thinkpadp16vgen1:~/VirtualMachines$ ssh redhat@192.168.111.200
redhat@192.168.111.200's password: 
Last login: Wed May  7 14:50:59 2025 from 192.168.111.1
[redhat@localhost ~]$ podman images
REPOSITORY  TAG         IMAGE ID    CREATED     SIZE
[redhat@localhost ~]$ sudo podman images
[sudo] password for redhat: 
REPOSITORY                                      TAG           IMAGE ID      CREATED        SIZE
quay.io/openshift-release-dev/ocp-v4.0-art-dev  <none>        78dffc9b208a  2 weeks ago    397 MB
quay.io/openshift-release-dev/ocp-v4.0-art-dev  <none>        cb6da2bc6850  3 weeks ago    496 MB
quay.io/openshift-release-dev/ocp-v4.0-art-dev  <none>        83647e00f538  3 weeks ago    464 MB
quay.io/openshift-release-dev/ocp-v4.0-art-dev  <none>        00c557191496  3 weeks ago    485 MB
quay.io/openshift-release-dev/ocp-v4.0-art-dev  <none>        43c9b1e23839  3 weeks ago    509 MB
quay.io/openshift-release-dev/ocp-v4.0-art-dev  <none>        b1bb5b8dc4f2  3 weeks ago    661 MB
quay.io/openshift-release-dev/ocp-v4.0-art-dev  <none>        aeeb36a3bc17  3 weeks ago    583 MB
quay.io/openshift-release-dev/ocp-v4.0-art-dev  <none>        73d85875785b  3 weeks ago    466 MB
docker.io/library/mysql                         8.0           00a697b8380c  3 weeks ago    789 MB
registry.redhat.io/lvms4/lvms-rhel9-operator    <none>        2b9159626250  7 months ago   218 MB
docker.io/library/wordpress                     6.2.1-apache  b8ee07adfa91  24 months ago  629 MB
[redhat@localhost ~]$ sudo crictl images
IMAGE                                            TAG                 IMAGE ID            SIZE
docker.io/library/mysql                          8.0                 00a697b8380c1       789MB
docker.io/library/wordpress                      6.2.1-apache        b8ee07adfa917       629MB
quay.io/openshift-release-dev/ocp-v4.0-art-dev   <none>              73d85875785b1       466MB
quay.io/openshift-release-dev/ocp-v4.0-art-dev   <none>              00c5571914963       485MB
quay.io/openshift-release-dev/ocp-v4.0-art-dev   <none>              b1bb5b8dc4f24       661MB
quay.io/openshift-release-dev/ocp-v4.0-art-dev   <none>              78dffc9b208a6       397MB
quay.io/openshift-release-dev/ocp-v4.0-art-dev   <none>              43c9b1e23839d       509MB
quay.io/openshift-release-dev/ocp-v4.0-art-dev   <none>              cb6da2bc6850a       496MB
quay.io/openshift-release-dev/ocp-v4.0-art-dev   <none>              83647e00f538a       464MB
quay.io/openshift-release-dev/ocp-v4.0-art-dev   <none>              aeeb36a3bc178       583MB
registry.redhat.io/lvms4/lvms-rhel9-operator     <none>              2b91596262502       218MB
[redhat@localhost ~]$ oc get pods -A
NAMESPACE                  NAME                                      READY   STATUS    RESTARTS   AGE
example-apps-wordpress     wordpress-ff94c8dcf-5cfzx                 1/1     Running   1          10m
example-apps-wordpress     wordpress-mysql-84dd895d65-9rf27          1/1     Running   0          10m
kube-system                csi-snapshot-controller-85ccb45d4-flzh8   1/1     Running   1          85m
openshift-dns              dns-default-pgh8w                         2/2     Running   3          85m
openshift-dns              node-resolver-r9822                       1/1     Running   1          85m
openshift-ingress          router-default-6ddbc959b9-vv6wr           1/1     Running   2          85m
openshift-ovn-kubernetes   ovnkube-master-qgchl                      4/4     Running   5          85m
openshift-ovn-kubernetes   ovnkube-node-d72c8                        1/1     Running   2          85m
openshift-service-ca       service-ca-7b964bd597-g2cvc               1/1     Running   1          85m
openshift-storage          lvms-operator-d6f9c9d4-m7cfr              0/1     Running   1          86m
openshift-storage          vg-manager-wx2bg                          0/1     Running   1          85m
[redhat@localhost ~]$ 

[redhat@localhost ~]$ cat /etc/redhat-release 
Red Hat Enterprise Linux release 9.4 (Plow)
[redhat@localhost ~]$ uname -a
Linux localhost.localdomain 5.14.0-427.61.1.el9_4.x86_64 #1 SMP PREEMPT_DYNAMIC Fri Mar 14 15:21:35 EDT 2025 x86_64 x86_64 x86_64 GNU/Linux
[redhat@localhost ~]$ sudo rpm-ostree status
State: idle
Deployments:
● ostree-unverified-image:dir:/var/bootc/updates/microshift-4.18-bootc-embeeded-v2/
                   Digest: sha256:aa8bf7098b61eae9a9a5bd59ea93bc83b538a281019f742a88bd24e24f6dd16e
                  Version: 9.20250327.0 (2025-05-07T13:33:04Z)

  ostree-unverified-registry:localhost/microshift-4.18-bootc-embedded
                   Digest: sha256:a72864b9478f9d12bc7d5ddb7058d321eb508a340546908360b371e0c6379606
                  Version: 9.20250327.0 (2025-05-07T11:54:42Z)
[redhat@localhost ~]$ 
~~~

#### Experimental - "Delta Updates" with tar-diff 

__Note: Kudos to Hrushabh Sirsulwar <hsirsulw@redhat.com> who suggested this approach.__ 

Traditional container image updates are too large for bandwidth-constrained far-edge devices. To address this, we would like to use delta updates, which only download the changes between layers. This significantly reduces data transfer while ensuring the updated image is identical to the full version.

Although bootc systems are based on OStree, which does support deltas, going through this path is very probamatic from management perspective as you lose all the benefits of bootc going through OCI standards. 

while reseraching for solutions, we've find out [`containers/tar-diff`](https://github.com/containers/tar-diff), which is a command-line utility designed to efficiently create and apply binary differences between two tar archives.

Its main purpose is to reduce the size of updates for container images by generating a small "delta" file that represents only the changes between an old image layer and a new one. This delta can then be used with the original layer to reconstruct the new version.

While containers/tar-diff is a functional tool, its application for producing and distributing delta updates for container images is not a universally supported feature across all container registries and engines. This capability exists within a specific ecosystem of tools that have implemented experimental support for OCI image delta updates.

DISCLAIMER: **THIS IS NOT A SUPPORTED UPGRADE PATH FOR BOOTC SYSTEMS. Beying tested and documented with the intension of exploration only.**

**Requirements on Build System**
- `base-image.tar` or an equivalent OCI-formatted image
This is the original, older version of the image. The build system needs access to this file to use it as the "before" state for comparison.

- `updated-image.tar` or an equivalent OCI-formatted image
This is the complete, new version of the image that the build system must first produce from the latest source code. It serves as the "after" state for the comparison.

- `tar-diff` binary (from the tar-diff toolset)
This is the essential utility used by the build system to compare the base-image.tar with the updated-image.tar. The tool's output is the delta_base_target.tar file.

**Requirements on Target System**

- Access to a OCI Registry within the same Isolated LAN, although could also be embeeded to the running edge system. 

- `base-image.tar` or an equivalent OCI-formatted image
 The base image must be available on-site, but it does not need to reside directly on the edge system. It can be stored on an on-site bastion host, local repository, or any system within the same network. This image will serve as the foundation for applying the delta.


- `delta_base_target.tar' (the delta update)
 This delta file contains only the differences between the base and updated images. It is significantly smaller than the full image and can be transferred to the site over the internet or any suitable medium.

- `tar-patch` binary (from the tar-diff toolset)
 This utility is essential for reconstructing the updated image on the target system. It combines the base image with the delta to produce the final image tarba

##### Updating our Bootc image with latest updates. 

Containerfile for updated OCI:
~~~
#FROM registry.redhat.io/rhel9/rhel-bootc:9.4 ## V1 is RHEL 9.4, EUS based. But with the release of RHEL 9.6 EUS, this UBI is not being updated anymore. 
FROM localhost/microshift-4.18-bootc-embeeded:v1 ## our base image does already have the everything included (baseOS, configs, app images)
ENV USHIFT_VER=4.18

# we are just updating the baseOS and eventually MicroShift with latest updates. 
RUN dnf config-manager \
        --set-enabled rhocp-${USHIFT_VER}-for-rhel-9-$(uname -m)-rpms \
        --set-enabled fast-datapath-for-rhel-9-$(uname -m)-rpms 
RUN dnf update --enablerepo=rhel-9-for-$(uname -m)-baseos-eus-rpms --enablerepo=rhel-9-for-x86_64-appstream-eus-rpms -y --releasever=9.4 && \
    dnf clean all

~~~

Build: 
~~~
+ PULL_SECRET=.pull-secret.json
+ IMAGE_NAME=microshift-4.18-bootc-embeeded
+ REGISTRY_URL=quay.io
+ TAG=v2
+ REGISTRY_IMG=rhn_support_arolivei/microshift-4.18-bootc-embeeded:v2
+ BASE_IMAGE_NAME=microshift-4.18-bootc:latest
+ echo '#### Building a new bootc image with MicroShift and application Container images embeeded to it'
#### Building a new bootc image with MicroShift and application Container images embeeded to it
+ podman build --authfile .pull-secret.json -t microshift-4.18-bootc-embeeded:v2 --secret id=pullsecret,src=.pull-secret.json --build-arg USHIFT_BASE_IMAGE_NAME=microshift-4.18-bootc:latest --build-arg USHIFT_BASE_IMAGE_TAG=v2 -f Containerfile.v2
STEP 1/4: FROM localhost/microshift-4.18-bootc-embeeded:v1
STEP 2/4: ENV USHIFT_VER=4.18
--> Using cache d8f2c743febedf60d4ffe9aca6b6c548c11654882091726eada189a230632869
--> d8f2c743febe
STEP 3/4: RUN dnf config-manager         --set-enabled rhocp-${USHIFT_VER}-for-rhel-9-$(uname -m)-rpms         --set-enabled fast-datapath-for-rhel-9-$(uname -m)-rpms 
Updating Subscription Management repositories.
Unable to read consumer identity
subscription-manager is operating in container mode.

This system is not registered with an entitlement server. You can use subscription-manager to register.

--> 00aee13b6f11
STEP 4/4: RUN dnf update --enablerepo=rhel-9-for-$(uname -m)-baseos-eus-rpms --enablerepo=rhel-9-for-x86_64-appstream-eus-rpms -y --releasever=9.4 &&     dnf clean all
Updating Subscription Management repositories.
Unable to read consumer identity
subscription-manager is operating in container mode.

This system is not registered with an entitlement server. You can use subscription-manager to register.

Red Hat Enterprise Linux 9 for x86_64 - AppStre  21 MB/s |  43 MB     00:02    
Red Hat Enterprise Linux 9 for x86_64 - BaseOS   18 MB/s |  35 MB     00:01    
Fast Datapath for RHEL 9 x86_64 (RPMs)          880 kB/s | 533 kB     00:00    
Red Hat Enterprise Linux 9 for x86_64 - AppStre  31 MB/s |  52 MB     00:01    
Red Hat OpenShift Container Platform 4.18 for R  36 MB/s |  27 MB     00:00    
Red Hat Enterprise Linux 9 for x86_64 - BaseOS   52 MB/s |  55 MB     00:01    
Dependencies resolved.
=====================================================================================================
 Package                   Arch    Version                   Repository                          Size
=====================================================================================================
Installing:
 kernel                    x86_64  5.14.0-427.72.1.el9_4     rhocp-4.18-for-rhel-9-x86_64-rpms  2.4 M
 kernel-core               x86_64  5.14.0-427.72.1.el9_4     rhocp-4.18-for-rhel-9-x86_64-rpms   17 M
 kernel-modules            x86_64  5.14.0-427.72.1.el9_4     rhocp-4.18-for-rhel-9-x86_64-rpms   36 M
 kernel-modules-core       x86_64  5.14.0-427.72.1.el9_4     rhocp-4.18-for-rhel-9-x86_64-rpms   30 M
Upgrading:
 conmon                    x86_64  3:2.1.12-7.rhaos4.18.el9  rhocp-4.18-for-rhel-9-x86_64-rpms   54 k
 container-selinux         noarch  4:2.235.0-2.rhaos4.18.el9 rhocp-4.18-for-rhel-9-x86_64-rpms   57 k
 containers-common         x86_64  3:1-86.rhaos4.18.el9      rhocp-4.18-for-rhel-9-x86_64-rpms   96 k
 crun                      x86_64  1.21-1.rhaos4.18.el9      rhocp-4.18-for-rhel-9-x86_64-rpms  235 k
 dracut                    x86_64  057-54.git20250423.el9_4  rhel-9-for-x86_64-baseos-eus-rpms  462 k
 dracut-network            x86_64  057-54.git20250423.el9_4  rhel-9-for-x86_64-baseos-eus-rpms   85 k
 dracut-squash             x86_64  057-54.git20250423.el9_4  rhel-9-for-x86_64-baseos-eus-rpms   12 k
 gnutls                    x86_64  3.8.3-4.el9_4.2           rhel-9-for-x86_64-baseos-eus-rpms  1.1 M
 libsmbclient              x86_64  4.19.4-105.el9_4.2        rhel-9-for-x86_64-baseos-eus-rpms   72 k
 libtasn1                  x86_64  4.16.0-8.el9_4.1          rhel-9-for-x86_64-baseos-eus-rpms   74 k
 libwbclient               x86_64  4.19.4-105.el9_4.2        rhel-9-for-x86_64-baseos-eus-rpms   41 k
 podman                    x86_64  5:5.2.2-8.rhaos4.18.el9   rhocp-4.18-for-rhel-9-x86_64-rpms   16 M
 samba-client-libs         x86_64  4.19.4-105.el9_4.2        rhel-9-for-x86_64-baseos-eus-rpms  5.1 M
 samba-common              noarch  4.19.4-105.el9_4.2        rhel-9-for-x86_64-baseos-eus-rpms  146 k
 samba-common-libs         x86_64  4.19.4-105.el9_4.2        rhel-9-for-x86_64-baseos-eus-rpms   98 k
 selinux-policy            noarch  38.1.35-2.el9_4.4         rhel-9-for-x86_64-baseos-eus-rpms   35 k
 selinux-policy-targeted   noarch  38.1.35-2.el9_4.4         rhel-9-for-x86_64-baseos-eus-rpms  6.9 M
 skopeo                    x86_64  2:1.16.1-1.rhaos4.18.el9  rhocp-4.18-for-rhel-9-x86_64-rpms  8.8 M
 toolbox                   noarch  0.1.2-1.rhaos4.18.el9     rhocp-4.18-for-rhel-9-x86_64-rpms   17 k

Transaction Summary
=====================================================================================================
Install   4 Packages
Upgrade  19 Packages

Total download size: 126 M
Downloading Packages:
(1/23): kernel-core-5.14.0-427.72.1.el9_4.x86_6  35 MB/s |  17 MB     00:00    
(2/23): kernel-modules-5.14.0-427.72.1.el9_4.x8  29 MB/s |  36 MB     00:01    
(3/23): kernel-5.14.0-427.72.1.el9_4.x86_64.rpm 2.0 MB/s | 2.4 MB     00:01    
(4/23): kernel-modules-core-5.14.0-427.72.1.el9  39 MB/s |  30 MB     00:00    
(5/23): containers-common-1-86.rhaos4.18.el9.x8 717 kB/s |  96 kB     00:00    
(6/23): conmon-2.1.12-7.rhaos4.18.el9.x86_64.rp 379 kB/s |  54 kB     00:00    
(7/23): toolbox-0.1.2-1.rhaos4.18.el9.noarch.rp 137 kB/s |  17 kB     00:00    
(8/23): container-selinux-2.235.0-2.rhaos4.18.e 476 kB/s |  57 kB     00:00    
(9/23): crun-1.21-1.rhaos4.18.el9.x86_64.rpm    957 kB/s | 235 kB     00:00    
(10/23): selinux-policy-38.1.35-2.el9_4.4.noarc 202 kB/s |  35 kB     00:00    
(11/23): podman-5.2.2-8.rhaos4.18.el9.x86_64.rp  30 MB/s |  16 MB     00:00    
(12/23): skopeo-1.16.1-1.rhaos4.18.el9.x86_64.r  15 MB/s | 8.8 MB     00:00    
(13/23): gnutls-3.8.3-4.el9_4.2.x86_64.rpm      8.4 MB/s | 1.1 MB     00:00    
(14/23): dracut-057-54.git20250423.el9_4.x86_64 3.4 MB/s | 462 kB     00:00    
(15/23): selinux-policy-targeted-38.1.35-2.el9_  31 MB/s | 6.9 MB     00:00    
(16/23): dracut-network-057-54.git20250423.el9_ 710 kB/s |  85 kB     00:00    
(17/23): dracut-squash-057-54.git20250423.el9_4  63 kB/s |  12 kB     00:00    
(18/23): libsmbclient-4.19.4-105.el9_4.2.x86_64 454 kB/s |  72 kB     00:00    
(19/23): libtasn1-4.16.0-8.el9_4.1.x86_64.rpm   616 kB/s |  74 kB     00:00    
(20/23): libwbclient-4.19.4-105.el9_4.2.x86_64. 326 kB/s |  41 kB     00:00    
(21/23): samba-common-4.19.4-105.el9_4.2.noarch 1.2 MB/s | 146 kB     00:00    
(22/23): samba-common-libs-4.19.4-105.el9_4.2.x 786 kB/s |  98 kB     00:00    
(23/23): samba-client-libs-4.19.4-105.el9_4.2.x  16 MB/s | 5.1 MB     00:00    
--------------------------------------------------------------------------------
Total                                            48 MB/s | 126 MB     00:02     
Running transaction check
Transaction check succeeded.
Running transaction test
Transaction test succeeded.
Running transaction
  Running scriptlet: selinux-policy-targeted-38.1.35-2.el9_4.4.noarch       1/1 
  Preparing        :                                                        1/1 
  Running scriptlet: samba-common-4.19.4-105.el9_4.2.noarch                1/42 
  Upgrading        : samba-common-4.19.4-105.el9_4.2.noarch                1/42 
  Running scriptlet: samba-common-4.19.4-105.el9_4.2.noarch                1/42 
  Upgrading        : dracut-057-54.git20250423.el9_4.x86_64                2/42 
  Installing       : kernel-modules-core-5.14.0-427.72.1.el9_4.x86_64      3/42 
  Installing       : kernel-core-5.14.0-427.72.1.el9_4.x86_64              4/42 
  Running scriptlet: kernel-core-5.14.0-427.72.1.el9_4.x86_64              4/42 
  Upgrading        : selinux-policy-38.1.35-2.el9_4.4.noarch               5/42 
  Running scriptlet: selinux-policy-38.1.35-2.el9_4.4.noarch               5/42 
  Running scriptlet: selinux-policy-targeted-38.1.35-2.el9_4.4.noarch      6/42 
  Upgrading        : selinux-policy-targeted-38.1.35-2.el9_4.4.noarch      6/42 
  Running scriptlet: selinux-policy-targeted-38.1.35-2.el9_4.4.noarch      6/42 
  Running scriptlet: container-selinux-4:2.235.0-2.rhaos4.18.el9.noarch    7/42 
  Upgrading        : container-selinux-4:2.235.0-2.rhaos4.18.el9.noarch    7/42 
  Running scriptlet: container-selinux-4:2.235.0-2.rhaos4.18.el9.noarch    7/42 
  Upgrading        : libtasn1-4.16.0-8.el9_4.1.x86_64                      8/42 
  Upgrading        : crun-1.21-1.rhaos4.18.el9.x86_64                      9/42 
  Upgrading        : containers-common-3:1-86.rhaos4.18.el9.x86_64        10/42 
  Upgrading        : gnutls-3.8.3-4.el9_4.2.x86_64                        11/42 
  Running scriptlet: libwbclient-4.19.4-105.el9_4.2.x86_64                12/42 
  Upgrading        : libwbclient-4.19.4-105.el9_4.2.x86_64                12/42 
  Upgrading        : samba-common-libs-4.19.4-105.el9_4.2.x86_64          13/42 
  Upgrading        : samba-client-libs-4.19.4-105.el9_4.2.x86_64          14/42 
  Installing       : kernel-modules-5.14.0-427.72.1.el9_4.x86_64          15/42 
  Running scriptlet: kernel-modules-5.14.0-427.72.1.el9_4.x86_64          15/42 
  Upgrading        : conmon-3:2.1.12-7.rhaos4.18.el9.x86_64               16/42 
  Upgrading        : podman-5:5.2.2-8.rhaos4.18.el9.x86_64                17/42 
  Upgrading        : toolbox-0.1.2-1.rhaos4.18.el9.noarch                 18/42 
  Installing       : kernel-5.14.0-427.72.1.el9_4.x86_64                  19/42 
  Upgrading        : libsmbclient-4.19.4-105.el9_4.2.x86_64               20/42 
  Upgrading        : skopeo-2:1.16.1-1.rhaos4.18.el9.x86_64               21/42 
  Upgrading        : dracut-network-057-54.git20250423.el9_4.x86_64       22/42 
  Upgrading        : dracut-squash-057-54.git20250423.el9_4.x86_64        23/42 
  Cleanup          : libsmbclient-4.19.4-105.el9_4.1.x86_64               24/42 
  Cleanup          : samba-client-libs-4.19.4-105.el9_4.1.x86_64          25/42 
  Cleanup          : samba-common-libs-4.19.4-105.el9_4.1.x86_64          26/42 
  Cleanup          : libwbclient-4.19.4-105.el9_4.1.x86_64                27/42 
  Cleanup          : gnutls-3.8.3-4.el9_4.x86_64                          28/42 
  Cleanup          : toolbox-0.0.99.5-2.el9.x86_64                        29/42 
  Cleanup          : dracut-squash-057-53.git20240104.el9.x86_64          30/42 
  Cleanup          : dracut-network-057-53.git20240104.el9.x86_64         31/42 
  Cleanup          : samba-common-4.19.4-105.el9_4.1.noarch               32/42 
  Running scriptlet: podman-4:4.9.4-18.el9_4.x86_64                       33/42 
  Cleanup          : podman-4:4.9.4-18.el9_4.x86_64                       33/42 
  Cleanup          : skopeo-2:1.14.5-2.el9_4.x86_64                       34/42 
  Cleanup          : containers-common-2:1-91.el9_4.x86_64                35/42 
  Cleanup          : container-selinux-3:2.229.0-1.el9_3.noarch           36/42 
  Running scriptlet: container-selinux-3:2.229.0-1.el9_3.noarch           36/42 
  Running scriptlet: selinux-policy-38.1.35-2.el9_4.3.noarch              37/42 
  Cleanup          : selinux-policy-38.1.35-2.el9_4.3.noarch              37/42 
  Running scriptlet: selinux-policy-38.1.35-2.el9_4.3.noarch              37/42 
  Cleanup          : selinux-policy-targeted-38.1.35-2.el9_4.3.noarch     38/42 
  Running scriptlet: selinux-policy-targeted-38.1.35-2.el9_4.3.noarch     38/42 
  Cleanup          : crun-1.14.3-3.el9_4.x86_64                           39/42 
  Cleanup          : conmon-2:2.1.10-1.el9.x86_64                         40/42 
  Cleanup          : dracut-057-53.git20240104.el9.x86_64                 41/42 
  Cleanup          : libtasn1-4.16.0-8.el9_1.x86_64                       42/42 
  Running scriptlet: kernel-modules-core-5.14.0-427.72.1.el9_4.x86_64     42/42 
  Running scriptlet: kernel-core-5.14.0-427.72.1.el9_4.x86_64             42/42 
grub2-probe: error: failed to get canonical path of `overlay'.
No path or device is specified.
Usage: grub2-probe [OPTION...] [OPTION]... [PATH|DEVICE]
Try 'grub2-probe --help' or 'grub2-probe --usage' for more information.
dracut-install: ERROR: installing '/root'
dracut: FAILED: /usr/lib/dracut/dracut-install -D /var/tmp/dracut.dek4G9/initramfs /root

  Running scriptlet: selinux-policy-targeted-38.1.35-2.el9_4.4.noarch     42/42 
  Running scriptlet: container-selinux-4:2.235.0-2.rhaos4.18.el9.noarch   42/42 
  Running scriptlet: kernel-modules-5.14.0-427.72.1.el9_4.x86_64          42/42 
  Running scriptlet: libtasn1-4.16.0-8.el9_1.x86_64                       42/42 
  Verifying        : kernel-5.14.0-427.72.1.el9_4.x86_64                   1/42 
  Verifying        : kernel-core-5.14.0-427.72.1.el9_4.x86_64              2/42 
  Verifying        : kernel-modules-5.14.0-427.72.1.el9_4.x86_64           3/42 
  Verifying        : kernel-modules-core-5.14.0-427.72.1.el9_4.x86_64      4/42 
  Verifying        : conmon-3:2.1.12-7.rhaos4.18.el9.x86_64                5/42 
  Verifying        : conmon-2:2.1.10-1.el9.x86_64                          6/42 
  Verifying        : containers-common-3:1-86.rhaos4.18.el9.x86_64         7/42 
  Verifying        : containers-common-2:1-91.el9_4.x86_64                 8/42 
  Verifying        : toolbox-0.1.2-1.rhaos4.18.el9.noarch                  9/42 
  Verifying        : toolbox-0.0.99.5-2.el9.x86_64                        10/42 
  Verifying        : skopeo-2:1.16.1-1.rhaos4.18.el9.x86_64               11/42 
  Verifying        : skopeo-2:1.14.5-2.el9_4.x86_64                       12/42 
  Verifying        : container-selinux-4:2.235.0-2.rhaos4.18.el9.noarch   13/42 
  Verifying        : container-selinux-3:2.229.0-1.el9_3.noarch           14/42 
  Verifying        : podman-5:5.2.2-8.rhaos4.18.el9.x86_64                15/42 
  Verifying        : podman-4:4.9.4-18.el9_4.x86_64                       16/42 
  Verifying        : crun-1.21-1.rhaos4.18.el9.x86_64                     17/42 
  Verifying        : crun-1.14.3-3.el9_4.x86_64                           18/42 
  Verifying        : selinux-policy-38.1.35-2.el9_4.4.noarch              19/42 
  Verifying        : selinux-policy-38.1.35-2.el9_4.3.noarch              20/42 
  Verifying        : selinux-policy-targeted-38.1.35-2.el9_4.4.noarch     21/42 
  Verifying        : selinux-policy-targeted-38.1.35-2.el9_4.3.noarch     22/42 
  Verifying        : gnutls-3.8.3-4.el9_4.2.x86_64                        23/42 
  Verifying        : gnutls-3.8.3-4.el9_4.x86_64                          24/42 
  Verifying        : dracut-057-54.git20250423.el9_4.x86_64               25/42 
  Verifying        : dracut-057-53.git20240104.el9.x86_64                 26/42 
  Verifying        : dracut-network-057-54.git20250423.el9_4.x86_64       27/42 
  Verifying        : dracut-network-057-53.git20240104.el9.x86_64         28/42 
  Verifying        : dracut-squash-057-54.git20250423.el9_4.x86_64        29/42 
  Verifying        : dracut-squash-057-53.git20240104.el9.x86_64          30/42 
  Verifying        : libsmbclient-4.19.4-105.el9_4.2.x86_64               31/42 
  Verifying        : libsmbclient-4.19.4-105.el9_4.1.x86_64               32/42 
  Verifying        : libtasn1-4.16.0-8.el9_4.1.x86_64                     33/42 
  Verifying        : libtasn1-4.16.0-8.el9_1.x86_64                       34/42 
  Verifying        : libwbclient-4.19.4-105.el9_4.2.x86_64                35/42 
  Verifying        : libwbclient-4.19.4-105.el9_4.1.x86_64                36/42 
  Verifying        : samba-client-libs-4.19.4-105.el9_4.2.x86_64          37/42 
  Verifying        : samba-client-libs-4.19.4-105.el9_4.1.x86_64          38/42 
  Verifying        : samba-common-4.19.4-105.el9_4.2.noarch               39/42 
  Verifying        : samba-common-4.19.4-105.el9_4.1.noarch               40/42 
  Verifying        : samba-common-libs-4.19.4-105.el9_4.2.x86_64          41/42 
  Verifying        : samba-common-libs-4.19.4-105.el9_4.1.x86_64          42/42 
Installed products updated.

Upgraded:
  conmon-3:2.1.12-7.rhaos4.18.el9.x86_64                                        
  container-selinux-4:2.235.0-2.rhaos4.18.el9.noarch                            
  containers-common-3:1-86.rhaos4.18.el9.x86_64                                 
  crun-1.21-1.rhaos4.18.el9.x86_64                                              
  dracut-057-54.git20250423.el9_4.x86_64                                        
  dracut-network-057-54.git20250423.el9_4.x86_64                                
  dracut-squash-057-54.git20250423.el9_4.x86_64                                 
  gnutls-3.8.3-4.el9_4.2.x86_64                                                 
  libsmbclient-4.19.4-105.el9_4.2.x86_64                                        
  libtasn1-4.16.0-8.el9_4.1.x86_64                                              
  libwbclient-4.19.4-105.el9_4.2.x86_64                                         
  podman-5:5.2.2-8.rhaos4.18.el9.x86_64                                         
  samba-client-libs-4.19.4-105.el9_4.2.x86_64                                   
  samba-common-4.19.4-105.el9_4.2.noarch                                        
  samba-common-libs-4.19.4-105.el9_4.2.x86_64                                   
  selinux-policy-38.1.35-2.el9_4.4.noarch                                       
  selinux-policy-targeted-38.1.35-2.el9_4.4.noarch                              
  skopeo-2:1.16.1-1.rhaos4.18.el9.x86_64                                        
  toolbox-0.1.2-1.rhaos4.18.el9.noarch                                          
Installed:
  kernel-5.14.0-427.72.1.el9_4.x86_64                                           
  kernel-core-5.14.0-427.72.1.el9_4.x86_64                                      
  kernel-modules-5.14.0-427.72.1.el9_4.x86_64                                   
  kernel-modules-core-5.14.0-427.72.1.el9_4.x86_64                              

Complete!
Updating Subscription Management repositories.
Unable to read consumer identity
subscription-manager is operating in container mode.

This system is not registered with an entitlement server. You can use subscription-manager to register.

50 files removed
COMMIT microshift-4.18-bootc-embeeded:v2
--> caa7e025d75f
[root@rhel94-local ~]# podman images|grep microshift|grep local
localhost/microshift-4.18-bootc-embeeded                     v2                    5f3b9b9fdb86  2 days ago     4.99 GB
localhost/microshift-4.18-bootc-embeeded                     v1                    39c7901b7b89  2 days ago     4.6 GB
localhost/microshift-4.18-bootc                              latest                778da22563f5  10 days ago    2.38 GB
[root@rhel94-local bootc-embeeded-containers]# 
~~~

##### Export Images to .tar

Use podman save to export the images:
~~~
podman save -o base-image.tar localhost/delta-oci-image:v1
podman save -o updated-image.tar localhost/delta-oci-image:v2
~~~

In our sample here, our updated OCI `microshift-4.18-bootc-embeeded:v2` is built from `microshift-4.18-bootc-embeeded:v1` and it does include only baseOS updates with ~390Mbytes of size. 

~~~
[root@rhel94-local ~]# podman images|grep microshift|grep local
localhost/microshift-4.18-bootc-embeeded                     v2                    5f3b9b9fdb86  2 days ago     4.99 GB
localhost/microshift-4.18-bootc-embeeded                     v1                    39c7901b7b89  2 days ago     4.6 GB
localhost/microshift-4.18-bootc                              latest                778da22563f5  10 days ago    2.38 GB
[root@rhel94-local ~]# podman save -o microshift-4.18-bootc-embeeded-v1.tar localhost/microshift-4.18-bootc-embeeded:v1
Copying blob 520d77fe5a18 done   | 
Copying blob 520d77fe5a18 done   | 
Copying blob 520d77fe5a18 done   | 
Copying blob 8b1ca488d473 done   | 
Copying blob a16a8823dad8 done   | 
Copying blob 5fa3edd23413 done   | 
Copying blob 84ee3ae1b356 done   | 
Copying config 39c7901b7b done   | 
(..)
Writing manifest to image destination
[root@rhel94-local ~]# 
[root@rhel94-local ~]# podman save -o microshift-4.18-bootc-embeeded-v2.tar localhost/microshift-4.18-bootc-embeeded:v2
Copying blob 520d77fe5a18 done   | 
Copying blob 520d77fe5a18 done   | 
Copying blob 520d77fe5a18 done   | 
Copying blob 520d77fe5a18 done   | 
Copying blob 7e2558927ccf done   | 
(..)
Copying blob 459fa026fdf6 done   | 
Copying blob 9f97221ac7c5 done   | 
Copying config 5f3b9b9fdb done   | 
Writing manifest to image destination
~~~

##### Installing tar-diff and tar-patch from source (to raise a issue to the repo): 

https://github.com/containers/tar-diff.git is not a very active repo, updated 5 years ago. And it does contains the binaries, so, you need to build. 
To build it, you need to have GoLang 1.22. So, you are running on RHEL 9.4+ (maybe even for 9.2), you must download GoLang binaries directly instead of using our rpms.  

~~~
[root@rhel94-local tar-diff]# wget https://go.dev/dl/go1.22.12.linux-amd64.tar.gz 
--2025-06-20 12:33:41--  https://go.dev/dl/go1.22.12.linux-amd64.tar.gz
Resolving go.dev (go.dev)... 216.239.32.21, 216.239.36.21, 216.239.34.21, ...
Connecting to go.dev (go.dev)|216.239.32.21|:443... connected.
HTTP request sent, awaiting response... 302 Found
Location: https://dl.google.com/go/go1.22.12.linux-amd64.tar.gz [following]
--2025-06-20 12:33:42--  https://dl.google.com/go/go1.22.12.linux-amd64.tar.gz
Resolving dl.google.com (dl.google.com)... 172.217.20.206, 2a00:1450:4007:810::200e
Connecting to dl.google.com (dl.google.com)|172.217.20.206|:443... connected.
HTTP request sent, awaiting response... 200 OK
Length: 68995422 (66M) [application/x-gzip]
Saving to: ‘go1.22.12.linux-amd64.tar.gz’

go1.22.12.linux-amd64.tar.gz                         100%[=====================================================================================================================>]  65.80M  25.5MB/s    in 2.6s    

2025-06-20 12:33:45 (25.5 MB/s) - ‘go1.22.12.linux-amd64.tar.gz’ saved [68995422/68995422]

[root@rhel94-local tar-diff]# tar -C /usr/local -xzf go1.22.*.linux-amd64.tar.gz
[root@rhel94-local tar-diff]# export PATH=$PATH:/usr/local/go/bin

[root@rhel94-local tar-diff]# go version
go version go1.22.12 linux/amd64
~~~


~~~
[root@rhel94-local tar-diff]# ll
total 67440
drwxr-xr-x. 4 root root       39 Jun 20 12:31 cmd
-rw-r--r--. 1 root root      193 Jun 20 12:31 CODE-OF-CONDUCT.md
-rw-r--r--. 1 root root     1973 Jun 20 12:31 file-format.md
-rw-r--r--. 1 root root 68995422 Feb  4 16:41 go1.22.12.linux-amd64.tar.gz
-rw-r--r--. 1 root root      138 Jun 20 12:31 go.mod
-rw-r--r--. 1 root root    21809 Jun 20 12:31 go.sum
-rw-r--r--. 1 root root    10728 Jun 20 12:31 LICENSE
-rw-r--r--. 1 root root     2184 Jun 20 12:31 Makefile
drwxr-xr-x. 5 root root       53 Jun 20 12:31 pkg
-rw-r--r--. 1 root root     1419 Jun 20 12:31 README.md
-rw-r--r--. 1 root root      241 Jun 20 12:31 SECURITY.md
drwxr-xr-x. 2 root root       21 Jun 20 12:31 tests

[root@rhel94-local tar-diff]# make tar-diff
GO111MODULE="on" go build  ./cmd/tar-diff
[root@rhel94-local tar-diff]# make build
GO111MODULE="on" go build  ./...
[root@rhel94-local tar-diff]# make install
GO111MODULE="on" go build  ./cmd/tar-patch
install -d -m 755 /usr/bin
install -m 755 tar-diff /usr/bin/tar-diff
install -m 755 tar-patch /usr/bin/tar-patch
~~~

##### Generate Delta Using Tar-Diff

1. Stage Your Images: Ensure both base-image.tar and updated-image.tar are present.
2. Generate the Delta: Run the tar-diff command.

~~~
tar-diff base-image.tar updated-image.tar delta_update.tar
~~~

As you can see, v1 image have 4761 Mbytes, v2 4761 Mbytes and the **delta only 207 Mbytes**. This is pretty much aligned to the outputs of `dnf updates` when building v2 image:  
~~~ 
[root@rhel94-local ~]# ls -la microshift-*tar
-rw-r--r--. 1 root root 4596023296 Jun 20 11:55 microshift-4.18-bootc-embeeded-v1.tar
-rw-r--r--. 1 root root 4991577088 Jun 20 12:00 microshift-4.18-bootc-embeeded-v2.tar
[root@rhel94-local ~]# #tar-diff base-image.tar updated-image.tar delta_update.tar
[root@rhel94-local ~]# tar-diff microshift-4.18-bootc-embeeded-v1.tar microshift-4.18-bootc-embeeded-v2.tar delta_microshift-4.18-bootc-embeeded-v2.tar
[root@rhel94-local ~]# echo $?
0
[root@rhel94-local ~]# du -sm *microshift-4.18-bootc-embeeded-v*tar
207	delta_microshift-4.18-bootc-embeeded-v2.tar
4384	microshift-4.18-bootc-embeeded-v1.tar
4761	microshift-4.18-bootc-embeeded-v2.tar
[root@rhel94-local ~]# 
~~~

3. Transfer the Delta: Send the resulting delta_update.tar file to your Local Registry & Patching Host.

##### Reconstruct v2 from the delta On the Local Registry

This server acts as the central hub for updates. It will receive the delta, reconstruct the new image, and publish it to its own registry service.

**Requirements**:
- `base-image.tar`: The original image archive.
- `delta_update.tar`: The delta file received from the build system.
- `tar-patch` binary: The utility to apply the patch (see installation steps above).
- An OCI container engine: Typically podman on a RHEL system.
- A running OCI registry service: The registry to which the new image will be pushed.

**Steps:**

1. Prepare Host: Ensure all requirements are met. The delta_update.tar has been copied to the server, and base-image.tar is available.
2. Extract the base image:
   ~~~
   # mkdir base-image
   # tar -xf base-image.tar -C base-image
   ~~~
   Sample output: 
   ~~~
   [root@rhel94-local deltas]# mkdir base-image
   [root@rhel94-local deltas]# tar -xf microshift-4.18-bootc-embeeded-v1.tar -C base-image
   [root@rhel94-local deltas]# du -sm base-image/
   4384	base-image/
   ~~~
3. Reconstruct the Image Archive: Run `tar-patch` to create the full `updated-image.tar`.
   ~~~
   tar-patch base-image.tar delta_update.tar reconstructed_image.tar 
   ~~~
   
   In this lab, we do have all images available, so we can compare size and hash: 
   ~~~
   [root@rhel94-local deltas]# tar-patch delta_microshift-4.18-bootc-embeeded-v2.tar base-image/ reconstructed_microshift-4.18-bootc-embeeded-v2.tar
   [root@rhel94-local deltas]# echo $?
   0
   [root@rhel94-local deltas]# du -sm *
   4384	base-image
   207	delta_microshift-4.18-bootc-embeeded-v2.tar
   4384	microshift-4.18-bootc-embeeded-v1.tar
   4761	microshift-4.18-bootc-embeeded-v2.tar
   4761	reconstructed_microshift-4.18-bootc-embeeded-v2.tar
   [root@rhel94-local deltas]# sha
   sha1hmac    sha1sum     sha224hmac  sha224sum   sha256hmac  sha256sum   sha384hmac  sha384sum   sha512hmac  sha512sum   shade-jar   shasum      
   [root@rhel94-local deltas]# sha256sum *tar
   d0443b08557644351f39b7040affacfdbab718afbe128097237014fac9ebbfa1  delta_microshift-4.18-bootc-embeeded-v2.tar
   d9af229feca6f2051494a9f5ff3fd1318eb95e22c044b80fe811b35b85a3580a  microshift-4.18-bootc-embeeded-v1.tar
   d5e4bc60e50772eb64d393bc9f569e2746a461dd093d12618a2d9be1e099785f  microshift-4.18-bootc-embeeded-v2.tar
   d5e4bc60e50772eb64d393bc9f569e2746a461dd093d12618a2d9be1e099785f  reconstructed_microshift-4.18-bootc-embeeded-v2.tar
   [root@rhel94-local deltas]# 
   ~~~
4. Load the generated image to a local OCI registry: 
   ~~~
   podman load -i reconstructed_microshift-4.18-bootc-embeeded-v2.tar
   podman tag microshift-4.18-bootc-embeeded:v2 localhost:5000/microshift-4.18-bootc-embeeded:v2
   podman push localhost:5000/microshift-4.18-bootc-embeeded:v2
   ~~~

##### Patching Host
In this context, our far-edge system must be installed from the ISO, as for remote locations we distribute the installation medias (USB, DVD, etc) due restricted internet connections. Then, as our far-edge node does have access to a local registry within the same LAN, the first update will be using `bootc switch`. 

Check current status of the system: 
~~~
[redhat@localhost patch]$ cat /etc/redhat-release 
Red Hat Enterprise Linux release 9.4 (Plow)
[redhat@localhost patch]$ uname -a
Linux microshift-4.18-bootc-isolated-v1 5.14.0-427.65.1.el9_4.x86_64 #1 SMP PREEMPT_DYNAMIC Fri Apr 11 15:52:56 EDT 2025 x86_64 x86_64 x86_64 GNU/Linux
[redhat@localhost patch]$ microshift version
MicroShift Version: 4.18.11
Base OCP Version: 4.18.11
[redhat@localhost patch]$ oc get pods -A
NAMESPACE                  NAME                                      READY   STATUS    RESTARTS        AGE
dotnet-memory-leak-app     dotnet-memory-leak-app-f54754f4c-kgwsb    1/1     Running   0               2d3h
example-apps-wordpress     wordpress-ff94c8dcf-8n885                 1/1     Running   0               2d18h
example-apps-wordpress     wordpress-mysql-84dd895d65-vnff2          1/1     Running   0               2d18h
kube-system                csi-snapshot-controller-85ccb45d4-9z2rd   1/1     Running   0               2d18h
openshift-dns              dns-default-dp5dt                         2/2     Running   0               2d18h
openshift-dns              node-resolver-wzgcg                       1/1     Running   0               2d18h
openshift-ingress          router-default-6ddbc959b9-dvs7q           1/1     Running   0               2d18h
openshift-ovn-kubernetes   ovnkube-master-4zld7                      4/4     Running   1 (2d18h ago)   2d18h
openshift-ovn-kubernetes   ovnkube-node-xgxtp                        1/1     Running   1 (2d18h ago)   2d18h
openshift-service-ca       service-ca-7b964bd597-hsh6p               1/1     Running   2 (2d12h ago)   2d18h
openshift-storage          lvms-operator-d6f9c9d4-grwdv              1/1     Running   0               2d18h
openshift-storage          vg-manager-24ptl                          1/1     Running   7 (42h ago)     2d18h
[redhat@localhost patch]$ 
[redhat@localhost patch]$ cat /etc/redhat-release 
Red Hat Enterprise Linux release 9.4 (Plow)
[redhat@localhost patch]$ sudo bootc status
[sudo] password for redhat: 
apiVersion: org.containers.bootc/v1alpha1
kind: BootcHost
metadata:
  name: host
spec:
  image:
    image: localhost/microshift-4.18-bootc-embedded
    transport: registry
  bootOrder: default
status:
  staged: null
  booted:
    image:
      image:
        image: localhost/microshift-4.18-bootc-embedded
        transport: registry
      version: 9.20250429.0
      timestamp: null
      imageDigest: sha256:3fca0adf6e1233c9fdfd4f2dcc52474386c65c657aece047d6ff95d4bc951cac
    cachedUpdate: null
    incompatible: false
    pinned: false
    store: ostreeContainer
    ostree:
      checksum: c44783039070260d412378f2f5e5650f8ff3187b32e5e156f8778afaad526dab
      deploySerial: 0
  rollback: null
  rollbackQueued: false
  type: bootcHost
[redhat@localhost patch]$ sudo rpm-ostree status
State: idle
Deployments:
● ostree-unverified-registry:localhost/microshift-4.18-bootc-embedded
                   Digest: sha256:3fca0adf6e1233c9fdfd4f2dcc52474386c65c657aece047d6ff95d4bc951cac
                  Version: 9.20250429.0 (2025-06-17T16:38:19Z)
[redhat@localhost patch]$ 
[redhat@localhost patch]$ systemctl status greenboot-status.service 
● greenboot-status.service - greenboot MotD Generator
     Loaded: loaded (/usr/lib/systemd/system/greenboot-status.service; enabled; preset: enabled)
     Active: active (exited) since Tue 2025-06-17 17:24:50 UTC; 2 days ago
    Process: 7103 ExecStart=/usr/libexec/greenboot/greenboot-status (code=exited, status=0/SUCCESS)
   Main PID: 7103 (code=exited, status=0/SUCCESS)
        CPU: 20ms

Jun 17 17:24:50 localhost.localdomain systemd[1]: Starting greenboot MotD Generator...
Jun 17 17:24:50 localhost.localdomain greenboot-status[7112]: Boot Status is GREEN - Health Check SUCCESS
Jun 17 17:24:50 localhost.localdomain systemd[1]: Finished greenboot MotD Generator.
[redhat@localhost patch]$ systemctl status greenboot-healthcheck.service 
● greenboot-healthcheck.service - greenboot Health Checks Runner
     Loaded: loaded (/usr/lib/systemd/system/greenboot-healthcheck.service; enabled; preset: enabled)
     Active: active (exited) since Tue 2025-06-17 17:24:50 UTC; 2 days ago
    Process: 745 ExecStart=/usr/libexec/greenboot/greenboot check (code=exited, status=0/SUCCESS)
   Main PID: 745 (code=exited, status=0/SUCCESS)
        CPU: 20.287s

Jun 17 17:23:57 localhost.localdomain 40_microshift_running_check.sh[774]: Checking pod restart count in the 'openshift-ovn-kubernetes' namespace
Jun 17 17:23:57 localhost.localdomain 40_microshift_running_check.sh[774]: Checking pod restart count in the 'openshift-service-ca' namespace
Jun 17 17:23:57 localhost.localdomain 40_microshift_running_check.sh[774]: Checking pod restart count in the 'openshift-ingress' namespace
Jun 17 17:23:57 localhost.localdomain 40_microshift_running_check.sh[774]: Checking pod restart count in the 'openshift-dns' namespace
Jun 17 17:23:57 localhost.localdomain 40_microshift_running_check.sh[774]: Checking pod restart count in the 'openshift-storage' namespace
Jun 17 17:23:57 localhost.localdomain 40_microshift_running_check.sh[774]: Checking pod restart count in the 'kube-system' namespace
Jun 17 17:24:50 localhost.localdomain 40_microshift_running_check.sh[774]: FINISHED
Jun 17 17:24:50 localhost.localdomain greenboot[745]: Script '40_microshift_running_check.sh' SUCCESS
Jun 17 17:24:50 localhost.localdomain greenboot[745]: Running Wanted Health Check Scripts...
Jun 17 17:24:50 localhost.localdomain systemd[1]: Finished greenboot Health Checks Runner.
[redhat@localhost patch]$ 
~~~

Upgrade with `bootc switch`: 

In this lab we are using a simple and insecure registry, so we need to Add a new registry entry:
Scroll through the file and add the following block. You can add it after the [registries.insecure] or [registries.search] sections, or at the end of the file.

~~~
[[registry]]
prefix = "192.168.111.152:5000"
location = "192.168.111.152:5000"
insecure = true
~~~

Then, Upgrade with `bootc switch`: 
~~~
[redhat@localhost patch]$ sudo bootc switch 192.168.111.152:5000/microshift-4.18-bootc-embeeded:v2
layers already present: 80; layers needed: 2 (230.5 MB)
Fetched layers: 219.81 MiB in 15 seconds (14.79 MiB/s)
Pruned images: 1 (layers: 0, objsize: 0 bytes)
Queued for next boot: 192.168.111.152:5000/microshift-4.18-bootc-embeeded:v2
  Version: 9.20250429.0
  Digest: sha256:1df6d058a1b086a0ecfd257ff743efc39010b29d4f41d1a634a4ad3e6c4430d9
[redhat@localhost patch]$ 
~~~

Check current status of bootc and ostree. We can see here that the updated image contains `Diff: 19 upgraded, 4 added`: 

~~~
apiVersion: org.containers.bootc/v1alpha1
kind: BootcHost
metadata:
  name: host
spec:
  image:
    image: 192.168.111.152:5000/microshift-4.18-bootc-embeeded:v2
    transport: registry
  bootOrder: default
status:
  staged:
    image:
      image:
        image: 192.168.111.152:5000/microshift-4.18-bootc-embeeded:v2
        transport: registry
      version: 9.20250429.0
      timestamp: null
      imageDigest: sha256:1df6d058a1b086a0ecfd257ff743efc39010b29d4f41d1a634a4ad3e6c4430d9
    cachedUpdate: null
    incompatible: false
    pinned: false
    store: ostreeContainer
    ostree:
      checksum: abf40b982c71b69c7da4cbf8ec08c9ea2ba608785a11319650d3149cea2cb1a9
      deploySerial: 0
  booted:
    image:
      image:
        image: localhost/microshift-4.18-bootc-embedded
        transport: registry
      version: 9.20250429.0
      timestamp: null
      imageDigest: sha256:3fca0adf6e1233c9fdfd4f2dcc52474386c65c657aece047d6ff95d4bc951cac
    cachedUpdate: null
    incompatible: false
    pinned: false
    store: ostreeContainer
    ostree:
      checksum: c44783039070260d412378f2f5e5650f8ff3187b32e5e156f8778afaad526dab
      deploySerial: 0
  rollback: null
  rollbackQueued: false
  type: bootcHost
[redhat@localhost patch]$ 
[redhat@localhost patch]$ sudo rpm-ostree status
State: idle
Deployments:
  ostree-unverified-registry:192.168.111.152:5000/microshift-4.18-bootc-embeeded:v2
                   Digest: sha256:1df6d058a1b086a0ecfd257ff743efc39010b29d4f41d1a634a4ad3e6c4430d9
                  Version: 9.20250429.0 (2025-06-18T08:22:10Z)
                     Diff: 19 upgraded, 4 added

● ostree-unverified-registry:localhost/microshift-4.18-bootc-embedded
                   Digest: sha256:3fca0adf6e1233c9fdfd4f2dcc52474386c65c657aece047d6ff95d4bc951cac
                  Version: 9.20250429.0 (2025-06-17T16:38:19Z)
[redhat@localhost patch]$ 
~~~

Apply & Reboot: 
~~~
[redhat@localhost patch]$ sudo bootc upgrade --apply 
No changes in 192.168.111.152:5000/microshift-4.18-bootc-embeeded:v2 => sha256:1df6d058a1b086a0ecfd257ff743efc39010b29d4f41d1a634a4ad3e6c4430d9
Staged update present, not changed.
Rebooting system
Connection to 192.168.111.227 closed by remote host.
Connection to 192.168.111.227 closed.
~~~

Check the status after the upgrade: 
~~~
arolivei@arolivei-thinkpadp16vgen1:~/VirtualMachines$ ssh redhat@192.168.111.227
redhat@192.168.111.227's password: 
Activate the web console with: systemctl enable --now cockpit.socket

Last login: Wed Jun 18 06:50:07 2025 from 192.168.111.1
[redhat@microshift-4 ~]$ uname -a 
Linux microshift-4.18-bootc-isolated-v1 5.14.0-427.65.1.el9_4.x86_64 #1 SMP PREEMPT_DYNAMIC Fri Apr 11 15:52:56 EDT 2025 x86_64 x86_64 x86_64 GNU/Linux
[redhat@microshift-4 ~]$ cat /etc/redhat-release 
Red Hat Enterprise Linux release 9.4 (Plow)
[redhat@microshift-4 ~]$ microshift version
MicroShift Version: 4.18.11
Base OCP Version: 4.18.11
[redhat@microshift-4 ~]$ sudo rpm-ostree status
[sudo] password for redhat: 
State: idle
Deployments:
● ostree-unverified-registry:192.168.111.152:5000/microshift-4.18-bootc-embeeded:v2
                   Digest: sha256:1df6d058a1b086a0ecfd257ff743efc39010b29d4f41d1a634a4ad3e6c4430d9
                  Version: 9.20250429.0 (2025-06-18T08:22:10Z)

  ostree-unverified-registry:localhost/microshift-4.18-bootc-embedded
                   Digest: sha256:3fca0adf6e1233c9fdfd4f2dcc52474386c65c657aece047d6ff95d4bc951cac
                  Version: 9.20250429.0 (2025-06-17T16:38:19Z)
[redhat@microshift-4 ~]$ sudo bootc status
apiVersion: org.containers.bootc/v1alpha1
kind: BootcHost
metadata:
  name: host
spec:
  image:
    image: 192.168.111.152:5000/microshift-4.18-bootc-embeeded:v2
    transport: registry
  bootOrder: default
status:
  staged: null
  booted:
    image:
      image:
        image: 192.168.111.152:5000/microshift-4.18-bootc-embeeded:v2
        transport: registry
      version: 9.20250429.0
      timestamp: null
      imageDigest: sha256:1df6d058a1b086a0ecfd257ff743efc39010b29d4f41d1a634a4ad3e6c4430d9
    cachedUpdate: null
    incompatible: false
    pinned: false
    store: ostreeContainer
    ostree:
      checksum: abf40b982c71b69c7da4cbf8ec08c9ea2ba608785a11319650d3149cea2cb1a9
      deploySerial: 0
  rollback:
    image:
      image:
        image: localhost/microshift-4.18-bootc-embedded
        transport: registry
      version: 9.20250429.0
      timestamp: null
      imageDigest: sha256:3fca0adf6e1233c9fdfd4f2dcc52474386c65c657aece047d6ff95d4bc951cac
    cachedUpdate: null
    incompatible: false
    pinned: false
    store: ostreeContainer
    ostree:
      checksum: c44783039070260d412378f2f5e5650f8ff3187b32e5e156f8778afaad526dab
      deploySerial: 0
  rollbackQueued: false
  type: bootcHost
[redhat@microshift-4 ~]$ 
~~~
