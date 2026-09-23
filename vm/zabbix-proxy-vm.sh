#!/usr/bin/env bash

set -Eeuo pipefail

APP="Zabbix Proxy"

source <(curl -fsSL "https://raw.githubusercontent.com/community-scripts/core/main/pve/vm-core.func")

load_functions

GEN_MAC="02:$(openssl rand -hex 5 | tr '[:lower:]' '[:upper:]' | sed 's/\(..\)/\1:/g; s/:$//')"

header_info() {
echo
echo "========================================"
echo "          ZABBIX PROXY VM"
echo "========================================"
echo
}

default_settings() {
VMID="$(get_valid_nextid)"
DISK_SIZE="16G"
HN="zabbix-proxy"
CORE_COUNT="2"
RAM_SIZE="2048"
BRG="vmbr0"
MAC="$GEN_MAC"
START_VM="yes"
METHOD="default"

```
echo
echo "========================================"
echo "       CONFIGURAÇÃO DEFAULT"
echo "========================================"
echo
echo "VM ID       : ${VMID}"
echo "Hostname    : ${HN}"
echo "CPU Cores   : ${CORE_COUNT}"
echo "RAM         : ${RAM_SIZE} MiB"
echo "Disco       : ${DISK_SIZE}"
echo "Bridge      : ${BRG}"
echo "MAC         : ${MAC}"
echo "Iniciar VM  : ${START_VM}"
echo
```

}

advanced_settings() {
METHOD="advanced"

```
VMID="$(get_valid_nextid)"

if ! VMID=$(whiptail \
    --backtitle "Proxmox VE Helper Scripts" \
    --title "VIRTUAL MACHINE ID" \
    --inputbox "Set Virtual Machine ID" 8 58 "$VMID" \
    3>&1 1>&2 2>&3
); then
    exit 0
fi

HN="zabbix-proxy"

if ! HN=$(whiptail \
    --backtitle "Proxmox VE Helper Scripts" \
    --title "HOSTNAME" \
    --inputbox "Set Hostname" 8 58 "$HN" \
    3>&1 1>&2 2>&3
); then
    exit 0
fi

if ! CORE_COUNT=$(whiptail \
    --backtitle "Proxmox VE Helper Scripts" \
    --title "CPU CORES" \
    --inputbox "Set CPU Cores" 8 58 "2" \
    3>&1 1>&2 2>&3
); then
```
