#!/usr/bin/env bash

set -Eeuo pipefail

APP="Zabbix Proxy"
APP_TYPE="vm"
NSAPP="zabbix-proxy-vm"

source <(curl -fsSL "https://raw.githubusercontent.com/community-scripts/core/main/pve/vm-core.func")

load_functions

GEN_MAC="02:$(openssl rand -hex 5 | tr '[:lower:]' '[:upper:]' | sed 's/\(..\)/\1:/g; s/:$//')"

METHOD=""

header_info() {
echo
echo "========================================"
echo "          ZABBIX PROXY VM"
echo "========================================"
echo
}

default_settings() {

```
VMID="$(get_valid_nextid)"
DISK_SIZE="16G"
HN="zabbix-proxy"
CORE_COUNT="2"
RAM_SIZE="2048"
BRG="vmbr0"
MAC="$GEN_MAC"
VLAN=""
MTU=""
START_VM="yes"
VERBOSE="no"
METHOD="default"

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

```
METHOD="advanced"

echo
echo "========================================"
echo "       CONFIGURAÇÃO ADVANCED"
echo "========================================"
echo
echo "Advanced Settings funcionando."
echo
echo "VM ID disponível: $(get_valid_nextid)"
echo "Hostname padrão : zabbix-proxy"
echo
```

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
echo
