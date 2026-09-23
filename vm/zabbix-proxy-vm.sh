#!/usr/bin/env bash

COMMUNITY_SCRIPTS_URL="${COMMUNITY_SCRIPTS_URL:-https://raw.githubusercontent.com/community-scripts/ProxmoxVE/main}"

source <(curl -fsSL "${COMMUNITY_SCRIPTS_CORE_URL:-https://raw.githubusercontent.com/community-scripts/core/main}/pve/vm-core.func")

load_functions

APP="Zabbix Proxy"
APP_TYPE="vm"
NSAPP="zabbix-proxy-vm"

ARCH=$(dpkg --print-architecture)
GEN_MAC=02:$(openssl rand -hex 5 | awk '{print toupper($0)}' | sed 's/\(..\)/\1:/g; s/.$//')

METHOD=""
VERBOSE="no"

default_settings() {
VMID=$(get_valid_nextid)

```
DISK_SIZE="16G"
HN="zabbix-proxy"
CORE_COUNT="2"
RAM_SIZE="2048"
BRG="vmbr0"
MAC="$GEN_MAC"
VLAN=""
MTU=""
START_VM="yes"
METHOD="default"

vm_echo_default_settings
```

}

advanced_settings() {
METHOD="advanced"

```
echo
echo "========================================"
echo "       ADVANCED FUNCIONOU"
echo "========================================"
echo
echo "VM ID      : $(get_valid_nextid)"
echo "Hostname   : zabbix-proxy"
echo "CPU Cores  : 2"
echo "RAM        : 2048 MiB"
echo "Disco      : 16G"
echo "Bridge     : vmbr0"
echo
```

}

header_info() {
echo
echo "========================================"
echo "          ZABBIX PROXY VM"
echo "========================================"
echo
}

header_info

vm_preflight

vm_start_script "Use Default Settings?" 10 58

echo
echo "========================================"
echo "             RESULTADO"
echo "========================================"
echo
echo "Método escolhido: ${METHOD}"
echo
echo "Nenhuma VM foi criada."
echo "Nenhum pacote foi instalado."
