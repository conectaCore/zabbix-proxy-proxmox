```bash
#!/usr/bin/env bash

COMMUNITY_SCRIPTS_URL="${COMMUNITY_SCRIPTS_URL:-https://raw.githubusercontent.com/community-scripts/ProxmoxVE/main}"

source <(
  curl -fsSL \
    "${COMMUNITY_SCRIPTS_CORE_URL:-https://raw.githubusercontent.com/community-scripts/core/main}/pve/vm-core.func"
)

load_functions

APP="Zabbix Proxy"

echo "========================================"
echo "        ${APP}"
echo "========================================"
echo
echo "Community Scripts VM Core carregado!"
echo
echo "Host: $(hostname)"
echo "Data: $(date)"
echo
echo "Teste concluído."
```
