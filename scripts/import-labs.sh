#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

SRC="${1:-${SRC:-}}"
VM_IP="${VM_IP:-192.168.122.20}"
VM_USER="${VM_USER:-root}"
REPO_LABS="${REPO_LABS:-$SCRIPT_DIR/../labs}"
REMOTE_LABDIR="${REMOTE_LABDIR:-/opt/unetlab/labs}"
WORKDIR="${WORKDIR:-${TMPDIR:-/tmp}/pnetlab-labs}"

if [[ -z "$SRC" ]]; then
  echo "usage: $0 <activity.zip>" >&2
  echo "   or: SRC=/path/to/activity.zip $0" >&2
  exit 2
fi
[[ -f "$SRC" ]] || { echo "error: activity zip not found: $SRC" >&2; exit 1; }
rm -rf "$WORKDIR"; mkdir -p "$WORKDIR" "$REPO_LABS"

unzip -o "$SRC" -d "$WORKDIR" >/dev/null
while IFS= read -r z; do
  unzip -o "$z" -d "${z%.zip}_ex" >/dev/null
done < <(find "$WORKDIR" -name '*.zip' -print)
mapfile -t UNL < <(find "$WORKDIR" -name '*.unl' -print)
[[ ${#UNL[@]} -gt 0 ]] || { echo "error: no .unl files in $SRC" >&2; exit 1; }

for f in "${UNL[@]}"; do cp "$f" "$REPO_LABS/"; done
echo "Copied ${#UNL[@]} lab(s) into $REPO_LABS"

echo "Uploading labs to ${VM_USER}@${VM_IP}:${REMOTE_LABDIR}"
scp "${UNL[@]}" "${VM_USER}@${VM_IP}:${REMOTE_LABDIR}/"
ssh "${VM_USER}@${VM_IP}" \
  "chmod 755 ${REMOTE_LABDIR}/*.unl; /opt/unetlab/wrappers/unl_wrapper -a fixpermissions || true"
echo "Done. Refresh the PNETLab web UI and open the labs."
