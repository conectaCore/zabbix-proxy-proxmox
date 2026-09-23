#!/usr/bin/env bash

APP="Zabbix Proxy"

echo "========================================"
echo "        ${APP}"
echo "========================================"
echo
echo "Carregando Community Scripts VM Core..."

source <(curl -fsSL "https://raw.githubusercontent.com/community-scripts/core/main/pve/vm-core.func")

echo "Core carregado."
echo

load_functions

echo "load_functions executado."
echo
echo "========================================"
echo "       TESTE CONCLUÍDO COM SUCESSO"
echo "========================================"
echo
echo "Aplicação: ${APP}"
echo "Nenhuma VM foi criada."
echo "Nenhum pacote foi instalado."
