# Matriz de compatibilidade

## Resumo do projeto

| Componente | Versão alvo do projeto | Observação |
|---|---|---|
| Proxmox VE | Versão compatível com o Community Scripts VM Core usado pelo projeto | Recomendado manter o host Proxmox atualizado |
| Ubuntu | 24.04 LTS (Noble Numbat) | Imagem cloud usada pelo instalador |
| Zabbix Proxy | 7.0 LTS | Repositório oficial da série 7.0 |
| Banco | SQLite | Suportado para Zabbix Proxy |
| Arquitetura | amd64 / arm64 | Pacotes oficiais do Zabbix 7.0 disponíveis para Ubuntu 24.04 |

## Ubuntu 24.04 LTS

Ubuntu 24.04 LTS foi lançado em abril de 2024 e tem suporte padrão até maio de 2029.

O instalador deste projeto é direcionado especificamente para 24.04 LTS.

Fonte oficial: https://ubuntu.com/about/release-cycle

## Zabbix 7.0 LTS

O projeto usa o repositório oficial da série 7.0.

Ciclo de vida oficial:

| Versão | Lançamento | Suporte completo | Suporte limitado |
|---|---:|---:|---:|
| 7.0 LTS | 04/06/2024 | 30/06/2027 | 30/06/2029 |

O repositório oficial oferece `zabbix-proxy-sqlite3` e `zabbix-sql-scripts` para Ubuntu 24.04 em `amd64` e `arm64`.

No momento desta documentação, a listagem oficial da série 7.0 mostra a linha 7.0.31 para Ubuntu 24.04.

Fontes oficiais:

- https://www.zabbix.com/br/life_cycle_and_release_policy
- https://www.zabbix.com/documentation/7.0/pt/manual/installation/requirements
- https://www.zabbix.com/documentation/7.0/pt/manual/installation/install_from_packages
- https://repo.zabbix.com/zabbix/7.0/ubuntu/
- https://repo.zabbix.com/zabbix/7.0/ubuntu-arm64/

## Observações importantes

- O projeto instala **Zabbix Proxy**, não Zabbix Server.
- O projeto não instala frontend web do Zabbix.
- O projeto usa SQLite local para o Proxy.
- O parâmetro `Server` deve apontar para o serviço do Zabbix Server, normalmente `host:10051`, e não para a URL `/zabbix/` do frontend web.
- Para Proxy Active, o nome em `Hostname` deve corresponder ao nome do Proxy cadastrado no Zabbix Server.
