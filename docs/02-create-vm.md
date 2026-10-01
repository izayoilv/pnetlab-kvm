# 02 — Create the VM and reserve its IP

Prerequisites: the qcow2 volume exists (docs/01), the appliance ISO is in the
working directory, and the libvirt `default` network is active.

## 1. Reserve the IPs

```bash
scripts/reserve-ip.sh
```

Adds two DHCP reservations on `default`:

| Name | MAC | IP |
|---|---|---|
| pnetlab-mgmt | `52:54:00:00:00:20` | `192.168.122.20` |
| pnetlab-data | `52:54:00:00:00:21` | `192.168.122.21` |

Idempotent: re-running does nothing if already reserved, and replaces stale
reservations of the same name. If another reservation already uses these IPs on
your network, override `IP_MGMT`/`IP_DATA` and update the URLs in docs/03–05.

## 2. Create the VM

```bash
scripts/create-vm.sh
```

Key choices and why:

- **4 vCPU / 4096 MB** (`RAM`, `VCPUS`) — matches the OVF; PNETLab recommends 4
  logical CPUs. On a memory-tight host use `RAM=3072 scripts/create-vm.sh`.
- **`--cpu host-passthrough`** — exposes hardware virtualization so PNETLab's
  own QEMU nodes run with nested KVM. Without it nodes won't start.
- **`--disk vol=<pool>/<vol>,bus=scsi` + `virtio-scsi`** — the guest keeps
  `/dev/sda` naming and gets better performance. Referencing the pool volume
  lets libvirt manage owner and SELinux label.
- **`model=e1000` NICs** — keeps the guest interface names `eth0`/`eth1`, which
  PNETLab expects. (virtio-net may rename them `ens*`.)
- **`--boot hd`** — boot the installed disk first; the appliance ISO stays
  attached on SATA only as reinstall/upgrade media.

The appliance ISO is auto-detected in `$WORKDIR`; set `ISO=/path/to/install.iso`
if it is elsewhere.

### Define without starting

To stage the domain now and boot later:

```bash
START=0 scripts/create-vm.sh
virsh --connect qemu:///system start pnetlab
```

The generated XML is written to `${TMPDIR:-/tmp}/pnetlab-domain.xml`
(override with `XML`).

### Overrides

`NAME`, `RAM`, `VCPUS`, `POOL`, `VOL`, `ISO`, `DISK` (use a path instead of a
pool volume), `MAC_MGMT`, `MAC_DATA`, `OSINFO`, `START`, `XML`, `LIBVIRT_URI`.

## 3. Verify

```bash
virsh --connect qemu:///system dominfo pnetlab
virsh --connect qemu:///system dumpxml pnetlab | grep -E "cpu mode|virtio-scsi|e1000|boot dev"
```

Expect: `State: running` (if started), `cpu mode='host-passthrough'`,
`virtio-scsi`, two `e1000` interfaces, `boot dev='hd'`.

## Notes

- The disk volume is owned by `qemu`/`root` after import; libvirt applies
  dynamic ownership and the `virt_image_t` SELinux label when the domain starts.
- Console: `virt-manager --connect qemu:///system --show-domain-console pnetlab`
  or `virsh --connect qemu:///system console pnetlab` (detach with `Ctrl-]`).
