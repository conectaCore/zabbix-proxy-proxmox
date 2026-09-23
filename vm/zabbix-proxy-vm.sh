#!/usr/bin/env bash

COMMUNITY_SCRIPTS_URL="${COMMUNITY_SCRIPTS_URL:-https://raw.githubusercontent.com/community-scripts/ProxmoxVE/main}"

source <(curl -fsSL "${COMMUNITY_SCRIPTS_CORE_URL:-https://raw.githubusercontent.com/community-scripts/core/main}/pve/vm-core.func")

load_functions

APP="Zabbix Proxy"
APP_TYPE="vm"
NSAPP="zabbix-proxy-vm"

var_os="ubuntu"
var_version="24.04"

OS_TYPE="ubuntu"
OS_VERSION="24.04"
OS_CODENAME="noble"
OS_DISPLAY="Ubuntu 24.04 LTS"

USE_CLOUD_INIT="yes"
CLOUDINIT_ENABLE="yes"

header_info() {
clear
echo
echo "========================================"
echo "          ZABBIX PROXY VM"
echo "========================================"
echo
}

default_settings() {

```
vm_apply_machine_type "q35"

VMID=$(get_valid_nextid)

CPU_TYPE=" -cpu host"
DISK_CACHE=""
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

vm_echo_default_settings
```

}

advanced_settings() {

```
METHOD="advanced"

vm_prompt_vmid "${VMID:-$(get_valid_nextid)}"
vm_prompt_machine_type "q35"
vm_prompt_disk_size "16G"
vm_prompt_disk_cache "none"
vm_prompt_hostname "zabbix-proxy"
vm_prompt_cpu_model "host"
vm_prompt_cpu_cores "2"
vm_prompt_ram "2048"
vm_prompt_bridge "vmbr0"
vm_prompt_mac "$GEN_MAC"
vm_prompt_vlan
vm_prompt_mtu
vm_prompt_verbose "no"
vm_prompt_start_vm "yes"

echo
echo "========================================"
echo "       CONFIGURAÇÃO AVANÇADA"
echo "========================================"
echo
echo "VM ID       : ${VMID}"
echo "Hostname    : ${HN}"
echo "CPU Cores   : ${CORE_COUNT}"
echo "RAM         : ${RAM_SIZE} MiB"
echo "Disk        : ${DISK_SIZE}"
echo "Bridge      : ${BRG}"
echo "VLAN        : ${VLAN:-Default}"
echo "Start VM    : ${START_VM}"
echo
```

}

vm_preflight

vm_start_script "Usar configurações padrão?" 12 60

echo
echo "========================================"
echo "          TESTE CONCLUÍDO"
echo "========================================"
echo
echo "Método escolhido : ${METHOD}"
echo "VM ID            : ${VMID}"
echo "Hostname         : ${HN}"
echo "CPU              : ${CORE_COUNT} cores"
echo "RAM              : ${RAM_SIZE} MiB"
echo "Disco            : ${DISK_SIZE}"
echo "Bridge           : ${BRG}"
echo
echo "Nenhuma VM foi criada."
