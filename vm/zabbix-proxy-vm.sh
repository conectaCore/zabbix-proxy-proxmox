#!/usr/bin/env bash

APP="Zabbix Proxy"

echo "========================================"
echo "        ${APP}"
echo "========================================"
echo
echo "1. Carregando Community Scripts VM Core..."

source <(curl -fsSL "https://raw.githubusercontent.com/community-scripts/core/main/pve/vm-core.func")

echo "2. vm-core.func carregado."

load_functions

echo "3. load_functions executado."
echo
echo "========================================"
echo "       TESTE CONCLUÍDO"
echo "========================================"
echo
echo "Nenhuma VM foi criada."
echo "Nenhum pacote foi instalado."
