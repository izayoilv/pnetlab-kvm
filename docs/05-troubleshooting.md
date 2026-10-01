# 05 — Troubleshooting

## VM won't boot / "no bootable device"

- The disk may be blank, or the CD booted instead of the disk.
- Confirm the disk has an installed system (`scripts/inspect-disk.sh <disk>`,
  needs sudo).
- If blank, let the attached ISO run its preseed install once, then reboot: the
  domain is defined with `--boot hd`, so it will boot the disk next time.
- Verify the disk is attached:
  `virsh --connect qemu:///system domblklist pnetlab`.

## Lab nodes start then immediately stop

- Most common cause: no virtualization inside the guest. Check:
  ```bash
  ssh root@192.168.122.20 'ls -l /dev/kvm; grep -c vmx /proc/cpuinfo'
  ```
- If `/dev/kvm` is missing, the domain lacks `host-passthrough`:
  ```bash
  virsh --connect qemu:///system dumpxml pnetlab | grep "cpu mode"
  ```
  It must be `cpu mode='host-passthrough'`. Also confirm host nested:
  `cat /sys/module/kvm_intel/parameters/nested` (expect `Y`).
- If an image field shows `(INVALID)` the image is missing — see docs/04.

## Web UI unreachable

- Check the VM is running: `virsh --connect qemu:///system domstate pnetlab`.
- Check the lease: `virsh --connect qemu:///system net-dhcp-leases default`.
- Check the guest IP: `ssh root@192.168.122.20 'ip -br a'`.
- `curl -I http://192.168.122.20` should return `301` to the store path.
- If the IP is wrong, confirm the reservation MAC matches the domain:
  `virsh --connect qemu:///system domiflist pnetlab` vs `scripts/reserve-ip.sh`
  output.

## Guest NICs are not eth0/eth1

- Happens if the NIC model was changed from e1000 (for example to virtio-net).
- Recreate with `model=e1000` (see `scripts/create-vm.sh`).

## `ishare2` fails (404 / repo.pnetlab.com)

- Install from the current source (`ishare2-org/ishare2-cli`):
  `wget -qO- https://ishare2.sh/install | sh`.
- In the guest, ensure CA certs and connectivity:
  `apt-get update && apt-get install -y ca-certificates`.
- If apt complains about `repo.pnetlab.com`, comment that line in
  `/etc/apt/sources.list` and retry.

## Lab references an image folder that doesn't exist

- List what's installed: `ls -1 /opt/unetlab/addons/qemu/`.
- Either pull it with ishare2 or symlink the existing folder to the expected
  name and run `unl_wrapper -a fixpermissions` (see docs/04).

## Host runs out of memory / labs are sluggish

- The appliance takes 4096 MB and lab nodes add more. Hosts with 8 GiB of RAM or
  less are the binding constraint; close other applications.
- To shrink the VM, redefine the domain without its disk:
  ```bash
  RAM=3072 START=0 scripts/create-vm.sh
  virsh --connect qemu:///system destroy pnetlab
  virsh --connect qemu:///system start pnetlab
  ```
- In PNETLab, reduce per-node RAM in the node Edit dialog, and run one lab at a
  time.

## Disk space

- The guest disk is sparse (1000 GiB virtual, a few GiB used) and lives in your
  libvirt pool. Keep the pool on a filesystem with free space.
- During conversion a staging copy is also written under `$WORKDIR`; it is
  removed after import unless `KEEP_LOCAL=1`.

## Data-loss warning

Never use `virsh undefine --remove-all-storage`; it can delete ISOs attached as
volumes. Use `scripts/destroy-vm.sh`, which removes only the domain and its
qcow2 volume.
