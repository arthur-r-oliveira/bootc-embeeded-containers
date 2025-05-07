

## Building Appliances for self-contained and disconnected environments with RHEL Image Mode (bootc)

[About image mode for Red Hat Enterprise Linux (RHEL)](https://docs.redhat.com/en/documentation/red_hat_build_of_microshift/4.18/html-single/installing_with_rhel_image_mode/index#microshift-bootc-conc_microshift-about-rhel-image-mode): _Image mode for Red Hat Enterprise Linux (RHEL) is a Technology Preview deployment method that uses a container-native approach to build, deploy, and manage the operating system as a bootc image. By using bootc, you can build, deploy, and manage the operating system as if it is any other container._

## Embedding Containers & Physically-bound images: ship it with the bootc image
[Some use cases require the entire boot image to be fully self contained. That means that everything needed to execute the workloads is shipped with the bootc image, including container images of the application containers and Quadlets. Such images are also referred to as “physically-bound images”.](https://docs.fedoraproject.org/en-US/bootc/embedding-containers/#_physically_bound_images_ship_it_with_the_bootc_image)

### General instructions: 
- Get started within MicroShift and image-mode (bootc) first https://docs.redhat.com/en/documentation/red_hat_build_of_microshift/4.18/html-single/installing_with_rhel_image_mode/index
- Then, embeed MicroShift and Application Container Images for offline deployments based on this:
  -  PR https://github.com/openshift/microshift/pull/4739 
  - https://github.com/ggiguash/microshift/blob/bootc-embedded-image-upgrade-418/docs/contributor/image_mode.md#appendix-b-embedding-container-images-in-bootc-builds 
  - https://gitlab.com/fedora/bootc/examples/-/tree/main/physically-bound-images

#### Step by step 
- Download your redhat pull secrets from https://console.redhat.com/openshift/downloads#tool-pull-secret and place as local file `.pull-secret.json`.

- Based on these [procedures](https://github.com/ggiguash/microshift/blob/bootc-embedded-image-upgrade-418/docs/contributor/image_mode.md#build-microshift-bootc-image), build the base microshift-bootc image.
  - `bash -x build-base.sh`

- Based on these [procedures]https://github.com/ggiguash/microshift/blob/bootc-embedded-image-upgrade-418/docs/contributor/image_mode.md#appendix-b-embedding-container-images-in-bootc-builds), using microshift-bootc image built in previous step, embeed the Container Images to your new microshift-bootc-embeed image:
  - `bash -x build.sh v1. 
    - That will include the MicroShift payload + an sample wordpress Container image to the bootc image.
    - Also produces a ISO image, to be used to install RHDE. 
- Within your test environment, [create a isolated network](https://github.com/openshift/microshift/blob/main/docs/contributor/image_mode.md#configure-isolated-network).
- Create a test VM with `create-vm.sh`.
- Access VM with user `redhat` and set [kubeconfig access to microshift](https://docs.redhat.com/en/documentation/red_hat_build_of_microshift/4.18/html/configuring/microshift-kubeconfig#accessing-microshift-cluster-locally_microshift-kubeconfig)
- Build the second image with `bash -x build.sh v2`.
  - That will include RHEL updates + a sample mysql Container image to bootc image tagged as V2.
  - Also produces a ISO image.
- Upgrade live system to v2. 
  - https://docs.fedoraproject.org/en-US/bootc/disconnected-updates/ 

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