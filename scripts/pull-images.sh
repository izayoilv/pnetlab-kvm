#!/usr/bin/env bash
set -euo pipefail

VM_IP="${VM_IP:-192.168.122.20}"
VM_USER="${VM_USER:-root}"
VIOS_ID="${VIOS_ID:-}"
VIOSL2_ID="${VIOSL2_ID:-}"

[[ -n "$VIOS_ID" && -n "$VIOSL2_ID" ]] || {
  echo "error: set VIOS_ID and VIOSL2_ID (from 'ishare2 search qemu vios' / viosl2)" >&2
  exit 1
}

ssh "${VM_USER}@${VM_IP}" \
  "wget -qO- https://ishare2.sh/install | sh; \
   ishare2 pull qemu ${VIOS_ID} && ishare2 pull qemu ${VIOSL2_ID}; \
   ishare2 installed qemu | grep -Ei 'vios|viosl2' || true"
echo "Done. Verify folder names match the lab; symlink if they differ (see docs/04)."
