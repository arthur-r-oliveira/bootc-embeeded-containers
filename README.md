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
[root@localhost ~]# podman login quay.io
Username: rhn_support_arolivei
Password: 
Login Succeeded!
[root@localhost ~]# cat /etc/redhat-release 
Red Hat Enterprise Linux release 9.4 (Plow)
[root@localhost ~]# bootc status
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
      version: 9.20241019.0
      timestamp: null
      imageDigest: sha256:50bf08f2971ec1022ab83fd74e9f38124afde18cea6f83c3d3a559c74ffb2715
    cachedUpdate: null
    incompatible: false
    pinned: false
    store: ostreeContainer
    ostree:
      checksum: 52f3dc10f6f84da017b5620450f1126cc0c811738b427368495d9de5b8bd65da
      deploySerial: 0
  rollback: null
  rollbackQueued: false
  type: bootcHost
[root@localhost wordpress]# oc get pods -A
NAMESPACE                  NAME                                       READY   STATUS    RESTARTS      AGE
kube-system                csi-snapshot-controller-79f48cb65c-qst8w   1/1     Running   0             21h
openshift-dns              dns-default-pqfnn                          2/2     Running   0             21h
openshift-dns              node-resolver-r9bhc                        1/1     Running   0             21h
openshift-ingress          router-default-5c6b6bf9cb-gzrcs            1/1     Running   0             21h
openshift-ovn-kubernetes   ovnkube-master-5wrgx                       4/4     Running   1 (21h ago)   21h
openshift-ovn-kubernetes   ovnkube-node-d2wjp                         1/1     Running   1 (21h ago)   21h
openshift-service-ca       service-ca-7674ff74cb-k8sw8                1/1     Running   0             21h
openshift-storage          lvms-operator-d6f9c9d4-77wj4               1/1     Running   0             21h
openshift-storage          vg-manager-gnpbd                           1/1     Running   0             21h
[root@localhost wordpress]# oc apply -k .
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
[root@localhost wordpress]# oc get pods -A
NAMESPACE                  NAME                                       READY   STATUS              RESTARTS      AGE
example-apps-wordpress     wordpress-ff94c8dcf-khvg9                  0/1     ContainerCreating   0             4s
example-apps-wordpress     wordpress-mysql-84dd895d65-6ms65           0/1     ContainerCreating   0             4s
kube-system                csi-snapshot-controller-79f48cb65c-qst8w   1/1     Running             0             21h
openshift-dns              dns-default-pqfnn                          2/2     Running             0             21h
openshift-dns              node-resolver-r9bhc                        1/1     Running             0             21h
openshift-ingress          router-default-5c6b6bf9cb-gzrcs            1/1     Running             0             21h
openshift-ovn-kubernetes   ovnkube-master-5wrgx                       4/4     Running             1 (21h ago)   21h
openshift-ovn-kubernetes   ovnkube-node-d2wjp                         1/1     Running             1 (21h ago)   21h
openshift-service-ca       service-ca-7674ff74cb-k8sw8                1/1     Running             0             21h
openshift-storage          lvms-operator-d6f9c9d4-77wj4               1/1     Running             0             21h
openshift-storage          vg-manager-gnpbd                           1/1     Running             0             21h
[root@localhost wordpress]# oc get pods -A
NAMESPACE                  NAME                                       READY   STATUS             RESTARTS      AGE
example-apps-wordpress     wordpress-ff94c8dcf-khvg9                  1/1     Running            0             6s
example-apps-wordpress     wordpress-mysql-84dd895d65-6ms65           0/1     ImagePullBackOff   0             6s
kube-system                csi-snapshot-controller-79f48cb65c-qst8w   1/1     Running            0             21h
openshift-dns              dns-default-pqfnn                          2/2     Running            0             21h
openshift-dns              node-resolver-r9bhc                        1/1     Running            0             21h
openshift-ingress          router-default-5c6b6bf9cb-gzrcs            1/1     Running            0             21h
openshift-ovn-kubernetes   ovnkube-master-5wrgx                       4/4     Running            1 (21h ago)   21h
openshift-ovn-kubernetes   ovnkube-node-d2wjp                         1/1     Running            1 (21h ago)   21h
openshift-service-ca       service-ca-7674ff74cb-k8sw8                1/1     Running            0             21h
openshift-storage          lvms-operator-d6f9c9d4-77wj4               1/1     Running            0             21h
openshift-storage          vg-manager-gnpbd                           1/1     Running            0             21h
[root@localhost wordpress]# oc get pods -A
NAMESPACE                  NAME                                       READY   STATUS             RESTARTS      AGE
example-apps-wordpress     wordpress-ff94c8dcf-khvg9                  1/1     Running            0             7s
example-apps-wordpress     wordpress-mysql-84dd895d65-6ms65           0/1     ImagePullBackOff   0             7s
kube-system                csi-snapshot-controller-79f48cb65c-qst8w   1/1     Running            0             21h
openshift-dns              dns-default-pqfnn                          2/2     Running            0             21h
openshift-dns              node-resolver-r9bhc                        1/1     Running            0             21h
openshift-ingress          router-default-5c6b6bf9cb-gzrcs            1/1     Running            0             21h
openshift-ovn-kubernetes   ovnkube-master-5wrgx                       4/4     Running            1 (21h ago)   21h
openshift-ovn-kubernetes   ovnkube-node-d2wjp                         1/1     Running            1 (21h ago)   21h
openshift-service-ca       service-ca-7674ff74cb-k8sw8                1/1     Running            0             21h
openshift-storage          lvms-operator-d6f9c9d4-77wj4               1/1     Running            0             21h
openshift-storage          vg-manager-gnpbd                           1/1     Running            0             21h
[root@localhost wordpress]# 

[root@localhost wordpress]# crictl images
IMAGE                                            TAG                 IMAGE ID            SIZE
docker.io/library/wordpress                      6.2.1-apache        b8ee07adfa917       629MB
quay.io/openshift-release-dev/ocp-v4.0-art-dev   <none>              d9fb51bc34340       462MB
quay.io/openshift-release-dev/ocp-v4.0-art-dev   <none>              d5f9bd9ceaa33       490MB
quay.io/openshift-release-dev/ocp-v4.0-art-dev   <none>              86a73a727e4f0       492MB
quay.io/openshift-release-dev/ocp-v4.0-art-dev   <none>              03ec3ae43b5e7       579MB
quay.io/openshift-release-dev/ocp-v4.0-art-dev   <none>              243083e135a20       481MB
quay.io/openshift-release-dev/ocp-v4.0-art-dev   <none>              3936b2921a18f       657MB
quay.io/openshift-release-dev/ocp-v4.0-art-dev   <none>              876a1efeb9a93       393MB
quay.io/openshift-release-dev/ocp-v4.0-art-dev   <none>              27f3bf3a2d3da       460MB
registry.redhat.io/lvms4/lvms-rhel9-operator     <none>              2b91596262502       218MB



[root@localhost ~]# mkdir /var/tmp/bootc-upgrade
[root@localhost ~]# skopeo copy docker://quay.io/rhn_support_arolivei/microshift-4.18-bootc:v2 dir://var/tmp/bootc-upgrade
Getting image source signatures
Copying blob 999c0822dc1d done   | 
Copying blob 999c0822dc1d done   | 
Copying blob 8bfc0e089ba9 done   | 
Copying blob 8bfc0e089ba9 done   | 
Copying blob 8bfc0e089ba9 done   | 
Copying blob 73299d564c44 [========>-----------------------------] 90.3MiB / 387.8MiB | 577.5 KiB/s

[root@localhost ~]# bootc switch --transport dir /var/tmp/bootc-upgrade/
layers already present: 67; layers needed: 11 (3.1 GB)
Fetched layers: 2.90 GiB in 41 seconds (72.80 MiB/s)
Pruned images: 1 (layers: 0, objsize: 0 bytes)
Queued for next boot: ostree-unverified-image:dir:/var/tmp/bootc-upgrade/
  Version: 9.20241019.0
  Digest: sha256:e75e8c447546b8c5c4fffaccb2e5f4e870559747d688335c91b68d08bdaba5c4
[root@localhost ~]# 

[root@localhost ~]# bootc status
apiVersion: org.containers.bootc/v1alpha1
kind: BootcHost
metadata:
  name: host
spec:
  image:
    image: /var/tmp/bootc-upgrade/
    transport: dir
  bootOrder: default
status:
  staged:
    image:
      image:
        image: /var/tmp/bootc-upgrade/
        transport: dir
      version: 9.20241019.0

[root@localhost ~]# rpm-ostree status
State: idle
Deployments:
  ostree-unverified-image:dir:/var/tmp/bootc-upgrade/
                   Digest: sha256:e75e8c447546b8c5c4fffaccb2e5f4e870559747d688335c91b68d08bdaba5c4
                  Version: 9.20241019.0 (2025-04-01T17:34:20Z)
                     Diff: 239 upgraded, 11 added

● ostree-unverified-registry:localhost/microshift-4.18-bootc-embedded
                   Digest: sha256:50bf08f2971ec1022ab83fd74e9f38124afde18cea6f83c3d3a559c74ffb2715
                  Version: 9.20241019.0 (2025-04-01T16:27:15Z)
[root@localhost ~]# 

[root@localhost ~]# bootc upgrade --apply
No changes in ostree-unverified-image:dir:/var/tmp/bootc-upgrade/ => sha256:e75e8c447546b8c5c4fffaccb2e5f4e870559747d688335c91b68d08bdaba5c4
Staged update present, not changed.
Rebooting system

[root@localhost ~]# bootc status
No staged image present
Current booted image: dir:/var/tmp/bootc-upgrade/
    Image version: 9.20241019.0 (2025-04-01 17:34:20.447641674 UTC)
    Image digest: sha256:e75e8c447546b8c5c4fffaccb2e5f4e870559747d688335c91b68d08bdaba5c4
Current rollback image: localhost/microshift-4.18-bootc-embedded
    Image version: 9.20241019.0 (2025-04-01 16:27:15.294366008 UTC)
    Image digest: sha256:50bf08f2971ec1022ab83fd74e9f38124afde18cea6f83c3d3a559c74ffb2715
[root@localhost ~]# rpm-ostree status
State: idle
Deployments:
● ostree-unverified-image:dir:/var/tmp/bootc-upgrade/
                   Digest: sha256:e75e8c447546b8c5c4fffaccb2e5f4e870559747d688335c91b68d08bdaba5c4
                  Version: 9.20241019.0 (2025-04-01T17:34:20Z)

  ostree-unverified-registry:localhost/microshift-4.18-bootc-embedded
                   Digest: sha256:50bf08f2971ec1022ab83fd74e9f38124afde18cea6f83c3d3a559c74ffb2715
                  Version: 9.20241019.0 (2025-04-01T16:27:15Z)
[root@localhost ~]# 


[root@localhost ~]# podman images
REPOSITORY                                                                   TAG           IMAGE ID      CREATED        SIZE
quay.io/openshift-release-dev/ocp-v4.0-art-dev                               <none>        86a73a727e4f  4 weeks ago    492 MB
quay.io/openshift-release-dev/ocp-v4.0-art-dev                               <none>        03ec3ae43b5e  4 weeks ago    579 MB
quay.io/openshift-release-dev/ocp-v4.0-art-dev                               <none>        3936b2921a18  5 weeks ago    657 MB
quay.io/openshift-release-dev/ocp-v4.0-art-dev                               <none>        243083e135a2  5 weeks ago    481 MB
quay.io/openshift-release-dev/ocp-v4.0-art-dev                               <none>        d5f9bd9ceaa3  5 weeks ago    490 MB
quay.io/openshift-release-dev/ocp-v4.0-art-dev                               <none>        70c4abc55055  5 weeks ago    439 MB
quay.io/openshift-release-dev/ocp-v4.0-art-dev                               <none>        fb7536807420  5 weeks ago    466 MB
quay.io/openshift-release-dev/ocp-v4.0-art-dev                               <none>        69488e7d6948  5 weeks ago    857 MB
quay.io/openshift-release-dev/ocp-v4.0-art-dev                               <none>        27f3bf3a2d3d  5 weeks ago    460 MB
quay.io/openshift-release-dev/ocp-v4.0-art-dev                               <none>        876a1efeb9a9  5 weeks ago    393 MB
quay.io/openshift-release-dev/ocp-v4.0-art-dev                               <none>        d9fb51bc3434  5 weeks ago    462 MB
docker.io/library/mysql                                                      8.0           1c83f38450c3  2 months ago   781 MB
registry.redhat.io/lvms4/lvms-rhel9-operator                                 <none>        2b9159626250  6 months ago   218 MB
registry.redhat.io/openshift-service-mesh-tech-preview/istio-pilot-rhel9     <none>        f740c90dc321  6 months ago   291 MB
registry.redhat.io/openshift-service-mesh-tech-preview/istio-rhel9-operator  <none>        2b7be54340b4  6 months ago   155 MB
registry.redhat.io/openshift4/ose-kube-rbac-proxy                            <none>        7e66f8a4c420  19 months ago  456 MB
docker.io/library/wordpress                                                  6.2.1-apache  b8ee07adfa91  22 months ago  629 MB
[root@localhost ~]# crictl images
IMAGE                                                                         TAG                 IMAGE ID            SIZE
docker.io/library/mysql                                                       8.0                 1c83f38450c37       781MB
docker.io/library/wordpress                                                   6.2.1-apache        b8ee07adfa917       629MB
quay.io/openshift-release-dev/ocp-v4.0-art-dev                                <none>              d9fb51bc34340       462MB
quay.io/openshift-release-dev/ocp-v4.0-art-dev                                <none>              d5f9bd9ceaa33       490MB
quay.io/openshift-release-dev/ocp-v4.0-art-dev                                <none>              86a73a727e4f0       492MB
quay.io/openshift-release-dev/ocp-v4.0-art-dev                                <none>              03ec3ae43b5e7       579MB
quay.io/openshift-release-dev/ocp-v4.0-art-dev                                <none>              69488e7d69489       857MB
quay.io/openshift-release-dev/ocp-v4.0-art-dev                                <none>              243083e135a20       481MB
quay.io/openshift-release-dev/ocp-v4.0-art-dev                                <none>              3936b2921a18f       657MB
quay.io/openshift-release-dev/ocp-v4.0-art-dev                                <none>              70c4abc55055c       439MB
quay.io/openshift-release-dev/ocp-v4.0-art-dev                                <none>              fb7536807420b       466MB
quay.io/openshift-release-dev/ocp-v4.0-art-dev                                <none>              876a1efeb9a93       393MB
quay.io/openshift-release-dev/ocp-v4.0-art-dev                                <none>              27f3bf3a2d3da       460MB
registry.redhat.io/lvms4/lvms-rhel9-operator                                  <none>              2b91596262502       218MB
registry.redhat.io/openshift-service-mesh-tech-preview/istio-pilot-rhel9      <none>              f740c90dc3217       291MB
registry.redhat.io/openshift-service-mesh-tech-preview/istio-rhel9-operator   <none>              2b7be54340b4c       155MB
registry.redhat.io/openshift4/ose-kube-rbac-proxy                             <none>              7e66f8a4c4202       456MB
[root@localhost ~]# 

~~~
