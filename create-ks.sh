AUTH_CONFIG=.quay-auth.json
PULL_SECRET=.pull-secret.json
IMAGE_REF="quay.io/rhn_support_arolivei/microshift-4.18-bootc:v1"
cat > kickstart.ks <<EOFKS
lang en_US.UTF-8
keyboard us
timezone UTC
text
reboot

Partition the disk with hardware-specific boot and swap partitions, adding an
LVM volume that contains a 10GB+ system root. The remainder of the volume will
be used by the CSI driver for storing data.
zerombr
clearpart --all --initlabel
Create boot and swap partitions as required by the current hardware platform
reqpart --add-boot
Add an LVM volume group and allocate a system root logical volume
part pv.01 --grow
volgroup rhel pv.01
logvol / --vgname=rhel --fstype=xfs --size=10240 --name=root

Lock root user account
rootpw --lock

Configure network to use DHCP and activate on boot
network --bootproto=dhcp --device=link --activate --onboot=on

%pre-install --log=/dev/console --erroronfail

Create a 'bootc' image registry authentication file
mkdir -p /etc/ostree
cat > /etc/ostree/auth.json <<'EOF'
$(cat "${AUTH_CONFIG}")
EOF

%end

Pull a 'bootc' image from a remote registry
ostreecontainer --url "${IMAGE_REF}"

%post --log=/dev/console --erroronfail

Create an OpenShift pull secret file
cat > /etc/crio/openshift-pull-secret <<'EOF'
$(cat "${PULL_SECRET}")
EOF
chmod 600 /etc/crio/openshift-pull-secret

%end
EOFKS
