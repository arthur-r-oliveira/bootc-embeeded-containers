
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
      - [Experimental - OSTree updates bypassing bootc utilities.](#experimental---ostree-updates-bypassing-bootc-utilities)
        - [Updating our Bootc image with latest updates.](#updating-our-bootc-image-with-latest-updates)


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

#### Experimental - OSTree updates bypassing bootc utilities.

As it is possible [extract OSTree commits from OCI](https://github.com/coreos/rpm-ostree/blob/main/docs/container.md#mapping-container-images-back-to-ostree), within this test we are: 

- Updating our Bootc image with latest updates. 
- Extracting all OSTree repository from the updated OCI. 
- Transfer the full OStree repository to a disconnected system and apply the updates. 
- Observe the healthy of the system and bootc status over the time. 

DISCLAIMER: **THIS IS NOT A SUPPORTED UPGRADE PATH FOR BOOTC SYSTEMS. Beying tested and documented with the intension of exploration only.**

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
[root@rhel94-local bootc-embeeded-containers]# podman images|grep microshift
localhost/microshift-4.18-bootc-embeeded         v2                    caa7e025d75f  4 minutes ago   6.66 GB
localhost/microshift-4.18-bootc-embeeded         v1                    c8a50dc29df5  4 days ago      6.26 GB
localhost/microshift-4.18-bootc                  latest                778da22563f5  4 days ago      2.38 GB
[root@rhel94-local bootc-embeeded-containers]# 
~~~

Create a local OSTree repo and pull the OSTree Commits from OCI:

~~~
[root@rhel94-local ~]# mkdir repo
mkdir: cannot create directory ‘repo’: File exists
[root@rhel94-local ~]# ostree --repo=/root/repo init
[root@rhel94-local ~]# ostree container image pull --insecure-skip-tls-verification /root/repo ostree-unverified-registry:quay.io/rhn_support_arolivei/microshift-4.18-bootc-embeeded:v2
layers already present: 0; layers needed: 82 (5.3 GB)
 61.99 MiB [████░░░░░░░░░░░░░░░░] (0s) Fetching layer sha256:d26ef76e8676 (307.9 MB)   
(..)
~~~

Check repo's metadata:
~~~
[root@rhel94-local repo]# du -sm .
5368	.
[root@rhel94-local repo]# ostree --repo=/root/repo summary -u
[root@rhel94-local repo]# ostree --repo=/root/repo summary -v
OT: using fuse: 0
* ostree/container/blob/sha256_3A_05d6802717d74e2078d81a328c6ae1988a93d8f1ceb0203146d2c676c5e320b5
    Latest Commit (86 bytes):
      a5e7cdb2b6ff702a09c790d61751c5eb2555847adb0dbe74bacc7959498e4615
    Timestamp (ostree.commit.timestamp): 1970-01-01T01:00:00+01

* ostree/container/blob/sha256_3A_0643e31e10c3f6d24b2ff40243d30bb558cd7d90e4a74392d7a7c89ecb3f0f9c
    Latest Commit (86 bytes):
      a693c9e9141991accf165fac6ea52d078dbaa9077f142f432a4dd6a891da5522
    Timestamp (ostree.commit.timestamp): 1970-01-01T01:00:00+01

* ostree/container/blob/sha256_3A_123a23fee02fcea5ba915c8c3f99df711e8bb8f0aeaff19c2de249a00106525f
    Latest Commit (86 bytes):
      4eb2e948b002ea90c3c41a1ce1390615de392334dd9f96d124704c1a987cf583
    Timestamp (ostree.commit.timestamp): 1970-01-01T01:00:00+01

* ostree/container/blob/sha256_3A_13dd1760bac04dd71abfc3984673ba4db8330a00d74a16d1681a643f7785957b
    Latest Commit (86 bytes):
      2b1c8b82102ccb09487b3b34728b9ed37a3c3e99178338c00fbd85e4a1aa7c1d
    Timestamp (ostree.commit.timestamp): 1970-01-01T01:00:00+01

* ostree/container/blob/sha256_3A_15736c42742c29fb33b3f74eb15b57c6f5b08a444bff54696128221f6051c3d4
    Latest Commit (86 bytes):
      11ebe23c63fdd631edc9e099568eaa7bbe9c34f2e797578c97009d30ddc2e025
    Timestamp (ostree.commit.timestamp): 1970-01-01T01:00:00+01

* ostree/container/blob/sha256_3A_18ab149f0f36fd9d5132410fa67e65e77b5b0f9b94e234b5d17af5bb0506e371
    Latest Commit (86 bytes):
      ef14df537f9f474431a984c0a397d89002d20f2690d50c80128617d318c88eeb
    Timestamp (ostree.commit.timestamp): 1970-01-01T01:00:00+01

* ostree/container/blob/sha256_3A_1966f2c5fedb219be6a80a356b230cdfd733afa8a00921d0e5247f167bafb89f
    Latest Commit (86 bytes):
      f410f2ea86f7705f0ea4d0deaeaf2164e3778c0c50402b3a47510fdbec8205fe
    Timestamp (ostree.commit.timestamp): 1970-01-01T01:00:00+01

* ostree/container/blob/sha256_3A_202ad3fe1cd4ab7f9a29adbd9d29ef9f6b6df03977cec1b6edd1447da80182d7
    Latest Commit (86 bytes):
      66c164ec913cfd8c5abd01dbb22b9d4c2078cb340516dc2b74af1ce87d41ac50
    Timestamp (ostree.commit.timestamp): 1970-01-01T01:00:00+01

* ostree/container/blob/sha256_3A_21b080004e82d1fcf3047e8151994cead0c4f3a1532c3deff7e9bfa7aa7af663
    Latest Commit (86 bytes):
      760b3b14c5094cfe02e97efda621db52823ba69cf2a8e512002f2ca79c843aea
    Timestamp (ostree.commit.timestamp): 1970-01-01T01:00:00+01

* ostree/container/blob/sha256_3A_242bd4b7d70ceb6c7890537ad517d2e9ad05fdab4e4279e3c8ed928bc1b56cdd
    Latest Commit (86 bytes):
      c01e886dd146f023771607aa756a641710698f0ef6025b0becedbc47ab2b3027
    Timestamp (ostree.commit.timestamp): 1970-01-01T01:00:00+01

* ostree/container/blob/sha256_3A_247f1cfe37bdc5bc68d1efe9745a323f4bb75b92f0ba58cf12b1e8613131758f
    Latest Commit (86 bytes):
      d584099852c3ab50c7d2b9c88e7b36018b3ffa362835ac5cfb13c576bda19d51
    Timestamp (ostree.commit.timestamp): 1970-01-01T01:00:00+01

* ostree/container/blob/sha256_3A_253e5f6c18184b52037a654371699a8a6ce91c944826d64e86b1bdefbf979bf4
    Latest Commit (86 bytes):
      a579da7ffcf1f911592f786ac767f5199d6c59b9890d4990561f4e024afdc165
    Timestamp (ostree.commit.timestamp): 1970-01-01T01:00:00+01

* ostree/container/blob/sha256_3A_284f9292018e14d68e4f7b60edd1dbbe1e835e962f7f5e14da1fbd636890a91c
    Latest Commit (118 bytes):
      568e6a5197f51be1af0304c974849ee95f73f47f413378df80645453580b047a
    Timestamp (ostree.commit.timestamp): 2025-06-13T19:24:46+01

* ostree/container/blob/sha256_3A_29cd45565a5bdc59ed4c75545999ffd9ea65551d402f383f0ef5ceeebde3cd54
    Latest Commit (86 bytes):
      0466eb19720c1eafa396420fd462b73032582ecdaed81e514e920ea710a85df8
    Timestamp (ostree.commit.timestamp): 1970-01-01T01:00:00+01

* ostree/container/blob/sha256_3A_2e2b6f8600d2853d2e7ef8dc27c056051bcc70450d0bfc1a41547129aa7de70c
    Latest Commit (86 bytes):
      300a0c229f68f57038baac6930d2028bb41b2cdf4f294f926ad79bd7a71bed27
    Timestamp (ostree.commit.timestamp): 1970-01-01T01:00:00+01

* ostree/container/blob/sha256_3A_2ec333bbfe22f1842b1ddf8594039d19d47ac40b2aa6c581f56ec7c2bcbe73a8
    Latest Commit (86 bytes):
      303d869d06171e3b241e419211e1c34b3d0ef5dcdf81e17b4b6a54ad19fe7251
    Timestamp (ostree.commit.timestamp): 1970-01-01T01:00:00+01

* ostree/container/blob/sha256_3A_356559c8327a50599218df5e2f937d87d847c85fb279921beb2a6326bd8b27df
    Latest Commit (86 bytes):
      03b2220cdec80fe67a0c4bdc8baee63bdeb1c53f362e6c95abdf15a6de2d3459
    Timestamp (ostree.commit.timestamp): 1970-01-01T01:00:00+01

* ostree/container/blob/sha256_3A_3a29477447e8ade1cc54fdc25c50d8318cda4d2c5bbfb793dedb9caddcb5c898
    Latest Commit (86 bytes):
      2876dc5a4b716062258879e3ad81d0621a6cb4a4152d098e3fcbfb3742c1482a
    Timestamp (ostree.commit.timestamp): 1970-01-01T01:00:00+01

* ostree/container/blob/sha256_3A_42caf0f2065346ec49f9c84a3e4813a628cc9c6261be4dea3647e80ce4a1f43f
    Latest Commit (118 bytes):
      331c6391508633d23936a01e7e805c05c7328e0923e18bd15f96f1384183f0c4
    Timestamp (ostree.commit.timestamp): 2025-06-13T19:17:49+01

* ostree/container/blob/sha256_3A_47bbeda4fc39e9155964700b57ebb97a8aa5be7512f3f3ae0c93fb972eb6a6cc
    Latest Commit (86 bytes):
      fc85ff11cf991114a03986e1fa39a326d758715bb475c0ec9cd3e847b5c6ffb7
    Timestamp (ostree.commit.timestamp): 1970-01-01T01:00:00+01

* ostree/container/blob/sha256_3A_47f62ae2a568faa28a0ce46e368cdc801763823fe0b0e091898d30d55efcff80
    Latest Commit (18.6 kB):
      d5300817582d40e12023d82aaae126fc3c6fd3d8b5cce707fbd08f88c71bccc3
    Version (ostree.commit.version): 9.20250429.0
    Timestamp (ostree.commit.timestamp): 2025-04-30T00:58:04+01

* ostree/container/blob/sha256_3A_492479b62c9091d5b30051fb067b79b85469bc9deee5551b1aa0e265984fcc47
    Latest Commit (86 bytes):
      3d26b64156daf96f1596097d926e2d47b02e95835ab05c7927f53dce0a3102c7
    Timestamp (ostree.commit.timestamp): 1970-01-01T01:00:00+01

* ostree/container/blob/sha256_3A_4bd911a69b60b477851460cf90bb32570eb84c438ec2ef2fedef10440269e11d
    Latest Commit (86 bytes):
      4e8a246988c81b199a083ec65761a442a20c4b4d9eb376c9c52247a80c1ed6bd
    Timestamp (ostree.commit.timestamp): 1970-01-01T01:00:00+01

* ostree/container/blob/sha256_3A_4e047fc78685ee769aec04ecc44c93032279314a26a21f23d4f44afecfa9dbe4
    Latest Commit (86 bytes):
      a9939d1d3a24583eee97f1ac361e711f79053157f7a785723753ea50a7fdd749
    Timestamp (ostree.commit.timestamp): 1970-01-01T01:00:00+01

* ostree/container/blob/sha256_3A_52d42db1a576a0b5af5c189374fa02c3aa2883a5f536ceac916e2ab26e2aaef3
    Latest Commit (86 bytes):
      6e7d8fa9669d52f8fb79ba7d31d2b30392e4474926e5b94c5f412b9b7d4113b6
    Timestamp (ostree.commit.timestamp): 1970-01-01T01:00:00+01

* ostree/container/blob/sha256_3A_58e306e395e5a89a998d79163be282d2731d6346db987b9c58cc1d1c7bf02a56
    Latest Commit (118 bytes):
      fd3c769b3ade99ddef1b0e45bc3d04ff038fcea6f45a38bb8636cbc2137181ee
    Timestamp (ostree.commit.timestamp): 2025-06-13T19:24:49+01

* ostree/container/blob/sha256_3A_5bbd225f3b702f3152503de343610f1dbb503ee0b724ff51e4275b35e002033a
    Latest Commit (86 bytes):
      b3d892b22c3a17ea8cc649683ebceeea669e6b90f68aa305bcd2e0b392ab2df9
    Timestamp (ostree.commit.timestamp): 1970-01-01T01:00:00+01

* ostree/container/blob/sha256_3A_5e070877bf43435f0fa0ba18e54900a60f79dd7d39b2b5f3a621354a1c3e3eb6
    Latest Commit (86 bytes):
      ce53ab657fed3d8f88744aa53765a908f608cb1925c83cc2b3fe995c4a4263d5
    Timestamp (ostree.commit.timestamp): 1970-01-01T01:00:00+01

* ostree/container/blob/sha256_3A_624413d50b1b963ddce0a286b2b69716329c9a3a36f6ccf1943230bbc1eda467
    Latest Commit (118 bytes):
      83d84edebe47e4ea41d3c46f26883414727a0ad4cfaeda6b85c0f4ff35293e40
    Timestamp (ostree.commit.timestamp): 2025-06-13T19:24:48+01

* ostree/container/blob/sha256_3A_62edc61188eeec795e5356e56803012ebd42ced94e144c0278fbcb67faeeee37
    Latest Commit (86 bytes):
      9a1f4d32aa52f586b517c28e8b4579dba3348205639259416e1a4f2390aa9b41
    Timestamp (ostree.commit.timestamp): 1970-01-01T01:00:00+01

* ostree/container/blob/sha256_3A_694b44a64d0af7aba1b444bbda8664680fe02e3ba693e91d5df05359cf598b0b
    Latest Commit (86 bytes):
      a0c7fbe11d8e8b95d301a59a8fdadde1a94f5d84a72f9e85bffdf2574d510205
    Timestamp (ostree.commit.timestamp): 1970-01-01T01:00:00+01

* ostree/container/blob/sha256_3A_6eced2568a921dcaa1ded47f2eecc410bbfea0207f93d354f3c5aabb4ab34ea2
    Latest Commit (86 bytes):
      c4f6ff540074a24bb5b33afddd7aa2ad378252d5d458c42df51590a433dd2cd2
    Timestamp (ostree.commit.timestamp): 1970-01-01T01:00:00+01

* ostree/container/blob/sha256_3A_6fd45085cb450c96c0f0f8b1890ea065be698154546223f6d4284d222680bd4a
    Latest Commit (86 bytes):
      5890ad5115dc89d156ef84c9cfb79f7ddfc3ddae1172c41ed8596d73287cb626
    Timestamp (ostree.commit.timestamp): 1970-01-01T01:00:00+01

* ostree/container/blob/sha256_3A_732e0147fb211bb8e88e12380b3a6573700f3ca79cce9adb6159e810686da4f0
    Latest Commit (118 bytes):
      4911a207d2167fd0762822a672447373e1eb6f84cad3f367389584cc2d658d02
    Timestamp (ostree.commit.timestamp): 2025-06-13T19:17:45+01

* ostree/container/blob/sha256_3A_7e0b03eff7ecd30c002d21522d952ecf7d6f098a6496339381aa746e59beca11
    Latest Commit (86 bytes):
      1e8f08b43ad44c0287affc149c11d2c5c0fe4b13044343f63a9bfddf282fcdaa
    Timestamp (ostree.commit.timestamp): 1970-01-01T01:00:00+01

* ostree/container/blob/sha256_3A_7e936b6df2faaba3119c05585b3bfb654baf0dcd4e378452e2ab437f173a5459
    Latest Commit (118 bytes):
      b17b20c8dd776f0f2297b3d896c44575d85cc3ac53f2b04325cfcd7504535b27
    Timestamp (ostree.commit.timestamp): 2025-06-13T19:25:20+01

* ostree/container/blob/sha256_3A_846d8c9ce4341771be2cc02318cc2ba24248864eceae7225bb296eef206ccd30
    Latest Commit (86 bytes):
      30b02c3a3fcac5317f007228b71306c833b4923e6f9f93e71ac3d6d2e8a48e77
    Timestamp (ostree.commit.timestamp): 1970-01-01T01:00:00+01

* ostree/container/blob/sha256_3A_8598fb22bc46af86c3a5bdf4e6f35684cc82a07c7e6c16c9a7f77f0c71b1abaf
    Latest Commit (86 bytes):
      750eb6777a1fea6c1786020552e198d33d635798abc466eaf9d7726f9dbdad44
    Timestamp (ostree.commit.timestamp): 1970-01-01T01:00:00+01

* ostree/container/blob/sha256_3A_880c478179aaabda95c2a07295c79dfe421daa3f6e38c9d2089bc3226ddf4272
    Latest Commit (86 bytes):
      9e59d9b2d3bd17d10ff515d31ad8cf4196d3369a75b9a247edc24d22bb7394a8
    Timestamp (ostree.commit.timestamp): 1970-01-01T01:00:00+01

* ostree/container/blob/sha256_3A_8bfc0e089ba960376546754faa80b7c7d704f68302bd5830ec5d5f5c46014047
    Latest Commit (86 bytes):
      ba43193ca3bb1751152107ac5827602ce8ebd17c663bf1d4a971f515974c412d
    Timestamp (ostree.commit.timestamp): 1970-01-01T01:00:00+01

* ostree/container/blob/sha256_3A_8dd992c765f031f50fb44299ddbbdcb00826f72128adde30e039b205c55d420f
    Latest Commit (86 bytes):
      2ecc7c7f048d022b295388dfeebcced7a8c6e444b21c1af61477d3a684a7ea71
    Timestamp (ostree.commit.timestamp): 1970-01-01T01:00:00+01

* ostree/container/blob/sha256_3A_902c65b86464852a3a3f79c9a0fcefc976669ed58296d182d9fe187e2a612627
    Latest Commit (86 bytes):
      c039da2ed6bf5697fc2bad236ec9fcb29a3fd151294e50b9f93988edabb90422
    Timestamp (ostree.commit.timestamp): 1970-01-01T01:00:00+01

* ostree/container/blob/sha256_3A_94c17a2237b13738ed26606b79166856a661ddb4898b20a3786c6eba15e78c45
    Latest Commit (86 bytes):
      6f79bbb26e799c04c2753c1d3576af92ab28328b3687e9cf09292f2042186d38
    Timestamp (ostree.commit.timestamp): 1970-01-01T01:00:00+01

* ostree/container/blob/sha256_3A_9be42f263b233f8c75e87b053950b402fce53558746eff267957fac5b7f8d845
    Latest Commit (118 bytes):
      e71c328502b26ec8e91ddc368673551ab8315cb664ce808963e1cb8ef2c9f7a9
    Timestamp (ostree.commit.timestamp): 2025-06-13T19:21:21+01

* ostree/container/blob/sha256_3A_9c884c682dc135b4a211c5488ff10fbe7258c0ab6e18c1331ac4f30a6e72179d
    Latest Commit (86 bytes):
      56b90ff858052e32fff092ba9e6ee5aed09340c65167d65c5eff93f79b7bb9c9
    Timestamp (ostree.commit.timestamp): 1970-01-01T01:00:00+01

* ostree/container/blob/sha256_3A_9f86bf49766dafc612d4cbfc285004ba3615d7567551362586fa16663331e280
    Latest Commit (86 bytes):
      00394292486c68f4050b870be73cea416ec0cfc21b51dfac120d723862bdd3bb
    Timestamp (ostree.commit.timestamp): 1970-01-01T01:00:00+01

* ostree/container/blob/sha256_3A_a36bc02c82c5eb0d45f409ee009ad63f849cdefbf5e1c4be6003b77fdff393c5
    Latest Commit (118 bytes):
      bb37c8a6fdc14a2abe3961325e73fe3df89579c72d5e41d84e1981e85190475e
    Timestamp (ostree.commit.timestamp): 2025-06-13T19:24:50+01

* ostree/container/blob/sha256_3A_a5f4b0fa0ba76d0268d5722a1e5370221ff0d2fafd59b4a36f4e9a2cca60c6b1
    Latest Commit (86 bytes):
      b5d1aa221fc511f4428127f424fbd959748d889fb29a7f831a15648841dacb6b
    Timestamp (ostree.commit.timestamp): 1970-01-01T01:00:00+01

* ostree/container/blob/sha256_3A_ab3994c50f3892ec655ece8b3a502d7b4e983b598d06803c1582fd8dafb1e79c
    Latest Commit (86 bytes):
      db8a04e4c197378ba67af1e022d6d36e7c12b884339a1925555a93d81d18facb
    Timestamp (ostree.commit.timestamp): 1970-01-01T01:00:00+01

* ostree/container/blob/sha256_3A_ad312c5c40ccd18a3c639cc139211f3c4284e568b69b2e748027cee057986fe0
    Latest Commit (86 bytes):
      6109d33e99f48e9b90cdf8ad037b8e5d20ef899697cfd3eb492cf78800aed498
    Timestamp (ostree.commit.timestamp): 1970-01-01T01:00:00+01

* ostree/container/blob/sha256_3A_af52e3360db3a6c6cefa705ba889fd355135af8ccc86bdc06aabef328f2b279e
    Latest Commit (86 bytes):
      9bc164967969396b581d4bb7cfc434d400b5bd1a997550b1a406f7fdba87b3c1
    Timestamp (ostree.commit.timestamp): 1970-01-01T01:00:00+01

* ostree/container/blob/sha256_3A_afe14d1785245750d24272a99336c68f42cba1d297891faf7cbaa6052705f000
    Latest Commit (86 bytes):
      bc53fe2fe3b4bc92b698620829043d6df99d41f821e7a5ab65339011e489c812
    Timestamp (ostree.commit.timestamp): 1970-01-01T01:00:00+01

* ostree/container/blob/sha256_3A_b0b79e518fe0f3abf125916bc0ee89872844419270597f327d12238df9398dca
    Latest Commit (118 bytes):
      f0bcfd470033a8fd70bacd6b9e4de81147d883ca929f542fbd9503c809ea7115
    Timestamp (ostree.commit.timestamp): 2025-06-13T19:17:48+01

* ostree/container/blob/sha256_3A_b72788d3bc178ac86469cde4098af293bbf3cb5919575fbec6f06621408cc90d
    Latest Commit (86 bytes):
      9c3d92b9a07da6899570e3fccc72fb86619f03375bd7a58428382cb1c9c22d7f
    Timestamp (ostree.commit.timestamp): 1970-01-01T01:00:00+01

* ostree/container/blob/sha256_3A_b8231dc71e6a7cc1e01b42b306be5885ba9d44f86f8818fdef0c4ad74234fffe
    Latest Commit (86 bytes):
      bb5da1f3621299bfc38de3dcedc78fb5e65ce04675ae89208a1e76695722d1e9
    Timestamp (ostree.commit.timestamp): 1970-01-01T01:00:00+01

* ostree/container/blob/sha256_3A_bd9ddc54bea929a22b334e73e026d4136e5b73f5cc29942896c72e4ece69b13d
    Latest Commit (118 bytes):
      a4b3f2bbc8aba12c549c842fd052a9784da8150b3a859c78c45812bf7c9a0c72
    Timestamp (ostree.commit.timestamp): 2025-06-13T19:17:43+01

* ostree/container/blob/sha256_3A_bdd445e15c5c99bc332d1a55ea8a76c4a91fcde4656f4c2840de9394e2e036ab
    Latest Commit (86 bytes):
      aa77fbb1254ef8e5dd99920701dc14be7aed6a183e83359259dcb7e8f8015a58
    Timestamp (ostree.commit.timestamp): 1970-01-01T01:00:00+01

* ostree/container/blob/sha256_3A_c80444e8da1e8e4b2d9c965d071b7033f7a1a597bc3a0e67d14b20c75acbbef9
    Latest Commit (86 bytes):
      ef41ac21864f3fe05692db99021aaf716162b6f0e0533183d9ca61ab712e3834
    Timestamp (ostree.commit.timestamp): 1970-01-01T01:00:00+01

* ostree/container/blob/sha256_3A_cf9c329a7bff9266f822b7c9503664ba41a7d8cc6d432ee1f700c39428bd5c82
    Latest Commit (86 bytes):
      484d01762e1628aa0fd3ad762bac9651be5fdc533a06f648c184e322fe4ab781
    Timestamp (ostree.commit.timestamp): 1970-01-01T01:00:00+01

* ostree/container/blob/sha256_3A_d095d2380eacc65c26aecb6616b6511c30a8370d1f7bcec5a31045312e724e09
    Latest Commit (86 bytes):
      36a9155b2f5435de11deb0939a30e012835440ef854e5b2f2a2612661ad32f80
    Timestamp (ostree.commit.timestamp): 1970-01-01T01:00:00+01

* ostree/container/blob/sha256_3A_d0ee2006506f1d52dfe89d12f7e08609510a87cbd1ac4b9a63ad5a77e4d173e6
    Latest Commit (86 bytes):
      eca620f4d4bbe4a4581b1ee4896fb4ba9a61c0c8aa2eb16d6ecdc8085b5935c4
    Timestamp (ostree.commit.timestamp): 1970-01-01T01:00:00+01

* ostree/container/blob/sha256_3A_d26ef76e86766469a49d2cb0b432631362bfc92d64b1baf6b21021e06dc77b30
    Latest Commit (118 bytes):
      1936d607e88355a8952d0bd6b6a2cab13937c24206ba7a32b13f5234cdc0bec2
    Timestamp (ostree.commit.timestamp): 2025-06-13T19:17:42+01

* ostree/container/blob/sha256_3A_d2c3ed7371e3dd88071e049cd25acd206c32452c56c68f19a844f7b3e9cdb199
    Latest Commit (118 bytes):
      19ca577ec99ed5486ed07fafe5350ddf05da7e5f942114fc3e0947760d636f40
    Timestamp (ostree.commit.timestamp): 2025-06-13T19:17:46+01

* ostree/container/blob/sha256_3A_d3019f07d56012374c993b52ab86ca375583f18df64db9de3bdf1124fa1b78e2
    Latest Commit (86 bytes):
      20d27fec2c8b505da8474b5a953eb5754f3fffa8173e9fee8a52e81d83bbe44d
    Timestamp (ostree.commit.timestamp): 1970-01-01T01:00:00+01

* ostree/container/blob/sha256_3A_d3de8bd41786ca4bbee55903265e03672d22c09687c4aa542f1b5292b553457f
    Latest Commit (118 bytes):
      9d39bfd17184ee2ae77e704221822cc53b44c380c824ac50b9290703cb9a6395
    Timestamp (ostree.commit.timestamp): 2025-06-13T19:24:51+01

* ostree/container/blob/sha256_3A_da954960b83f1bac52d8966a25f1858b8502519b77e69f2d8936fdee8c862868
    Latest Commit (86 bytes):
      e29d144a5a5be3b2124de3019001581ca77fe32bfabf7f624fe5ae7be6a18a92
    Timestamp (ostree.commit.timestamp): 1970-01-01T01:00:00+01

* ostree/container/blob/sha256_3A_dcfc1a89e116c144c1181c814422efd92d2bb809a02749fcda1409e775cb857e
    Latest Commit (86 bytes):
      e8fcde276d23faf557c63e2449f2db21efda2733d747e4f7b3b956cd3601e62e
    Timestamp (ostree.commit.timestamp): 1970-01-01T01:00:00+01

* ostree/container/blob/sha256_3A_de79382b283be6736a610f81c6fbbf463e481da664a0af371d857ce1037f769d
    Latest Commit (86 bytes):
      4b1248f8f3ba20e41639edf0aa3ec5b4040086652af060543e7df842d631b9a6
    Timestamp (ostree.commit.timestamp): 1970-01-01T01:00:00+01

* ostree/container/blob/sha256_3A_e21aed3024e30a6b416efd94e5587b51d99460ca1fd88358e211497e4858cc65
    Latest Commit (118 bytes):
      f98d556e0a1d415b6a3de02f63f36be5f1e959ec2b8836be913078bd51d111cd
    Timestamp (ostree.commit.timestamp): 2025-06-13T19:17:44+01

* ostree/container/blob/sha256_3A_e718848b472aa2858700b4655d4a79c77b8d9d5dff0140021b037ae191e1ed1c
    Latest Commit (86 bytes):
      a9476d151276b233ad0d20d38cbb5864273606f71ac74eacdc74cd6a7717a89f
    Timestamp (ostree.commit.timestamp): 1970-01-01T01:00:00+01

* ostree/container/blob/sha256_3A_e834242c12ffa8b2e8960dc7856ee13cd23a23dc7e534e0229a8175be0e8e8b8
    Latest Commit (118 bytes):
      9354ce9aae86e7648e7dc3a212a8a52c81e2997df67c336ef26953f5483a37dc
    Timestamp (ostree.commit.timestamp): 2025-06-13T19:17:50+01

* ostree/container/blob/sha256_3A_ea63be1073b5fa3c5f6d2c39576b85199953c22b7b663ac1ab6f7ab9e16e18ef
    Latest Commit (86 bytes):
      34fb0011ee1c5ecb54d3fc59ad08bc7fcb3cbf2ebe6c666e974bc80c9b2c6fdd
    Timestamp (ostree.commit.timestamp): 1970-01-01T01:00:00+01

* ostree/container/blob/sha256_3A_ebdfea18c39b03ff1b726b83b4214fe8d0a8dde5ec47454f0ae0b07561217b62
    Latest Commit (86 bytes):
      34c161a65ce234b913d817f111af5e11a2c6e94f3c3cf48ec3f53e219135e2db
    Timestamp (ostree.commit.timestamp): 1970-01-01T01:00:00+01

* ostree/container/blob/sha256_3A_ec33ac690926410a934a79ad3d24c067fe37f0c35becf234ff0482156ba76587
    Latest Commit (118 bytes):
      45326d49f09826887455fdeadbdad015ebc0dfc8260292e9651116d7a55b870a
    Timestamp (ostree.commit.timestamp): 2025-06-13T19:17:47+01

* ostree/container/blob/sha256_3A_ecaa57980e2d981111859a4557a5f77e305ab0d6d3bf424952fa9eb545903ccb
    Latest Commit (86 bytes):
      408e968cbaaf11360775c2268b4f36ffd84e20105c59012055c51a432ee3e532
    Timestamp (ostree.commit.timestamp): 1970-01-01T01:00:00+01

* ostree/container/blob/sha256_3A_f4e337b33971149c8fbe688c3daf3adc4e06a982e46d627fa1963c45833109cd
    Latest Commit (118 bytes):
      bb5dedb893106d622e0fb96cecbabf380c5f6ef772cf05dea97b87db69860d6e
    Timestamp (ostree.commit.timestamp): 2025-06-13T19:16:54+01

* ostree/container/blob/sha256_3A_f51db0f8833d54173863a607dcbec4bec8357536b5c74bfec0dfcbc7dee61111
    Latest Commit (86 bytes):
      64ff451ec8b918a0733289b722206d6413a7e651433b5cb58710a5b9462de7ad
    Timestamp (ostree.commit.timestamp): 1970-01-01T01:00:00+01

* ostree/container/blob/sha256_3A_f543bc96340b6fdfac50e20c2b885b745055fa15fb155fb49dad4992eb4502a6
    Latest Commit (86 bytes):
      b1df7b7a22224539de2a43ed544258a7998df1ee7ae95800aeb3e64dfd4078ce
    Timestamp (ostree.commit.timestamp): 1970-01-01T01:00:00+01

* ostree/container/blob/sha256_3A_fa10023c68bb6d896ad33ddc803ee11854c2ee3cbfc86fa1fb9c091c0d331edb
    Latest Commit (86 bytes):
      b8d171098c2c90d5cc5ed3f78bfaa9040ceddd767dd3c732a0b71589e23f94aa
    Timestamp (ostree.commit.timestamp): 1970-01-01T01:00:00+01

* ostree/container/blob/sha256_3A_fa3050cba1c873174c8e02978dbbb1cee83de68cc352fd0ea9be806e29c1a945
    Latest Commit (86 bytes):
      fa5f55858dad32225b5c4720d5e36bd3d17aee82f2527c4eb08884718495bb3c
    Timestamp (ostree.commit.timestamp): 1970-01-01T01:00:00+01

* ostree/container/blob/sha256_3A_fc13c0de7a3c9629ac5a07c855387354e6d6aa01dda7b3c0520c17a38642c22d
    Latest Commit (86 bytes):
      8d4efb94a3db9dd1567b018fdf64118730290eee3c0e6f9adde009ac7d3965b8
    Timestamp (ostree.commit.timestamp): 1970-01-01T01:00:00+01

* ostree/container/blob/sha256_3A_ff89bfb07d324df88d1ade9e2899b56a3b3db61fefc2c91edf04e6107e67e13e
    Latest Commit (86 bytes):
      f629c131114261be20c24daa24223eee1ec8b57af7891e33bd6ca73996c2accd
    Timestamp (ostree.commit.timestamp): 1970-01-01T01:00:00+01

* ostree/container/image/docker_3A__2F__2F_quay_2E_io/rhn__support__arolivei/microshift-4_2E_18-bootc-embeeded_3A_v2
    Latest Commit (34.0 kB):
      1ee86936c0463da392589e3f491be3b99a5d4c6f158d17e845261f048196c5cd
    Timestamp (ostree.commit.timestamp): 2025-06-13T18:59:53+01

Repository Mode (ostree.summary.mode): bare
Last-Modified (ostree.summary.last-modified): 2025-06-13T19:50:26+01
Has Tombstone Commits (ostree.summary.tombstone-commits): No
ostree.summary.indexed-deltas: true
[root@rhel94-local repo]# 
~~~

tar.gz it and transfer to the target bootc system to get updated:
~~~
[root@rhel94-local ~]# tar zcvf repo.tar.gz repo/
repo/
repo/config
repo/tmp/
repo/tmp/cache/
repo/extensions/
repo/state/
repo/refs/
repo/refs/heads/
repo/refs/heads/ostree/
repo/refs/heads/ostree/container/
repo/refs/heads/ostree/container/blob/
repo/refs/heads/ostree/container/blob/sha256_3A_13dd1760bac04dd71abfc3984673ba4db8330a00d74a16d1681a643f7785957b
repo/refs/heads/ostree/container/blob/sha256_3A_18ab149f0f36fd9d5132410fa67e65e77b5b0f9b94e234b5d17af5bb0506e371
repo/refs/heads/ostree/container/blob/sha256_3A_242bd4b7d70ceb6c7890537ad517d2e9ad05fdab4e4279e3c8ed928bc1b56cdd
(..)
repo/objects/ff/ef63f5caee06e913877fd0bfadc8ca23d00d81b2881853f0c33731a20f576b.dirtree
repo/objects/ff/695360b1bff7695ead630a0307adfd9865eb1ea887bd8c5bfde7f6b4a07240.dirtree
repo/objects/ff/351d2e6c1a759264f5cce12db156af197fbe5c112dbb9c8d2346e39dc6886e.dirtree
repo/.lock
repo/summary

[root@rhel94-local ~]# scp repo.tar.gz redhat@192.168.111.198:/var/tmp/ostree-updates
redhat@192.168.111.198's password: 
repo.tar.gz                                                                                                                                100% 4069MB 543.7MB/s   00:07    
[root@rhel94-local ~]# 
~~~

Apply the OStree repo: 

~~~
[root@rhel94-local ~]# ssh redhat@192.168.111.198
redhat@192.168.111.198's password: 
Boot Status is GREEN - Health Check SUCCESS
Web console: https://localhost:9090/

Last login: Fri Jun 13 18:55:34 2025 from 192.168.111.152
[redhat@localhost ~]$ sudo -i
[sudo] password for redhat: 
[root@localhost ~]# journalctl -f -u rpm-ostreed.service
Jun 13 18:54:20 localhost.localdomain rpm-ostree[1296]: Reading config file '/etc/rpm-ostreed.conf'
Jun 13 18:54:20 localhost.localdomain systemd[1]: Started rpm-ostree System Management Daemon.
Jun 13 18:54:20 localhost.localdomain rpm-ostree[1296]: In idle state; will auto-exit in 64 seconds
Jun 13 18:54:20 localhost.localdomain rpm-ostree[1296]: client(id:cli dbus:1.12 unit:microshift.service uid:0) added; new total=1
Jun 13 18:54:20 localhost.localdomain rpm-ostree[1296]: client(id:cli dbus:1.12 unit:microshift.service uid:0) vanished; remaining=0
Jun 13 18:54:20 localhost.localdomain rpm-ostree[1296]: In idle state; will auto-exit in 62 seconds
Jun 13 18:54:20 localhost.localdomain rpm-ostree[1296]: client(id:cli dbus:1.13 unit:microshift.service uid:0) added; new total=1
Jun 13 18:54:20 localhost.localdomain rpm-ostree[1296]: client(id:cli dbus:1.13 unit:microshift.service uid:0) vanished; remaining=0
Jun 13 18:54:20 localhost.localdomain rpm-ostree[1296]: In idle state; will auto-exit in 64 seconds
Jun 13 18:55:24 localhost.localdomain systemd[1]: rpm-ostreed.service: Deactivated successfully.
q^C
[root@localhost ~]# cd /var/tmp/ostree-updates/
[root@localhost ostree-updates]# tar xf repo.tar.gz 
[root@localhost ostree-updates]# rpm-ostree upgrade --check
error: Creating importer: Failed to invoke skopeo proxy method OpenImage: remote error: pinging container registry localhost: Get "https://localhost/v2/": dial tcp [::1]:443: connect: connection refused
[root@localhost ostree-updates]# rpm-ostree status
State: idle
Deployments:
● ostree-unverified-registry:localhost/microshift-4.18-bootc-embedded
                   Digest: sha256:8b770ff5b62b73902b0fcc82dfac00312f4b84dc8c54f30482632daebc6841a3
                  Version: 9.20250429.0 (2025-06-04T22:08:08Z)
[root@localhost ostree-updates]# rpm-ostree status -v
State: idle
AutomaticUpdates: disabled
Deployments:
● ostree-unverified-registry:localhost/microshift-4.18-bootc-embedded (index: 0)
                   Digest: sha256:8b770ff5b62b73902b0fcc82dfac00312f4b84dc8c54f30482632daebc6841a3
                  Version: 9.20250429.0 (2025-06-04T22:08:08Z)
                   Commit: 0351d3dfa326d2758d408cfc6a423b3212be02941f50e3adabe1dae01fd51a6d
                   Staged: no
                StateRoot: default
[root@localhost ostree-updates]# 

[root@localhost ostree-updates]# ostree remote add local /var/tmp/ostree-updates/repo
[root@localhost ostree-updates]# cat /etc/ostree/remotes.d/local.conf
[remote "local"]
url=/var/tmp/ostree-updates/repo
[root@localhost ostree-updates]# 


~~~