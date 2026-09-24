<div align="center">
  <a href="https://github.com/conectaCore/zabbix-proxy-proxmox">
    <img src="https://github.com/conectaCore.png?size=180" alt="ConectaCore" width="140" height="140">
  </a>

  <h1>ConectaCore — Zabbix Proxy para Proxmox VE</h1>

  <p>Instalação automatizada de Zabbix Proxy em uma VM Ubuntu 24.04 LTS no Proxmox VE.</p>

  <p>
    <a href="https://github.com/conectaCore/zabbix-proxy-proxmox/blob/main/LICENSE"><img src="https://img.shields.io/badge/license-MIT-green.svg" alt="MIT License"></a>
    <a href="https://www.ubuntu.com/desktop/developers"><img src="https://img.shields.io/badge/Ubuntu-24.04%20LTS-E95420.svg?logo=ubuntu&logoColor=white" alt="Ubuntu 24.04 LTS"></a>
    <a href="https://www.zabbix.com/"> <img src="https://img.shields.io/badge/Zabbix-7.0%20LTS-red.svg" alt="Zabbix 7.0 LTS"></a>
    <a href="https://www.proxmox.com/"> <img src="https://img.shields.io/badge/Proxmox%20VE-VM-purple.svg" alt="Proxmox VE"></a>
  </p>
</div>

> **Projeto:** `conectaCore/zabbix-proxy-proxmox`  
> **Objetivo:** criar uma VM Ubuntu 24.04 LTS e instalar o Zabbix Proxy com SQLite, de forma semelhante à experiência dos Community Scripts para Proxmox VE.

---

## Instalação rápida

No Shell do Proxmox, como `root`, execute:

```bash
bash -c "$(curl -fsSL https://raw.githubusercontent.com/conectaCore/zabbix-proxy-proxmox/main/vm/zabbix-proxy-vm.sh)"
```

O instalador apresenta o fluxo interativo de configuração e cria a VM automaticamente.

---

## O que o script faz

1. Carrega o **Community Scripts VM Core** oficial.
2. Executa as verificações de pré-requisitos do Proxmox.
3. Permite escolher entre **Default** e **Advanced**.
4. Cria uma VM com **Ubuntu Server 24.04 LTS** usando Cloud-Init.
5. Configura disco, CPU, memória, bridge, VLAN e demais opções da VM.
6. Baixa a imagem cloud oficial do Ubuntu.
7. Instala, no primeiro boot da VM, o **Zabbix Proxy com SQLite**.
8. Adiciona o repositório oficial do Zabbix para a linha **7.0 LTS**.
9. Configura o `zabbix_proxy.conf` e inicia o serviço `zabbix-proxy`.

O projeto usa o Core compartilhado do Community Scripts para a criação da VM e mantém a instalação do Zabbix separada, dentro da VM. O Core oficial é distribuído sob a licença MIT.  

---

## Configuração padrão

A opção **Default** usa os valores abaixo:

| Recurso | Valor padrão |
|---|---|
| Sistema operacional | Ubuntu Server 24.04 LTS |
| CPU | 2 vCPU |
| Memória | 2048 MiB |
| Disco | 16 GB |
| Machine Type | Q35 |
| Bridge | `vmbr0` |
| Cloud-Init | Habilitado |
| QEMU Guest Agent | Habilitado |
| Banco do Proxy | SQLite |
| Proxy Mode | Active (`ProxyMode=0`) |
| Porta do Zabbix Server | `10051` |

A opção **Advanced** permite ajustar os principais parâmetros da VM antes da criação.

---

## Configuração do Zabbix Proxy

Durante a instalação, o script solicita:

- endereço ou DNS do Zabbix Server;
- porta do Zabbix Server;
- nome do Proxy;
- modo do Proxy (Active ou Passive);
- porta de escuta, quando usado Proxy Passive.

Para Proxy Active, a configuração segue o formato do Zabbix 7.0:

```ini
ProxyMode=0
Server=SEU_ZABBIX_SERVER:10051
Hostname=nome-do-proxy
DBName=/var/lib/zabbix/zabbix_proxy.db
```

O endereço do **frontend web** não é usado pelo Proxy. Por exemplo, isto é o frontend:

```text
http://seu-servidor:6080/zabbix/
```

Mas o Proxy precisa acessar o serviço do Zabbix Server, normalmente em TCP `10051`:

```text
SEU_ZABBIX_SERVER:10051
```

No modo Active, o Proxy inicia a comunicação com o Zabbix Server.

---

## Coleta de dispositivos

Depois que o Proxy estiver instalado, os equipamentos da rede do cliente podem ser monitorados por ele.

Fluxo típico:

```text
Switch / Router / Firewall / UPS / AP
                │
                │ SNMP / ICMP / Agent
                ▼
        Zabbix Proxy (cliente)
                │
                │ TCP 10051
                ▼
          Zabbix Server
```

Para dispositivos de rede, o Proxy pode fazer consultas SNMP diretamente. Para hosts com Zabbix Agent, o endereço do Proxy pode ser usado para as verificações ativas/passivas de acordo com a arquitetura escolhida.

No frontend do Zabbix Server, os hosts devem ser atribuídos ao Proxy correspondente.

---

## Banco de dados

O projeto usa **SQLite** para o Zabbix Proxy:

```text
/var/lib/zabbix/zabbix_proxy.db
```

SQLite é uma opção suportada pelo Zabbix para **Proxy** e não deve ser confundida com a arquitetura de banco usada pelo Zabbix Server.

---

## Versões suportadas pelo projeto

### Ubuntu

**Versão suportada pelo instalador:**

- **Ubuntu Server 24.04 LTS (Noble Numbat)**

O Ubuntu 24.04 LTS foi lançado em abril de 2024 e possui suporte padrão até **maio de 2029**.  

> O instalador é direcionado especificamente para Ubuntu 24.04 LTS. Outras versões podem possuir pacotes Zabbix disponíveis no repositório oficial, mas não fazem parte do alvo deste script.

### Zabbix

**Versão utilizada pelo instalador:**

- **Zabbix 7.0 LTS**

O instalador usa o repositório oficial da série `7.0`, portanto o pacote instalado é a versão de manutenção mais recente disponibilizada nesse repositório no momento da instalação.

Em **24/09/2026**, o repositório oficial disponibiliza pacotes da série 7.0 para Ubuntu 24.04, incluindo `zabbix-proxy-sqlite3` e `zabbix-sql-scripts`. A listagem atual inclui a versão **7.0.31** para Ubuntu 24.04.  

O ciclo de vida oficial informado pelo Zabbix para o **7.0 LTS** é:

| Versão | Lançamento | Suporte completo | Suporte limitado |
|---|---:|---:|---:|
| Zabbix 7.0 LTS | 04/06/2024 | 30/06/2027 | 30/06/2029 |

O Zabbix também mantém a linha 7.4 como release estável, mas **este instalador não instala 7.4**: ele está intencionalmente fixado na linha 7.0 LTS para manter um alvo estável e previsível.

---

## Arquiteturas

O fluxo do projeto prevê imagens cloud do Ubuntu para:

- `amd64`
- `arm64`

O repositório oficial do Zabbix também disponibiliza pacotes do Proxy SQLite para Ubuntu 24.04 em `amd64` e `arm64`. A validação principal deste projeto foi feita em ambiente `amd64`.

---

## Requisitos

Antes de executar:

- Proxmox VE com acesso `root` ao Shell;
- armazenamento disponível para a VM;
- conectividade com a Internet no host Proxmox e na VM;
- acesso à imagem cloud do Ubuntu;
- acesso ao repositório oficial do Zabbix;
- acesso de rede da VM ao Zabbix Server na porta configurada.

---

## Verificações após a instalação

Dentro da VM:

```bash
systemctl status zabbix-proxy --no-pager
```

Versão instalada:

```bash
zabbix_proxy --version
```

Teste de acesso TCP ao Zabbix Server:

```bash
timeout 5 bash -c '</dev/tcp/SEU_ZABBIX_SERVER/10051' && echo "CONEXÃO OK" || echo "CONEXÃO FALHOU"
```

Configuração principal:

```bash
grep -E '^(ProxyMode|Server|ServerPort|Hostname|DBName)=' /etc/zabbix/zabbix_proxy.conf
```

Banco SQLite:

```bash
sqlite3 /var/lib/zabbix/zabbix_proxy.db "SELECT name FROM sqlite_master WHERE type='table' LIMIT 5;"
```

---

## Atualização

O instalador trabalha com a linha **Zabbix 7.0 LTS**. Para atualizar uma instalação existente, prefira o mecanismo de atualização via `apt` usando o repositório oficial do Zabbix.

Exemplo:

```bash
apt update
apt install --only-upgrade zabbix-proxy-sqlite3 zabbix-sql-scripts
systemctl restart zabbix-proxy
```

Antes de atualizar, verifique a matriz de compatibilidade e o ciclo de vida oficial do Zabbix.

---

## Segurança

Para proxies em redes remotas, especialmente quando o Proxy se comunica pela Internet, recomenda-se configurar criptografia entre Proxy e Server, como TLS PSK ou certificados, em vez de deixar essa comunicação sem proteção adicional.

Não publique credenciais, PSKs, senhas ou tokens no GitHub.

---

## Estrutura do projeto

```text
zabbix-proxy-proxmox/
├── vm/
│   └── zabbix-proxy-vm.sh
├── docs/
│   └── COMPATIBILITY.md
├── LICENSE
└── README.md
```

---

## Relação com o Community Scripts

Este projeto utiliza o **Community Scripts Core** oficial para funções de VM no Proxmox, incluindo preflight, menus interativos, seleção de storage e criação da VM.

O projeto `conectaCore/zabbix-proxy-proxmox` é um repositório independente e não é o repositório oficial do Community Scripts nem do Zabbix.

- Community Scripts Core: https://github.com/community-scripts/core
- Proxmox VE Helper-Scripts: https://github.com/community-scripts/ProxmoxVE
- Zabbix: https://www.zabbix.com/
- Repositório oficial Zabbix: https://repo.zabbix.com/

---

## Licença

Este projeto é distribuído sob a **MIT License**. Consulte o arquivo [LICENSE](LICENSE).

As dependências e projetos de terceiros utilizados pelo instalador permanecem sujeitos às respectivas licenças.

---

## Autor

**ConectaCore Tecnologia**  
GitHub: https://github.com/conectaCore

---

## Referências oficiais

- Zabbix — Ciclo de vida e política de releases: https://www.zabbix.com/br/life_cycle_and_release_policy
- Zabbix 7.0 — Requisitos: https://www.zabbix.com/documentation/7.0/pt/manual/installation/requirements
- Zabbix 7.0 — Instalação por pacotes: https://www.zabbix.com/documentation/7.0/pt/manual/installation/install_from_packages
- Zabbix 7.0 — Configuração do Proxy: https://www.zabbix.com/documentation/7.0/en/manual/appendix/config/zabbix_proxy
- Ubuntu — Ciclo de releases: https://ubuntu.com/about/release-cycle
- Community Scripts Core: https://github.com/community-scripts/core
