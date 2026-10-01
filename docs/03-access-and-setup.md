# 03 — Access and first-run setup

Once the domain is running (`virsh --connect qemu:///system start pnetlab`), the
appliance boots Ubuntu 18.04.6 straight from the converted disk.

## Console

- GUI: `virt-manager --connect qemu:///system --show-domain-console pnetlab`
- CLI: `virsh --connect qemu:///system console pnetlab` (detach with `Ctrl-]`)
- SSH: `ssh root@192.168.122.20` (default password `pnet`)

## Web UI

Open `http://192.168.122.20` and log in:

- **Offline mode:** `admin` / `pnet` — no internet/registration required.
- **Online mode:** register at pnetlab.com and sign in (needs outbound internet,
  which the NAT network provides).

The UI redirects to `/store/public/admin/main/view`.

## First-run checklist

1. Log in and complete the initial setup wizard (defaults are fine).
2. Change the web `admin` password and the Linux `root` password.
3. Set the timezone.
4. Enable the HTML5 console in the sidebar (no native client needed).

## Verify nested KVM (required for lab nodes)

Nested virtualization must reach the guest, or lab nodes will not start.

From the host:

```bash
ps -ef | grep -o -- "-cpu [^ ]*" | grep -v grep   # expect: -cpu host,migratable=on
```

From the guest:

```bash
ls -l /dev/kvm              # expect a character device
grep -c vmx /proc/cpuinfo   # expect > 0
```

If `/dev/kvm` is missing, the domain lacks `host-passthrough` — see docs/05.

## Notes

- The appliance normally ships the device images the course labs use under
  `/opt/unetlab/addons/qemu/` (see docs/04).
- If the web UI is unreachable, see docs/05-troubleshooting.md.
