#!/usr/bin/env bash
set -euo pipefail

URI="${LIBVIRT_URI:-qemu:///system}"
NETWORK="${NETWORK:-default}"
NAME="${NAME:-pnetlab}"
MAC_MGMT="${MAC_MGMT:-52:54:00:00:00:20}"
MAC_DATA="${MAC_DATA:-52:54:00:00:00:21}"
IP_MGMT="${IP_MGMT:-192.168.122.20}"
IP_DATA="${IP_DATA:-192.168.122.21}"

virsh_cmd=(virsh --connect "$URI")

reserve() {
  local name=$1 mac=$2 ip=$3 existing
  existing=$("${virsh_cmd[@]}" net-dumpxml "$NETWORK" | grep -oE "<host [^>]*name=['\"]$name['\"][^>]*/>" || true)
  if [[ -n "$existing" ]]; then
    if grep -qE "mac=['\"]$mac['\"]" <<<"$existing"; then
      echo "$name: already reserved ($mac)"; return 0
    fi
    "${virsh_cmd[@]}" net-update "$NETWORK" delete ip-dhcp-host "$existing" --live --config
    echo "$name: replaced stale reservation"
  fi
  "${virsh_cmd[@]}" net-update "$NETWORK" add ip-dhcp-host \
    "<host mac='$mac' name='$name' ip='$ip'/>" --live --config
  echo "$name -> $ip ($mac)"
}

reserve "${NAME}-mgmt" "$MAC_MGMT" "$IP_MGMT"
reserve "${NAME}-data" "$MAC_DATA" "$IP_DATA"
