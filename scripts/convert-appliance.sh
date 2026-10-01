#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

SRC="${1:-${SRC:-}}"
WORKDIR="${WORKDIR:-$HOME/pnetlab/staging}"
LOCAL="${LOCAL:-$WORKDIR/pnetlab.qcow2}"
POOL="${POOL:-virtimages}"
VOL="${VOL:-pnetlab.qcow2}"
OUT="${OUT:-}"
FORCE="${FORCE:-0}"
KEEP_LOCAL="${KEEP_LOCAL:-0}"

if [[ -z "$SRC" ]]; then
  echo "usage: $0 <appliance.ova|zip>" >&2
  echo "   or: SRC=/path/to/appliance.zip $0" >&2
  exit 2
fi
[[ -f "$SRC" ]] || { echo "error: appliance archive not found: $SRC" >&2; exit 1; }
mkdir -p "$WORKDIR"

if find "$WORKDIR" -maxdepth 2 -name '*.vmdk' -print -quit | grep -q .; then
  echo "Staging already present in $WORKDIR (skip extract)"
else
  echo "Extracting $(basename "$SRC") -> $WORKDIR"
  unzip -o "$SRC" -d "$WORKDIR" >/dev/null
fi

mapfile -t MF < <(find "$WORKDIR" -maxdepth 2 -name '*.mf' -print)
[[ ${#MF[@]} -eq 1 ]] || { echo "error: expected one .mf manifest, found ${#MF[@]}" >&2; exit 1; }
MANDIR="$(dirname "${MF[0]}")"

echo "Verifying checksums against $(basename "${MF[0]}")"
while IFS= read -r line; do
  [[ "$line" =~ ^SHA256\((.*)\)=[[:space:]]*(.+)$ ]] || continue
  file="${BASH_REMATCH[1]}"; want="${BASH_REMATCH[2]}"
  [[ -f "$MANDIR/$file" ]] || { echo "error: missing $file" >&2; exit 1; }
  got="$(sha256sum "$MANDIR/$file" | awk '{print $1}')"
  [[ "$got" == "$want" ]] || { echo "error: checksum mismatch for $file" >&2; exit 1; }
  echo "  ok: $file"
done < "${MF[0]}"

VMDK="$(find "$MANDIR" -maxdepth 1 -name '*.vmdk' -print -quit)"
[[ -n "$VMDK" ]] || { echo "error: no .vmdk found in $MANDIR" >&2; exit 1; }

if [[ -f "$LOCAL" && "$FORCE" != "1" ]]; then
  echo "Local qcow2 exists, skipping conversion (FORCE=1 to redo): $LOCAL"
else
  mkdir -p "$(dirname "$LOCAL")"
  echo "Converting $(basename "$VMDK") -> $LOCAL"
  qemu-img convert -p -f vmdk -O qcow2 "$VMDK" "$LOCAL"
fi

if [[ -n "$OUT" && -w "$(dirname "$OUT")" ]]; then
  if [[ -f "$OUT" && "$FORCE" != "1" ]]; then
    echo "Output exists, skipping copy (FORCE=1 to redo): $OUT"
  else
    cp "$LOCAL" "$OUT"
  fi
  qemu-img info "$OUT"
else
  virsh_cmd=(virsh --connect "${LIBVIRT_URI:-qemu:///system}")
  if "${virsh_cmd[@]}" vol-info --pool "$POOL" "$VOL" >/dev/null 2>&1; then
    if [[ "$FORCE" == "1" ]]; then
      "${virsh_cmd[@]}" vol-delete --pool "$POOL" "$VOL"
    else
      echo "Volume $POOL/$VOL already exists; not overwriting (FORCE=1 to redo)."
      "${virsh_cmd[@]}" vol-info --pool "$POOL" "$VOL"
      exit 0
    fi
  fi
  virt_bytes="$(qemu-img info --output=json "$LOCAL" | sed -n 's/.*"virtual-size": *\([0-9]*\).*/\1/p')"
  [[ -n "$virt_bytes" ]] || { echo "error: could not read virtual size" >&2; exit 1; }
  echo "Importing into libvirt pool $POOL as $VOL ($virt_bytes bytes virtual)"
  "${virsh_cmd[@]}" vol-create-as "$POOL" "$VOL" "$virt_bytes" --format qcow2
  "${virsh_cmd[@]}" vol-upload --pool "$POOL" "$VOL" "$LOCAL"
  "${virsh_cmd[@]}" vol-info --pool "$POOL" "$VOL"
fi

if [[ "$KEEP_LOCAL" != "1" && "$LOCAL" != "$OUT" ]]; then
  rm -f "$LOCAL"
  echo "Removed local staging image (KEEP_LOCAL=1 to retain): $LOCAL"
fi
