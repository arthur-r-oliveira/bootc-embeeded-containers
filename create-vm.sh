VMNAME=microshift-4.19-bootc-vm1
NETNAME=default
#sudo virt-install \
#    --name ${VMNAME} \
#    --vcpus 2 \
#    --memory 2048 \
#    --disk path=/var/lib/libvirt/images/${VMNAME}.qcow2,size=20 \
#    --network network=${NETNAME},model=virtio \
#    --events on_reboot=restart \
#    --location /var/lib/libvirt/images/rhel-9.4-$(uname -m)-boot.iso \
#    --initrd-inject kickstart.ks \
#    --extra-args "inst.ks=file://kickstart.ks" \
#    --wait

sudo virt-install --name ${VMNAME} \
--os-variant fedora-coreos-stable \
--memory 8192 \
--vcpus 4 \
--disk size=120 \
--network network=${NETNAME} \
--location ${VMNAME}.iso,kernel=images/pxeboot/vmlinuz,initrd=images/pxeboot/initrd.img \
--initrd-inject kickstart.ks \
--extra-args "inst.ks=file:/kickstart.ks"
