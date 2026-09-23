#!/usr/bin/env bash

set -Eeuo pipefail

APP="Zabbix Proxy"
APP_TYPE="vm"
NSAPP="zabbix-proxy-vm"

COMMUNITY_SCRIPTS_CORE_URL="${COMMUNITY_SCRIPTS_CORE_URL:-https://raw.githubusercontent.com/community-scripts/core/main}"

source <(curl -fsSL "${COMMUNITY_SCRIPTS_CORE_URL}/pve/vm-core.func")

load_functions

ARCH="$(dpkg --print-architecture)"

GEN_MAC="02:$(openssl rand -hex 5 | tr '[:lower:]' '[:upper:]' | sed 's/\(..\)/\1:/g; s/:$//')"

var_arm64="yes"

var_os="ubuntu"
var_version="24.04"

OS_TYPE="ubuntu"
OS_VERSION="24.04"
OS_CODENAME="noble"
OS_DISPLAY="Ubuntu 24.04 LTS"

USE_CLOUD_INIT="yes"
export CLOUDINIT_ENABLE="yes"

CLOUDINIT_USER="root"
CLOUDINIT_NETWORK_MODE="dhcp"
CLOUDINIT_IP=""
CLOUDINIT_GW=""
CLOUDINIT_DNS="1.1.1.1 8.8.8.8"

DISK_SIZE="16G"

ZABBIX_BRANCH="7.0"
ZABBIX_SERVER=""
ZABBIX_SERVER_PORT="10051"
ZABBIX_PROXY_NAME="zabbix-proxy"
ZABBIX_PROXY_MODE="0"
ZABBIX_LISTEN_PORT="10051"

METHOD=""

header_info() {
echo
echo "========================================"
echo "          ZABBIX PROXY VM"
echo "========================================"
echo
}

get_image_url() {
local arch


arch="$(dpkg --print-architecture)"

case "$arch" in
    amd64|arm64)
        echo "https://cloud-images.ubuntu.com/${OS_CODENAME}/current/${OS_CODENAME}-server-cloudimg-${arch}.img"
        ;;
    *)
        msg_error "Arquitetura não suportada: ${arch}"
        exit 106
        ;;
esac


}

prompt_zabbix_settings() {


while true; do
    if ! vm_dialog inputbox \
        "ZABBIX SERVER" \
        "Informe o endereço IP ou DNS do Zabbix Server:" \
        10 70 "${ZABBIX_SERVER}"; then
        exit_script
    fi

    ZABBIX_SERVER="$VM_DIALOG_RESULT"

    if [[ -n "$ZABBIX_SERVER" ]]; then
        break
    fi

    vm_dialog msgbox \
        "CAMPO OBRIGATÓRIO" \
        "O endereço do Zabbix Server não pode ficar vazio." \
        8 58
done

if vm_dialog inputbox \
    "PROXY NAME" \
    "Informe o nome do Proxy exatamente como será cadastrado no Zabbix:" \
    10 70 "${HN}"; then

    ZABBIX_PROXY_NAME="$VM_DIALOG_RESULT"

    if [[ -z "$ZABBIX_PROXY_NAME" ]]; then
        ZABBIX_PROXY_NAME="$HN"
    fi
else
    exit_script
fi

if vm_dialog radiolist \
    "PROXY MODE" \
    "Escolha o modo de operação do Zabbix Proxy:" \
    12 72 2 \
    "0" "Active Proxy - o Proxy inicia conexão com o Server" ON \
    "1" "Passive Proxy - o Server inicia conexão com o Proxy" OFF; then

    ZABBIX_PROXY_MODE="$VM_DIALOG_RESULT"
else
    exit_script
fi

if vm_dialog inputbox \
    "ZABBIX SERVER PORT" \
    "Porta do Zabbix Server:" \
    10 70 "${ZABBIX_SERVER_PORT}"; then

    ZABBIX_SERVER_PORT="$VM_DIALOG_RESULT"

    [[ -z "$ZABBIX_SERVER_PORT" ]] && ZABBIX_SERVER_PORT="10051"
else
    exit_script
fi

if [[ "$ZABBIX_PROXY_MODE" == "1" ]]; then

    if vm_dialog inputbox \
        "PROXY LISTEN PORT" \
        "Porta na qual o Proxy Passive ficará escutando:" \
        10 70 "${ZABBIX_LISTEN_PORT}"; then

        ZABBIX_LISTEN_PORT="$VM_DIALOG_RESULT"

        [[ -z "$ZABBIX_LISTEN_PORT" ]] && ZABBIX_LISTEN_PORT="10051"
    else
        exit_script
    fi
fi

echo
echo "========================================"
echo "       ZABBIX PROXY CONFIGURATION"
echo "========================================"
echo
echo "Zabbix Server : ${ZABBIX_SERVER}"
echo "Server Port   : ${ZABBIX_SERVER_PORT}"
echo "Proxy Name    : ${ZABBIX_PROXY_NAME}"
echo "Proxy Mode    : ${ZABBIX_PROXY_MODE}"
echo "Listen Port   : ${ZABBIX_LISTEN_PORT}"


}

default_settings() {


vm_apply_machine_type "q35"

VMID="$(get_valid_nextid)"

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
VERBOSE="no"

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

if vm_confirm_advanced_settings \
    "Ready to configure the Zabbix Proxy settings?"; then

    echo
    echo "Configuração da VM confirmada."

else

    header_info

    echo -e "${ADVANCED}${BOLD}${RD}Using Advanced Settings${CL}"

    advanced_settings
    return
fi


}

header_info

vm_preflight

vm_start_script "Use Default Settings?" 10 58

prompt_zabbix_settings

vm_select_storage "$HN"

msg_info "Validando requisitos para criação da VM"

vm_ensure_virt_customize

msg_ok "Requisitos validados"

URL="$(get_image_url)"

CACHE_FILE="$(vm_image_cache_path "$URL")"

mkdir -p "$(dirname "$CACHE_FILE")"

msg_info "Baixando imagem ${OS_DISPLAY}"

msg_ok "${CL}${BL}${URL}${CL}"

vm_fetch_image 
"$URL" 
"$CACHE_FILE" 
--cache 
--min-bytes "$((100 * 1024 * 1024))"

msg_ok "Imagem Ubuntu disponível"

WORK_FILE="$(mktemp --suffix=.img)"

cp "$CACHE_FILE" "$WORK_FILE"

msg_info "Preparando imagem Ubuntu"

vm_prepare_cloud_image "$WORK_FILE" "$HN"

msg_ok "Imagem preparada"

INSTALL_CONFIG="$(mktemp)"

printf '%s\n' 
"ZABBIX_SERVER=$(printf '%q' "$ZABBIX_SERVER")" 
"ZABBIX_SERVER_PORT=$(printf '%q' "$ZABBIX_SERVER_PORT")" 
"ZABBIX_PROXY_NAME=$(printf '%q' "$ZABBIX_PROXY_NAME")" 
"ZABBIX_PROXY_MODE=$(printf '%q' "$ZABBIX_PROXY_MODE")" 
"ZABBIX_LISTEN_PORT=$(printf '%q' "$ZABBIX_LISTEN_PORT")" 
"ZABBIX_BRANCH=$(printf '%q' "$ZABBIX_BRANCH")" 
> "$INSTALL_CONFIG"

INSTALL_SCRIPT="$(mktemp)"

cat > "$INSTALL_SCRIPT" <<'ZABBIX_INSTALLER'
#!/usr/bin/env bash

set -Eeuo pipefail

LOG_FILE="/var/log/zabbix-proxy-install.log"
CONFIG_FILE="/etc/zabbix-proxy-install.conf"
DONE_FILE="/var/lib/zabbix-proxy-install.done"

exec > >(tee -a "$LOG_FILE") 2>&1

echo
echo "========================================"
echo "     ZABBIX PROXY FIRST BOOT INSTALL"
echo "========================================"
echo

if [[ -f "$DONE_FILE" ]]; then
echo "Instalação já concluída."
exit 0
fi

source "$CONFIG_FILE"

echo "Zabbix Server : ${ZABBIX_SERVER}"
echo "Server Port   : ${ZABBIX_SERVER_PORT}"
echo "Proxy Name    : ${ZABBIX_PROXY_NAME}"
echo "Proxy Mode    : ${ZABBIX_PROXY_MODE}"
echo

export DEBIAN_FRONTEND=noninteractive

echo "[1/7] Atualizando sistema..."
apt-get update

echo "[2/7] Instalando dependências..."
apt-get install -y 
ca-certificates 
wget 
sqlite3

echo "[3/7] Adicionando repositório oficial do Zabbix..."

REPO_DEB="/tmp/zabbix-release.deb"

wget -q 
"https://repo.zabbix.com/zabbix/${ZABBIX_BRANCH}/ubuntu/pool/main/z/zabbix-release/zabbix-release_latest+ubuntu24.04_all.deb" 
-O "$REPO_DEB"

dpkg -i "$REPO_DEB"

apt-get update

echo "[4/7] Instalando Zabbix Proxy..."

apt-get install -y 
zabbix-proxy-sqlite3 
zabbix-sql-scripts

echo "[5/7] Criando banco SQLite..."

DB_DIR="/var/lib/zabbix"
DB_FILE="${DB_DIR}/zabbix_proxy.db"

install -d 
-o zabbix 
-g zabbix 
"$DB_DIR"

if [[ ! -s "$DB_FILE" ]]; then


if [[ -f "/usr/share/zabbix-sql-scripts/sqlite3/proxy.sql" ]]; then

    sqlite3 "$DB_FILE" \
        < "/usr/share/zabbix-sql-scripts/sqlite3/proxy.sql"

elif [[ -f "/usr/share/doc/zabbix-proxy-sqlite3/schema.sql.gz" ]]; then

    zcat "/usr/share/doc/zabbix-proxy-sqlite3/schema.sql.gz" \
        | sqlite3 "$DB_FILE"

else

    echo "Schema SQLite do Zabbix Proxy não foi localizado."
    exit 1
fi


fi

chown zabbix:zabbix "$DB_FILE"

echo "[6/7] Configurando zabbix_proxy.conf..."

CONF="/etc/zabbix/zabbix_proxy.conf"

set_conf() {


local key="$1"
local value="$2"

local escaped="${value//\\/\\\\}"
escaped="${escaped//&/\\&}"
escaped="${escaped//|/\\|}"

if grep -qE "^[#[:space:]]*${key}=" "$CONF"; then

    sed -i -E \
        "s|^[#[:space:]]*${key}=.*|${key}=${escaped}|" \
        "$CONF"

else

    printf '%s=%s\n' "$key" "$value" >> "$CONF"
fi


}

set_conf "ProxyMode" "$ZABBIX_PROXY_MODE"
set_conf "Server" "$ZABBIX_SERVER"
set_conf "ServerPort" "$ZABBIX_SERVER_PORT"
set_conf "Hostname" "$ZABBIX_PROXY_NAME"
set_conf "DBName" "$DB_FILE"
set_conf "ListenPort" "$ZABBIX_LISTEN_PORT"

echo "[7/7] Iniciando Zabbix Proxy..."

systemctl daemon-reload

systemctl enable zabbix-proxy

systemctl restart zabbix-proxy

sleep 3

if systemctl is-active --quiet zabbix-proxy; then


echo
echo "Zabbix Proxy iniciou corretamente."


else


echo
echo "ERRO: Zabbix Proxy não iniciou."
echo
systemctl status zabbix-proxy --no-pager || true
echo
journalctl -u zabbix-proxy -n 50 --no-pager || true

exit 1


fi

mkdir -p "$(dirname "$DONE_FILE")"

date > "$DONE_FILE"

chmod 600 "$CONFIG_FILE" || true

rm -f "$REPO_DEB"

rm -f "$CONFIG_FILE"

systemctl disable zabbix-proxy-firstboot.service || true

echo
echo "========================================"
echo "      ZABBIX PROXY INSTALADO"
echo "========================================"
echo
echo "Proxy Name : ${ZABBIX_PROXY_NAME}"
echo "Server     : ${ZABBIX_SERVER}"
echo "Mode       : ${ZABBIX_PROXY_MODE}"
echo
echo "Log:"
echo "  ${LOG_FILE}"
echo
ZABBIX_INSTALLER

chmod 700 "$INSTALL_SCRIPT"

msg_info "Inserindo instalador de primeiro boot"

virt-customize -q 
-a "$WORK_FILE" 
--upload "$INSTALL_SCRIPT":/root/install-zabbix-proxy.sh 
--upload "$INSTALL_CONFIG":/etc/zabbix-proxy-install.conf 
--run-command "chmod 700 /root/install-zabbix-proxy.sh" 
--run-command "cat > /etc/systemd/system/zabbix-proxy-firstboot.service <<'EOF'
[Unit]
Description=Install Zabbix Proxy on first boot
After=network-online.target cloud-final.service
Wants=network-online.target
ConditionPathExists=/root/install-zabbix-proxy.sh

[Service]
Type=oneshot
ExecStart=/root/install-zabbix-proxy.sh
TimeoutStartSec=0
RemainAfterExit=yes

[Install]
WantedBy=multi-user.target
EOF" 
--run-command "systemctl enable zabbix-proxy-firstboot.service" 
>/dev/null

msg_ok "Instalador de primeiro boot configurado"

rm -f "$INSTALL_SCRIPT"
rm -f "$INSTALL_CONFIG"

msg_info "Ajustando tamanho da imagem para ${DISK_SIZE}"

qemu-img resize "$WORK_FILE" "$DISK_SIZE" >/dev/null 2>&1

msg_ok "Disco ajustado para ${DISK_SIZE}"

msg_info "Criando shell da VM"

qm create "$VMID" 
-agent 1 
${MACHINE} 
-tablet 0 
-localtime 1 
-bios ovmf 
${CPU_TYPE} 
-cores "$CORE_COUNT" 
-memory "$RAM_SIZE" 
-name "$HN" 
-tags "zabbix-proxy" 
-net0 "virtio,bridge=${BRG},macaddr=${MAC}${VLAN}${MTU}" 
-onboot 1 
-ostype l26 
-scsihw virtio-scsi-pci 
>/dev/null

msg_ok "Shell da VM criado"

msg_info "Importando disco para ${STORAGE}"

if qm disk import --help >/dev/null 2>&1; then


IMPORT_CMD=(qm disk import)


else


IMPORT_CMD=(qm importdisk)


fi

IMPORT_OUT="$(
"${IMPORT_CMD[@]}" 
"$VMID" 
"$WORK_FILE" 
"$STORAGE" 
${DISK_IMPORT_FORMAT:+--format "$DISK_IMPORT_FORMAT"} 
2>&1 || true
)"

DISK_REF_IMPORTED="$(
printf '%s\n' "$IMPORT_OUT" |
sed -n "s/.*successfully imported disk '\([^']*\)'.*/\1/p" |
tr -d '\r"'
)"

if [[ -z "$DISK_REF_IMPORTED" ]]; then


DISK_REF_IMPORTED="$(
    pvesm list "$STORAGE" 2>/dev/null |
        awk -v id="$VMID" '$0 ~ ("vm-" id "-disk-") {print $1 ":" $5}' |
        sort |
        tail -n1
)"


fi

if [[ -z "$DISK_REF_IMPORTED" ]]; then


msg_error "Não foi possível determinar o disco importado."

echo "$IMPORT_OUT"

exit 226


fi

msg_ok "Disco importado"

rm -f "$WORK_FILE"

msg_info "Anexando EFI e disco raiz"

qm set "$VMID" 
--efidisk0 "${STORAGE}:0,efitype=4m" 
--scsi0 "${DISK_REF_IMPORTED},${DISK_CACHE}${THIN%,}" 
--boot "order=scsi0" 
--serial0 socket 
>/dev/null

qm set "$VMID" --agent enabled=1 >/dev/null

msg_ok "EFI e disco raiz configurados"

VM_DESCRIPTION="<div align='center'>

<h2>Zabbix Proxy</h2>
<p>Ubuntu 24.04 LTS</p>
<p>Zabbix Proxy ${ZABBIX_BRANCH} + SQLite</p>
<p><a href='https://github.com/conectaCore/zabbix-proxy-proxmox'>conectaCore/zabbix-proxy-proxmox</a></p>
</div>"

qm set "$VMID" --description "$VM_DESCRIPTION" >/dev/null

msg_info "Configurando Cloud-Init"

if vm_provision "$VMID"; then


msg_ok "Cloud-Init configurado"


else


msg_warn "A VM foi criada, mas o Cloud-Init não pôde ser configurado."


fi

if [[ "$START_VM" == "yes" ]]; then


msg_info "Iniciando Zabbix Proxy VM"

$STD qm start "$VMID"

msg_ok "VM iniciada"


fi

VM_IP=""

if [[ "$START_VM" == "yes" ]]; then


set +e

for _ in {1..15}; do

    VM_IP="$(
        qm guest cmd "$VMID" network-get-interfaces 2>/dev/null |
            jq -r '
                .[]
                | select(.name != "lo")
                | ."ip-addresses"[]?
                | select(."ip-address-type" == "ipv4")
                | ."ip-address"
            ' 2>/dev/null |
            grep -v "^127\." |
            head -n1
    )"

    [[ -n "$VM_IP" ]] && break

    sleep 3
done

set -e


fi

echo
echo "========================================"
echo "      ZABBIX PROXY VM CRIADA"
echo "========================================"
echo
echo "VM ID         : ${VMID}"
echo "Hostname      : ${HN}"
echo "OS            : ${OS_DISPLAY}"
echo "CPU           : ${CORE_COUNT}"
echo "RAM           : ${RAM_SIZE} MiB"
echo "Disco         : ${DISK_SIZE}"
echo "Bridge        : ${BRG}"
echo "Zabbix Server : ${ZABBIX_SERVER}"
echo "Proxy Name    : ${ZABBIX_PROXY_NAME}"
echo "Proxy Mode    : ${ZABBIX_PROXY_MODE}"

if [[ -n "$VM_IP" ]]; then
echo "IP Address    : ${VM_IP}"
fi

echo
echo "A instalação do Zabbix Proxy será executada no primeiro boot."
echo
echo "Log dentro da VM:"
echo "  /var/log/zabbix-proxy-install.log"
echo
echo "Nenhum Zabbix Server ou frontend será instalado."
echo
