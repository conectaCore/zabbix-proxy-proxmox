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

header_info

vm_preflight

echo "  ⚙️  Using Default Settings"

default_settings

echo
echo "========================================"
echo "           TESTE CONCLUÍDO"
echo "========================================"
echo
echo "Nenhuma VM foi criada."
echo "Nenhum pacote foi instalado."
