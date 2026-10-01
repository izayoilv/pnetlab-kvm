# PNETLab on KVM (libvirt)

Run the PNETLab network-emulator appliance on libvirt/KVM instead of VMware
Workstation. The appliance runs on the libvirt NAT network (host-only access by
default) and uses nested virtualization so PNETLab can boot its own QEMU lab
nodes. This guide also imports the course `.unl` topologies.

## Reference environment (tested on)

Fedora 44 host, Intel i5-8350U (8 threads), 7.5 GiB RAM, nested KVM enabled
(`/sys/module/kvm_intel/parameters/nested = Y`), libvirt `qemu:///system`. The
host is on Wi-Fi, so bridging to the LAN is not available and the VM uses
libvirt's NAT network. Adjust paths and resources to your own host.

## Roles and reading order

| # | Step | Document |
|---|---|---|
| 0 | Host prerequisites | `docs/00-prerequisites.md` |
| 1 | Convert the VMware appliance to qcow2 | `docs/01-convert-appliance.md` |
| 2 | Define the VM and reserve its IP | `docs/02-create-vm.md` |
| 3 | Boot, access, first-run setup | `docs/03-access-and-setup.md` |
| 4 | Import labs and device images | `docs/04-labs-and-images.md` |

Troubleshooting: `docs/05-troubleshooting.md`.

## Layout

```
.
├── README.md
├── docs/
│   ├── 00-prerequisites.md
│   ├── 01-convert-appliance.md
│   ├── 02-create-vm.md
│   ├── 03-access-and-setup.md
│   ├── 04-labs-and-images.md
│   └── 05-troubleshooting.md
├── scripts/
│   ├── convert-appliance.sh
│   ├── inspect-disk.sh
│   ├── create-vm.sh
│   ├── reserve-ip.sh
│   ├── import-labs.sh
│   ├── pull-images.sh
│   └── destroy-vm.sh
└── labs/                (course topologies; .unl is gitignored)
```

## Paths and resources

Every path and size is configurable through environment variables; the examples
in these docs use `$HOME` and a libvirt storage pool named `virtimages`. If your
pool lives somewhere else, pass `POOL`/`VOL` or point the scripts at your own
paths — nothing here depends on a particular machine. See each document for the
overrides it accepts.

## Notes

- Host-only access by design (libvirt NAT `192.168.122.0/24`). Adapt the network
  section if you need LAN or internet access to the UI.
- PNETLab web login (offline mode): `admin` / `pnet`. SSH: `root` / `pnet`.
  Change both after first boot.
- Device images the course labs use are normally bundled in the appliance;
  `ishare2` is documented as a fallback if one is missing.
- Tear down with `scripts/destroy-vm.sh`, never with
  `virsh undefine --remove-all-storage` (it can delete attached ISOs).
