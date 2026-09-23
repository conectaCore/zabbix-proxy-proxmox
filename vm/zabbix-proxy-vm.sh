```bash
#!/usr/bin/env bash

set -Eeuo pipefail

APP="Zabbix Proxy"

# Community Scripts VM Core
source <(
  curl -fsSL \
  "${COMMUNITY_SCRIPTS_CORE_URL:-https://raw.githubusercontent.com/community-scripts/core/main}/pve/vm-core.func"
)

load_functions

clear

echo "========================================"
echo "        ${APP}"
echo "========================================"
echo
echo "Community Scripts VM Core carregado!"
echo
echo "APP: ${APP}"
echo "Hostname: $(hostname)"
echo "Data: $(date)"
echo
echo "Teste concluído."
```
