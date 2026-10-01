#!/usr/bin/env bash
set -euo pipefail

URI="${LIBVIRT_URI:-qemu:///system}"
NAME="${NAME:-pnetlab}"
RAM="${RAM:-4096}"
VCPUS="${VCPUS:-4}"
POOL="${POOL:-virtimages}"
VOL="${VOL:-pnetlab.qcow2}"
WORKDIR="${WORKDIR:-$HOME/pnetlab/staging}"
ISO="${ISO:-}"
MAC_MGMT="${MAC_MGMT:-52:54:00:00:00:20}"
MAC_DATA="${MAC_DATA:-52:54:00:00:00:21}"
OSINFO="${OSINFO:-ubuntu18.04}"
START="${START:-1}"
XML="${XML:-${TMPDIR:-/tmp}/pnetlab-domain.xml}"

if [[ -n "${DISK:-}" ]]; then
  DISK_OPT="path=$DISK,format=qcow2,bus=scsi"
else
  DISK_OPT="vol=$POOL/$VOL,format=qcow2,bus=scsi"
fi

if [[ -z "$ISO" ]]; then
  ISO="$(find "$WORKDIR" -maxdepth 3 -name '*-file2.iso' -print -quit 2>/dev/null || true)"
fi
[[ -n "$ISO" && -f "$ISO" ]] || {
  echo "error: appliance ISO not found; set ISO=/path/to/appliance-install.iso" >&2; exit 1; }

args=(
  virt-install --connect "$URI"
  --name "$NAME"
  --memory "$RAM" --vcpus "$VCPUS"
  --cpu host-passthrough
  --import
  --disk "$DISK_OPT"
  --controller type=scsi,model=virtio-scsi
  --disk path="$ISO",device=cdrom,bus=sata
  --network network=default,model=e1000,mac="$MAC_MGMT"
  --network network=default,model=e1000,mac="$MAC_DATA"
  --osinfo name="$OSINFO",require=off
  --graphics spice
  --boot hd
  --noautoconsole
)

if [[ "$START" == "1" ]]; then
  "${args[@]}"
  echo "VM '$NAME' defined and started."
else
  mkdir -p "$(dirname "$XML")"
  "${args[@]}" --print-xml > "$XML"
  virsh --connect "$URI" define "$XML"
  echo "VM '$NAME' defined (not started). Start with: virsh --connect $URI start $NAME"
fi

echo "Web UI: http://192.168.122.20 (admin/pnet)   Console: virsh console $NAME"
