# Prerequisites

Complete these host and source-file prerequisites before following any step.

## Host requirements

- A 64-bit x86_64 Linux host with hardware virtualization enabled —
  `grep -cE '(vmx|svm)' /proc/cpuinfo` must return more than `0`.
- Nested virtualization enabled on the host, because PNETLab runs its own QEMU
  nodes inside the appliance:
  ```bash
  cat /sys/module/kvm_intel/parameters/nested   # expect: Y (AMD: kvm_amd)
  ```
- KVM, QEMU tools, and libvirt installed (`qemu-img`, `qemu-nbd`,
  `virt-install`, `virsh`, `virt-manager`, `unzip`, `curl`).
- RAM: 8 GiB recommended. The appliance wants 4 GiB and lab nodes add more, so
  on smaller hosts close other applications and run one lab at a time.
- Free disk space for the converted disk and its staging copy (roughly 20 GiB
  during conversion; the disk itself is sparse, ~8 GiB used).
- A libvirt storage pool for the disk. These docs use a pool named
  `virtimages` (its target directory is yours to choose); adjust with
  `POOL`/`VOL` or your own paths.
- Reference environment (tested on): Fedora 44, 8 CPU threads, 7.5 GiB RAM.
  On Debian/Ubuntu hosts, translate `dnf` to `apt` — the concepts are the same.

## Libvirt network

The appliance uses the libvirt `default` network (NAT, `192.168.122.0/24`).
Confirm it is active:

```bash
virsh --connect qemu:///system net-list
```

## Source files

You need the instructor's PNETLab appliance archive and the activity archive
(both may be `.zip` or an OVA). Paths are passed to the scripts; the examples
below use generic names:

| Item | Example path |
|---|---|
| Appliance archive | `$HOME/Downloads/PNETLab-appliance.zip` |
| Activity archive (`.unl` labs) | `$HOME/Downloads/pnetlab-activity.zip` |

Do not modify the originals; scripts extract into a working directory
(`$HOME/pnetlab/staging` by default, overridable with `WORKDIR`).

## sudo

`scripts/inspect-disk.sh` uses `sudo` for `modprobe nbd` and `qemu-nbd`. It is
optional — skip it and rely on the first boot to prove the disk works. All other
scripts operate through libvirt and need no `sudo` when your user is in the
`libvirt` group.
