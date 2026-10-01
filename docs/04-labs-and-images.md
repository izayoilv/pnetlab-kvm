# 04 — Course labs and device images

## Labs

PNETLab topologies are `.unl` files. The activity archive nests a zip per module,
so the import extracts the outer archive and then any inner zips before
collecting the `.unl` files.

```bash
scripts/import-labs.sh /path/to/activity.zip
# or: SRC=/path/to/activity.zip scripts/import-labs.sh
```

It copies the `.unl` files into the repo `labs/` directory (gitignored — the
instructor's material is kept locally, not committed) and uploads them to the
guest at `/opt/unetlab/labs/`, then runs
`/opt/unetlab/wrappers/unl_wrapper -a fixpermissions`.

Expected guest layout:

```
-RWXR-XR-X <web-user> <web-group>  /opt/unetlab/labs/<module>.unl
```

Alternative: use the PNETLab web UI **Import** button to upload each `.unl`.

Open the labs from the web UI sidebar; start nodes and open an HTML5 console.

> **Known limitation:** in PNETLab 5.x the CLI wrapper's node start is broken
> (`unl_wrapper -a start` fails with `Call to undefined method
> Node::getNodes()`). Start and stop the labs from the web UI instead. There is
> no simple HTTP API on this build either (`/api/*` returns 404).

## Device images

PNETLab QEMU devices live under `/opt/unetlab/addons/qemu/<image-folder>/`.
The appliance normally already contains the images the course labs use; list
what is present:

```bash
ssh root@192.168.122.20 'ls -1 /opt/unetlab/addons/qemu/'
```

Typical Cisco images for the modules are folders such as
`vios-adventerprisek9-m.spa.159-3.m9` and
`viosl2-adventerprisek9-m.ssa.high_iron_20200929`, each containing a
`virtioa.qcow2`. VPCS is built into PNETLab and needs no image file.

If a node shows `(INVALID)` in its Edit dialog, the image folder name does not
match what the lab expects — pull it (below) or symlink the existing folder to
the expected name.

### Fix permissions / verify

```bash
ssh root@192.168.122.20 '/opt/unetlab/wrappers/unl_wrapper -a fixpermissions; \
  ls -1 /opt/unetlab/addons/qemu/'
```

## Fallback: pull missing images with ishare2

If an image is missing, use `ishare2`. Current source is
`https://github.com/ishare2-org/ishare2-cli` (the `pnetlabrepo/ishare2` repo is
deprecated).

```bash
ssh root@192.168.122.20 'wget -qO- https://ishare2.sh/install | sh'
ssh root@192.168.122.20 'ishare2 search qemu <keyword>'
ssh root@192.168.122.20 'ishare2 pull qemu <id>'
ssh root@192.168.122.20 'ishare2 installed qemu'
```

`scripts/pull-images.sh` wraps this (`VIOS_ID=… VIOSL2_ID=… scripts/pull-images.sh`).

If the downloaded folder name differs from what the lab expects, symlink it:

```bash
ssh root@192.168.122.20 'cd /opt/unetlab/addons/qemu && \
  ln -sfn <downloaded-dir> <expected-folder-name> && \
  /opt/unetlab/wrappers/unl_wrapper -a fixpermissions'
```

Cisco images are proprietary; images supplied by the instructor can be copied
into `/opt/unetlab/addons/qemu/<exact-folder>/` instead.
