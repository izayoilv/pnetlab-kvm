#!/usr/bin/env bash
set -euo pipefail

QC="${1:-${QC:-}}"
NBD="${NBD:-/dev/nbd0}"
SUDO="${SUDO:-sudo}"

if [[ -z "$QC" ]]; then
  echo "usage: $0 <disk.qcow2>" >&2
  exit 2
fi
[[ -f "$QC" ]] || { echo "error: image not found: $QC" >&2; exit 1; }

cleanup() { $SUDO qemu-nbd --disconnect "$NBD" >/dev/null 2>&1 || true; }
trap cleanup EXIT

echo "Attaching $QC read-only at $NBD (sudo password may be required)"
$SUDO modprobe nbd max_part=16
$SUDO qemu-nbd --connect="$NBD" --read-only "$QC"
$SUDO partprobe "$NBD" >/dev/null 2>&1 || true
sleep 1

echo "=== partition table ==="
$SUDO parted -s "$NBD" unit MiB print || $SUDO fdisk -l "$NBD"

echo "=== filesystems ==="
lsblk -f "$NBD" || true
