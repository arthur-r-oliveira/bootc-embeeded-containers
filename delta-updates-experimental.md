# Procedures to extract OSTree commits from bootc image (OCI) available
About extracting OSTree commits from OCI https://github.com/coreos/rpm-ostree/blob/main/docs/container.md#mapping-container-images-back-to-ostree

About OSTree delta updates, see references at: 
- https://ostreedev.github.io/ostree/copying-deltas/#static-deltas-for-offline-updates
- https://sigs.centos.org/automotive/building/creating_static_deltas/#making-offline-updates
-  https://docs.redhat.com/en/documentation/red_hat_enterprise_linux/9/html/composing_installing_and_managing_rhel_for_edge_images/creating-and-managing-ostree-image-updates_composing-installing-managing-rhel-for-edge-images#performing-updates-by-using-static-deltas_creating-and-managing-ostree-image-updates

## Setup 
Let's assume that you have two bootc (OCI) images, a v1 with the initial state of your system and a v2 with the OS updated and additional container images embeeed to it: 

~~~
[root@rhel94-local ~]# podman images|grep microshift-4.18-bootc-embeeded
localhost/microshift-4.18-bootc-embeeded       v2              797afe15262d  5 days ago     10.7 GB
localhost/microshift-4.18-bootc-embeeded       v1              894052d64cc8  5 days ago     5.76 GB
[root@rhel94-local ~]# 
~~~

## Extracting OSTree Commits

Init two new ostree repos, one for each version of your OCIs

~~~
[root@rhel94-local ~]# ostree --repo=repo1 init
[root@rhel94-local ~]# ostree --repo=repo2 init
~~~

Then extract the OSTree commits from OCI into each repo, v1 to repo1 and v2 to repo2

If you have the updated OCI image in some registry, you can pull it with `ostree container pull` and `ostree-unverified-registry`
See more at https://github.com/coreos/rpm-ostree/blob/main/docs/container.md#url-format-for-ostree-native-containers

~~~
[root@rhel94-local ~]# podman images|grep microshift
localhost:5000/microshift-4.18-bootc-embeeded  v2              797afe15262d  5 days ago     10.7 GB
localhost/microshift-4.18-bootc-embeeded       v2              797afe15262d  5 days ago     10.7 GB
localhost/microshift-4.18-bootc-embeeded       v1              894052d64cc8  5 days ago     5.76 GB
localhost/microshift-4.18-bootc                latest          484398421db2  5 days ago     2.37 GB
[root@rhel94-local ~]# 
~~~

ostree-unverified-registry: 
~~~
[root@rhel94-local ~]# ostree container image pull --insecure-skip-tls-verification /root/repo1 ostree-unverified-registry:localhost:5000/microshift-4.18-bootc-embeeded:v1
layers already present: 0; layers needed: 90 (8.9 GB)
 274 B [████████████████████] (0s) Fetched layer sha256:b924d56fae13                                                                                                                                               Image contains non-ostree compatible file paths: tmp: 2 run: 7
Wrote: ostree-unverified-registry:localhost:5000/microshift-4.18-bootc-embeeded:v2 => 706dabbe7a480cf6d65ed6f9829e44a1d354709ec0c5e98990b0e4d6a4664918
[root@rhel94-local ~]# 
~~~

Or you can pull from your local container storage with ostree-unverified-image:containers-storage:
~~~
[root@rhel94-local ~]# ostree container image pull --insecure-skip-tls-verification /root/repo2 ostree-unverified-image:containers-storage:localhost/microshift-4.18-bootc-embeeded:v2
layers already present: 0; layers needed: 90 (10.7 GB)
 4.00 KiB [████████████████████] (0s) Fetched layer sha256:d9721dcd6b2a                                                                                                                                            Image contains non-ostree compatible file paths: tmp: 2 run: 7
Wrote: ostree-unverified-image:containers-storage:localhost/microshift-4.18-bootc-embeeded:v2 => fd0b22924747724043aa4817782b6c6ac3fdbbc81b9617a994304924ded7ca03
[root@rhel94-local ~]# 

~~~

## Check the content of OSTree repos vs Live

Check the content of the repos and note that OCI v2 have additional commits: 

~~~
[root@rhel94-local ~]# ostree --repo=/root/repo1 summary -u
[root@rhel94-local ~]# ostree --repo=/root/repo2 summary -u

[root@rhel94-local ~]# ostree --repo=/root/repo1 summary -v|grep container|wc -l
OT: using fuse: 0
80
[root@rhel94-local ~]# ostree --repo=/root/repo2 summary -v|grep container|wc -l
OT: using fuse: 0
89
~~~

If you check a live system still running the original OCI (v1), you are going to find the same amount of commits: 

~~~
[root@localhost ~]# rpm-ostree status
State: idle
Deployments:
● ostree-unverified-registry:localhost/microshift-4.18-bootc-embedded
                   Digest: sha256:94b7cddbeddbc429cbe32390dcd92ac47c11c81e8bd5f5ad3740145e161784ba
                  Version: 9.20250429.0 (2025-05-14T15:53:06Z)
[root@localhost ~]# bootc status|grep -i image
  image:
    image: localhost/microshift-4.18-bootc-embedded
    image:
      image:
        image: localhost/microshift-4.18-bootc-embedded
      imageDigest: sha256:94b7cddbeddbc429cbe32390dcd92ac47c11c81e8bd5f5ad3740145e161784ba
[root@localhost ~]# 
[root@localhost ~]# ostree --repo=/sysroot/ostree/repo summary -v|grep container|wc -l
OT: using fuse: 0
OT: using fuse: 0
80
~~~


## Diff of OSTree commits from V1 to V2 

Check the references on both repos and diff: 

~~~
[root@rhel94-local ~]#  ostree --repo=/root/repo1 refs > ref1
[root@rhel94-local ~]#  ostree --repo=/root/repo2 refs > ref2
(failed reverse-i-search)`diff': mk^Cr repo
(reverse-i-search)`': ^C
[root@rhel94-local ~]# diff ref1 ref2
0a1
> exampleos/x86_64/v1
15a17
> ostree/container/blob/sha256_3A_2f17387e78ec4547ac01575b54bf94bb17a08eb06e5b1c197e3461c04213ade4
17a20
> ostree/container/blob/sha256_3A_31eb84f17005248731407679150ef705c99a9e1b1184f6c9c1436e12784af963
21a25
> ostree/container/blob/sha256_3A_3e40da00e20a664a53c46dc97e4eaf05d2afa7aea48e48e144f0342a030960e2
35a40
> ostree/container/blob/sha256_3A_63df15081d5815de4f587251d91363a189bc7277a42ebeab864be9af4ce5b9b2
40a46
> ostree/container/blob/sha256_3A_74f5fc42d6e30046ae9988acef45ed8ff521083973abe5d961de1ce6de27a504
51a58
> ostree/container/blob/sha256_3A_975136cca72b74c3fbcfbb0a202ca41e49aa363ddc275375ff92fee2c4221359
54a62
> ostree/container/blob/sha256_3A_ad9bb9ba8090f280e4729e0d57df2619fcdd8cb03cc93df5c876c9ab436876cb
70a79
> ostree/container/blob/sha256_3A_d9721dcd6b2ad36a1b11127a7fb8fbea887411a64abfec8f365af8cb9ce69c80
79a89
> ostree/container/blob/sha256_3A_f6bbf4fa7a7d4c6a633b20ee7b447ebd31d2ea005c7706ad3008a002ee44b317
81c91
< ostree/container/image/containers-storage_3A_localhost/microshift-4_2E_18-bootc-embeeded_3A_v1
---
> ostree/container/image/containers-storage_3A_localhost/microshift-4_2E_18-bootc-embeeded_3A_v2
~~~

## creating the static deltas 

Then, work on creating the static deltas 
https://ostreedev.github.io/ostree/copying-deltas/#static-deltas-for-offline-updates 
https://docs.redhat.com/en/documentation/red_hat_enterprise_linux/9/html/composing_installing_and_managing_rhel_for_edge_images/creating-and-managing-ostree-image-updates_composing-installing-managing-rhel-for-edge-images#performing-updates-by-using-static-deltas_creating-and-managing-ostree-image-updates

Note: "from" first Reference and "to" the last reference in the list above: 

~~~
[[root@rhel94-local ~]# ostree --min-fallback-size=0 --repo=repo2 static-delta generate --from=ostree/container/blob/sha256_3A_2f17387e78ec4547ac01575b54bf94bb17a08eb06e5b1c197e3461c04213ade4 --to=ostree/container/image/containers-storage_3A_localhost/microshift-4_2E_18-bootc-embeeded_3A_v2 --filename=delta-update-file
Generating static delta:
  From: f6042a07dea41120abeeb2b6aca534a3caf1ebbb7e7d5430aa5334838ddee7f0
  To:   946b882ce81d8a8ffcd617b0de4905dbeac13568d4514d0cf08206d6fcb1f862
modified: 0
new reachable: metadata=5218 content regular=35388 symlink=4668
rollsum for 0/0 modified
(..)
part 37 n:699 compressed:17790501 uncompressed:31900908
part 38 n:947 compressed:22263817 uncompressed:31968009
part 39 n:914 compressed:15020513 uncompressed:30655857
part 40 n:556 compressed:13954749 uncompressed:30914503
part 41 n:4827 compressed:2377353 uncompressed:4729924
uncompressed=1263733379 compressed=683361637 loose=1263906155
rollsum=0 objects, 0 bytes
bsdiff=0 objects
[root@rhel94-local ~]# 
[root@rhel94-local ~]#  ostree --repo=repo2 summary -u
[root@rhel94-local ~]#  ostree --repo=repo2 summary -v|tail -10
OT: using fuse: 0
* ostree/container/image/containers-storage_3A_localhost/microshift-4_2E_18-bootc-embeeded_3A_v2
    Latest Commit (37.5 kB):
      946b882ce81d8a8ffcd617b0de4905dbeac13568d4514d0cf08206d6fcb1f862
    Timestamp (ostree.commit.timestamp): 2025-05-14T17:36:11+01

Repository Mode (ostree.summary.mode): bare
Last-Modified (ostree.summary.last-modified): 2025-05-20T18:16:04+01
Has Tombstone Commits (ostree.summary.tombstone-commits): No
Static Deltas (ostree.static-deltas): {'f6042a07dea41120abeeb2b6aca534a3caf1ebbb7e7d5430aa5334838ddee7f0-946b882ce81d8a8ffcd617b0de4905dbeac13568d4514d0cf08206d6fcb1f862': <[byte 0x92, 0x07, 0x7c, 0x56, 0x11, 0xd4, 0x96, 0x15, 0x49, 0xde, 0x10, 0xab, 0xe0, 0xc7, 0xfa, 0x02, 0xf2, 0xd9, 0x3b, 0x2d, 0xef, 0x94, 0x46, 0x9c, 0x20, 0x88, 0x24, 0x96, 0xdc, 0x4a, 0x51, 0x49]>}
ostree.summary.indexed-deltas: true
[root@rhel94-local ~]# 

[root@rhel94-local ~]#  ostree --repo=repo2 static-delta list
f6042a07dea41120abeeb2b6aca534a3caf1ebbb7e7d5430aa5334838ddee7f0-946b882ce81d8a8ffcd617b0de4905dbeac13568d4514d0cf08206d6fcb1f862
[root@rhel94-local ~]# 

[root@rhel94-local ~]# du -sm delta-update/
3911	delta-update/
[root@rhel94-local ~]# ls delta-update/
0    102  107  111  116  120  125  13   134  139  143  148  152  157  161  166  170  175  20  25  3   34  39  43  48  52  57  61  66  70  75  8   84  89  93  98
1    103  108  112  117  121  126  130  135  14   144  149  153  158  162  167  171  176  21  26  30  35  4   44  49  53  58  62  67  71  76  80  85  9   94  99
10   104  109  113  118  122  127  131  136  140  145  15   154  159  163  168  172  18   22  27  31  36  40  45  5   54  59  63  68  72  77  81  86  90  95  delta-update-file
100  105  11   114  119  123  128  132  137  141  146  150  155  16   164  169  173  19   23  28  32  37  41  46  50  55  6   64  69  73  78  82  87  91  96
101  106  110  115  12   124  129  133  138  142  147  151  156  160  165  17   174  2    24  29  33  38  42  47  51  56  60  65  7   74  79  83  88  92  97
[root@rhel94-local ~]# 

~~~

Create a new local repo `repo-deltas` on `archive` mode and pull the content from previous repo: 

~~~
[root@rhel94-local ~]# ostree --repo=repo-deltas init --mode=archive
[root@rhel94-local ~]# 

[root@rhel94-local ~]# ostree --repo=/root/repo pull-local repo-deltas
0 metadata, 0 content objects imported; 0 bytes content written                                                                                                                                                    
[root@rhel94-local ~]# 
~~~

Pull the content from repo2: 

~~~
[root@rhel94-local ~]#  ostree --repo=repo-deltas pull-local repo2 ostree/container/image/containers-storage_3A_localhost/microshift-4_2E_18-bootc-embeeded_3A_v2
5221 metadata, 40057 content objects imported; 5.8 GB content written                                                                                                                                              
[root@rhel94-local ~]# 
[root@rhel94-local ~]# du -sm repo2/ repo-deltas/
6612	repo2/
4255	repo-deltas/
~~~

Transfer repo-deltas to the target system: 

~~~
[root@localhost ~]# scp -r 192.168.111.152:/root/repo-deltas/ /var/ostree/updates

[root@localhost updates]# scp -r 192.168.111.152:/root/delta-update/ /var/ostree/updates

~~~


~~~
[root@localhost updates]# ostree static-delta apply-offline  /var/ostree/updates/delta-update/delta-update-file
error: Commit f6042a07dea41120abeeb2b6aca534a3caf1ebbb7e7d5430aa5334838ddee7f0, which is the delta source, is not in repository
~~~
