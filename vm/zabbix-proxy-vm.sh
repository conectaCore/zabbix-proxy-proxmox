#!/usr/bin/env bash

set -Eeuo pipefail

COMMUNITY_SCRIPTS_URL="${COMMUNITY_SCRIPTS_URL:-https://raw.githubusercontent.com/community-scripts/ProxmoxVE/main}"
COMMUNITY_SCRIPTS_CORE_URL="${COMMUNITY_SCRIPTS_CORE_URL:-https://raw.githubusercontent.com/community-scripts/core/main}"

source <(curl -fsSL "${COMMUNITY_SCRIPTS_CORE_URL}/pve/vm-core.func")

load_functions

APP="Zabbix Proxy"
APP_TYPE="vm"
NSAPP="zabbix-proxy-vm"

ARCH=$(dpkg --print-architecture)
GEN_MAC=02:$(openssl rand -hex 5 | awk '{print toupper($0)}' | sed 's/\(..\)/\1:/g; s/.$//')

METHOD=""
VERBOSE="no"

header_info() {
    echo
    echo "========================================"
    echo "          ZABBIX PROXY VM"
    echo "========================================"
    echo
}

default_settings() {
    vm_apply_machine_type "q35"

    VMID=$(get_valid_nextid)

    if [ "$ARCH" = "arm64" ]; then
        CPU_TYPE=""
    else
        CPU_TYPE=" -cpu host"
    fi

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
    METHOD="default"

    vm_echo_default_settings
}

advanced_settings() {
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
    echo "MAC         : ${MAC}"
    echo "VLAN        : ${VLAN:-Default}"
    echo "Start VM    : ${START_VM}"
    echo
}

header_info

vm_preflight

vm_start_script "Use Default Settings?" 10 58

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
echo "MAC              : ${MAC}"
echo
echo "Nenhuma VM foi criada."