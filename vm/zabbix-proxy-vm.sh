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
echo "=============
