#!/usr/bin/env bash
set -euo pipefail

URI="${LIBVIRT_URI:-qemu:///system}"
NAME="${NAME:-pnetlab}"
POOL="${POOL:-virtimages}"
VOL="${VOL:-pnetlab.qcow2}"

virsh_cmd=(virsh --connect "$URI")

"${virsh_cmd[@]}" destroy "$NAME" 2>/dev/null || true
"${virsh_cmd[@]}" undefine "$NAME" --nvram 2>/dev/null || "${virsh_cmd[@]}" undefine "$NAME" 2>/dev/null || true
"${virsh_cmd[@]}" vol-delete --pool "$POOL" "$VOL" 2>/dev/null || true
echo "Removed VM '$NAME' and volume '$VOL' from pool '$POOL' (ISOs untouched)."
