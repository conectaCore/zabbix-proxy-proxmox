#!/usr/bin/env bash

COMMUNITY_SCRIPTS_URL="${COMMUNITY_SCRIPTS_URL:-https://raw.githubusercontent.com/community-scripts/ProxmoxVE/main}"

source <(curl -fsSL "${COMMUNITY_SCRIPTS_CORE_URL:-https://raw.githubusercontent.com/community-scripts/core/main}/pve/vm-core.func")

load_functions

APP="Zabbix Proxy"
APP_TYPE="vm"
NSAPP="zabbix-proxy-vm"

echo
echo "========================================"
echo "        Zabbix Proxy"
echo "========================================"
echo
echo "Executando verificações do Proxmox..."
echo

vm_preflight

echo
echo "========================================"
echo "        PREFLIGHT CONCLUÍDO"
echo "========================================"
echo
echo "O ambiente Proxmox passou pelo preflight."
echo
echo "Nenhuma VM foi criada."
echo "Nenhum pacote foi instalado."
echo
