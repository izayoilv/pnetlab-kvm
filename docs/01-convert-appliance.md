# 01 — Convert the VMware appliance to qcow2

The instructor ships PNETLab as a VMware appliance containing an OVF, a
`streamOptimized` VMDK, install/upgrade media (floppy + ISO), and a SHA256
manifest. This step converts the VMDK to qcow2 and imports it into a libvirt
storage pool so it can run on KVM.

## What's in the appliance

- Guest: Ubuntu 18.04.6 LTS with the `pnetlab2` kernel.
- Hardware in the OVF: 2 vCPU, 4096 MB RAM, one 1000 GB disk (lsilogic SCSI),
  SATA + cdrom, two E1000 NICs.
- The floppy and ISO are auto-install/upgrade media; the OS is already
  installed on the VMDK (its populated size matches the disk's used space).

## Run the conversion

```bash
scripts/convert-appliance.sh /path/to/appliance.zip
# or: SRC=/path/to/appliance.ova scripts/convert-appliance.sh
```

The script:

1. Extracts the archive into a working directory (default
   `$HOME/pnetlab/staging`; skips extraction if already present).
2. Verifies every file against the `.mf` SHA256 manifest (aborts on mismatch).
3. Converts the VMDK to a staging qcow2 with
   `qemu-img convert -f vmdk -O qcow2`.
4. Publishes it into the libvirt pool (default `virtimages`) as
   `pnetlab.qcow2`.

### Why the libvirt storage API

A managed pool directory (for example `/home/virtimages`) is commonly owned by
`qemu:libvirt` with mode `750`, so an unprivileged user cannot write the qcow2
there directly. The script instead creates and fills the volume through
libvirt, which needs no `sudo` when your user is in the `libvirt` group:

```bash
virsh vol-create-as <pool> <vol> <virtual-size-bytes> --format qcow2
virsh vol-upload --pool <pool> <vol> <local-qcow2>
```

The volume then gets the correct owner and SELinux label from libvirt.

Expected result:

```
Name:           pnetlab.qcow2
Type:           file
Capacity:       1000.00 GiB
Allocation:     ~7.8 GiB
```

The allocation matching the OVF's `populatedSize` confirms the disk carries an
installed system.

## Optional: inspect the disk before booting

```bash
scripts/inspect-disk.sh <disk.qcow2>
```

Attaches the image read-only with `qemu-nbd` and prints the partition table.
Requires `sudo`. Skip it if you cannot use sudo — the first boot proves the
disk.

## Reuse for other OVAs

Any VMware OVA/OVF can be handled the same way: pass the archive path.
Overrides: `SRC`, `WORKDIR`, `LOCAL`, `POOL`, `VOL`, `OUT` (write directly to a
writable path instead of the pool), `FORCE=1`, `KEEP_LOCAL=1`.

## Troubleshooting

- **Checksum mismatch** — re-download the archive; do not continue.
- **`Unknown image format` on a stream-optimized VMDK** — convert via a flat
  intermediate:
  ```bash
  qemu-img convert -O vmdk <disk>.vmdk /tmp/flat.vmdk
  qemu-img convert -f vmdk -O qcow2 /tmp/flat.vmdk <pool>/<vol>
  ```
- **`Permission denied` writing the pool directory** — expected; use the pool
  API path above, or set `OUT` to a writable directory.
