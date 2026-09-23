#!/usr/bin/env bash

set -Eeuo pipefail

APP="Zabbix Proxy"

COMMUNITY_SCRIPTS_CORE_URL="${COMMUNITY_SCRIPTS_CORE_URL:-https://raw.githubusercontent.com/community-scripts/core/main}"

echo "========================================"
echo "        ${APP}"
echo "========================================"
echo
echo "Iniciando teste do Community Scripts VM Core..."
echo

CORE_FILE="$(mktemp)"

cleanup() {
rm -f "$CORE_FILE"
}

trap cleanup EXIT

echo "Baixando vm-core.func..."

if ! curl -fsSL 
-o "$CORE_FILE" 
"${COMMUNITY_SCRIPTS_CORE_URL}/pve/vm-core.func"; then

```
echo
echo "ERRO: não foi possível baixar o vm-core.func."
exit 1
```

fi

echo "Download concluído."
echo

echo "Carregando vm-core.func..."

if ! source "$CORE_FILE"; then
echo
echo "ERRO: não foi possível carregar o vm-core.func."
exit 1
fi

echo "vm-core.func carregado."
echo

if ! declare -F load_functions >/dev/null 2>&1; then
echo "ERRO: a função load_functions não foi encontrada."
exit 1
fi

echo "Executando load_functions..."

load_functions

echo
echo "========================================"
echo "       TESTE CONCLUÍDO COM SUCESSO"
echo "========================================"
echo
echo "Aplicação : ${APP}"
echo "Hostname  : $(hostname)"
echo "Data      : $(date)"
echo
echo "Community Scripts VM Core carregado corretamente."
echo
echo "Nenhuma VM foi criada."
echo "Nenhum pacote foi instalado."
echo

exit 0
