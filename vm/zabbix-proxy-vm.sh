#!/usr/bin/env bash

set -Eeuo pipefail

APP="Zabbix Proxy"
APP_TYPE="vm"
NSAPP="zabbix-proxy-vm"

COMMUNITY_SCRIPTS_URL="${COMMUNITY_SCRIPTS_URL:-https://raw.githubusercontent.com/community-scripts/ProxmoxVE/main}"
COMMUNITY_SCRIPTS_CORE_URL="${COMMUNITY_SCRIPTS_CORE_URL:-https://raw.githubusercontent.com/community-scripts/core/main}"

source <(curl -fsSL "${COMMUNITY_SCRIPTS_CORE_URL}/pve/vm-core.func")

load_functions

ARCH="$(dpkg --print-architecture)"

GEN_MAC="02:$(openssl rand -hex 5 | tr '[:lower:]' '[:upper:]' | sed 's/\(..\)/\1:/g; s/:$//')"

var_arm64="yes"

OS_TYPE="ubuntu"
OS_VERSION="24.04"
OS_CODENAME="noble"
OS_DISPLAY="Ubuntu 24.04 LTS"

USE_CLOUD_INIT="yes"
CLOUDINIT_REQUIRED="1"

DISK_SIZE="16G"
METHOD=""

ZABBIX_BRANCH="7.0"
ZABBIX_SERVER=""
ZABBIX_SERVER_PORT="10051"
ZABBIX_PROXY_NAME="zabbix-proxy"
ZABBIX_PROXY_MODE="0"
ZABBIX_LISTEN_PORT="10051"

header_info() {
clear
echo
echo "========================================"
echo "          ZABBIX PROXY VM"
echo "========================================"
echo
}

select_cloud_init() {
vm_prompt_cloud_init "root"


if [[ "${USE_CLOUD_INIT:-no}" != "yes" ]]; then
    msg_error "Ubuntu 24.04 usa uma Cloud Image e precisa de Cloud-Init."
    msg_error "O Cloud-Init será habilitado automaticamente."
    USE_CLOUD_INIT="yes"
    export CLOUDINIT_ENABLE="yes"
fi


}

default_settings() {


vm_apply_machine_type "q35"

select_cloud_init

VMID="$(get_valid_nextid)"

if [[ "$ARCH" == "arm64" ]]; then
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

select_cloud_init

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

if vm_confirm_advanced_settings "Ready to configure the Zabbix Proxy?"; then
    echo -e "${CREATING}${BOLD}${DGN}Configuring a Zabbix Proxy VM using the above advanced settings${CL}"
else
    header_info
    echo -e "${ADVANCED}${BOLD}${RD}Using Advanced Settings${CL}"
    advanced_settings
fi


}

configure_zabbix() {


while true; do

    ZABBIX_SERVER="$(whiptail \
        --backtitle "Proxmox VE Helper Scripts" \
        --title "ZABBIX SERVER" \
        --inputbox \
        "Informe o IP ou DNS do Zabbix Server." \
        9 70 \
        "${ZABBIX_SERVER}" \
        3>&1 1>&2 2>&3)" || exit_script

    if [[ -n "$ZABBIX_SERVER" ]]; then
        break
    fi

    whiptail \
        --backtitle "Proxmox VE Helper Scripts" \
        --title "CAMPO OBRIGATÓRIO" \
        --msgbox \
        "O endereço do Zabbix Server não pode ficar vazio." \
        8 58
done

ZABBIX_SERVER_PORT="$(whiptail \
    --backtitle "Proxmox VE Helper Scripts" \
    --title "ZABBIX SERVER PORT" \
    --inputbox \
    "Porta do Zabbix Server." \
    8 58 \
    "${ZABBIX_SERVER_PORT}" \
    3>&1 1>&2 2>&3)" || exit_script

ZABBIX_SERVER_PORT="${ZABBIX_SERVER_PORT:-10051}"

ZABBIX_PROXY_NAME="$(whiptail \
    --backtitle "Proxmox VE Helper Scripts" \
    --title "PROXY NAME" \
    --inputbox \
    "Nome do Zabbix Proxy.\n\nUse exatamente o mesmo nome que será cadastrado no Zabbix Server." \
    10 70 \
    "${HN}" \
    3>&1 1>&2 2>&3)" || exit_script

ZABBIX_PROXY_NAME="${ZABBIX_PROXY_NAME:-$HN}"

ZABBIX_PROXY_MODE="$(whiptail \
    --backtitle "Proxmox VE Helper Scripts" \
    --title "PROXY MODE" \
    --radiolist \
    "Escolha o modo de operação do Proxy." \
    12 72 2 \
    "0" "Active Proxy - conecta ao Zabbix Server" ON \
    "1" "Passive Proxy - Zabbix Server conecta ao Proxy" OFF \
    3>&1 1>&2 2>&3)" || exit_script

if [[ "$ZABBIX_PROXY_MODE" == "1" ]]; then

    ZABBIX_LISTEN_PORT="$(whiptail \
        --backtitle "Proxmox VE Helper Scripts" \
        --title "PROXY LISTEN PORT" \
        --inputbox \
        "Porta TCP em que o Proxy Passive ficará escutando." \
        8 58 \
        "${ZABBIX_LISTEN_PORT}" \
        3>&1 1>&2 2>&3)" || exit_script

    ZABBIX_LISTEN_PORT="${ZABBIX_LISTEN_PORT:-10051}"
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
echo


}

get_image_url() {
if [[ "$ARCH" == "arm64" ]]; then
echo "https://cloud-images.ubuntu.com/${OS_CODENAME}/current/${OS_CODENAME}-server-cloudimg-arm64.img"
else
echo "https://cloud-images.ubuntu.com/${OS_CODENAME}/current/${OS_CODENAME}-server-cloudimg-amd64.img"
fi
}

create_installer_config() {


INSTALL_CONFIG="$(mktemp)"

{
    printf 'ZABBIX_BRANCH=%q\n' "$ZABBIX_BRANCH"
    printf 'ZABBIX_SERVER=%q\n' "$ZABBIX_SERVER"
    printf 'ZABBIX_SERVER_PORT=%q\n' "$ZABBIX_SERVER_PORT"
    printf 'ZABBIX_PROXY_NAME=%q\n' "$ZABBIX_PROXY_NAME"
    printf 'ZABBIX_PROXY_MODE=%q\n' "$ZABBIX_PROXY_MODE"
    printf 'ZABBIX_LISTEN_PORT=%q\n' "$ZABBIX_LISTEN_PORT"
} > "$INSTALL_CONFIG"


}

create_firstboot_installer() {


INSTALL_SCRIPT="$(mktemp)"

cat > "$INSTALL_SCRIPT" <<'ZABBIX_INSTALLER'


#!/usr/bin/env bash

set -Eeuo pipefail

LOG_FILE="/var/log/zabbix-proxy-install.log"
CONFIG_FILE="/etc/zabbix-proxy-install.conf"
DONE_FILE="/var/lib/zabbix/.zabbix-proxy-installed"

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

export DEBIAN_FRONTEND=noninteractive

echo "[1/6] Aguardando rede..."

for _ in {1..30}; do
if getent hosts repo.zabbix.com >/dev/null 2>&1; then
break
fi
sleep 3
done

echo "[2/6] Atualizando Ubuntu..."

apt-get update

echo "[3/6] Instalando dependências..."

apt-get install -y 
ca-certificates 
wget

echo "[4/6] Adicionando repositório oficial do Zabbix ${ZABBIX_BRANCH}..."

REPO_DEB="/tmp/zabbix-release_latest+ubuntu24.04_all.deb"

wget -q 
"https://repo.zabbix.com/zabbix/${ZABBIX_BRANCH}/ubuntu/pool/main/z/zabbix-release/zabbix-release_latest+ubuntu24.04_all.deb" 
-O "$REPO_DEB"

dpkg -i "$REPO_DEB"

apt-get update

echo "[5/6] Instalando Zabbix Proxy SQLite..."

apt-get install -y 
zabbix-proxy-sqlite3

echo "[6/6] Configurando Zabbix Proxy..."

ZABBIX_CONF="/etc/zabbix/zabbix_proxy.conf"

set_config() {


local key="$1"
local value="$2"

if grep -qE "^[#[:space:]]*${key}=" "$ZABBIX_CONF"; then
    sed -i -E "s|^[#[:space:]]*${key}=.*|${key}=${value}|" "$ZABBIX_CONF"
else
    printf '%s=%s\n' "$key" "$value" >> "$ZABBIX_CONF"
fi


}

set_config "ProxyMode" "$ZABBIX_PROXY_MODE"
set_config "Server" "$ZABBIX_SERVER"
set_config "ServerPort" "$ZABBIX_SERVER_PORT"
set_config "Hostname" "$ZABBIX_PROXY_NAME"
set_config "DBName" "/var/lib/zabbix/zabbix_proxy.db"

if [[ "$ZABBIX_PROXY_MODE" == "1" ]]; then
set_config "ListenPort" "$ZABBIX_LISTEN_PORT"
fi

install -d 
-o zabbix 
-g zabbix 
/var/lib/zabbix

echo
echo "Iniciando serviço zabbix-proxy..."

systemctl daemon-reload
systemctl enable zabbix-proxy
systemctl restart zabbix-proxy

sleep 5

if systemctl is-active --quiet zabbix-proxy; then
echo
echo "========================================"
echo "      ZABBIX PROXY INSTALADO"
echo "========================================"
echo
echo "Proxy Name : ${ZABBIX_PROXY_NAME}"
echo "Server     : ${ZABBIX_SERVER}"
echo "Mode       : ${ZABBIX_PROXY_MODE}"
echo
else
echo
echo "========================================"
echo "    ERRO AO INICIAR ZABBIX PROXY"
echo "========================================"
echo


systemctl status zabbix-proxy --no-pager || true
echo
journalctl -u zabbix-proxy -n 50 --no-pager || true

exit 1


fi

touch "$DONE_FILE"

rm -f "$REPO_DEB"
rm -f "$CONFIG_FILE"
rm -f /root/install-zabbix-proxy.sh

systemctl disable zabbix-proxy-firstboot.service || true

echo
echo "Log de instalação:"
echo "  ${LOG_FILE}"
echo

ZABBIX_INSTALLER


chmod 700 "$INSTALL_SCRIPT"


}

header_info

vm_preflight

vm_start_script "Use Default Settings?" 12 60

configure_zabbix

vm_select_storage "$HN"

msg_info "Preparing the Ubuntu 24.04 image"

URL="$(get_image_url)"

CACHE_DIR="/var/lib/vz/template/cache"
CACHE_FILE="${CACHE_DIR}/$(basename "$URL")"

mkdir -p "$CACHE_DIR"

msg_ok "${CL}${BL}${URL}${CL}"

MIN_IMAGE_BYTES=$((100 * 1024 * 1024))

vm_fetch_image "$URL" "$CACHE_FILE" --cache --min-bytes "$MIN_IMAGE_BYTES"

msg_ok "Ubuntu 24.04 image available"

vm_ensure_virt_customize

create_installer_config
create_firstboot_installer

WORK_FILE="$(mktemp --suffix=.qcow2)"

cp "$CACHE_FILE" "$WORK_FILE"

msg_info "Preparing Ubuntu image"

vm_prepare_cloud_image "$WORK_FILE" "$HN"

msg_ok "Ubuntu image prepared"

msg_info "Adding Zabbix Proxy first-boot installer"

virt-customize 
-q 
-a "$WORK_FILE" 
--upload "$INSTALL_SCRIPT":/root/install-zabbix-proxy.sh 
--upload "$INSTALL_CONFIG":/etc/zabbix-proxy-install.conf 
--run-command "chmod 700 /root/install-zabbix-proxy.sh" 
>/dev/null

virt-customize 
-q 
-a "$WORK_FILE" 
--run-command 'cat > /etc/systemd/system/zabbix-proxy-firstboot.service << "EOF"
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
EOF
systemctl enable zabbix-proxy-firstboot.service' 
>/dev/null

msg_ok "Zabbix Proxy first-boot installer configured"

rm -f "$INSTALL_SCRIPT"
rm -f "$INSTALL_CONFIG"

msg_info "Resizing image to ${DISK_SIZE}"

qemu-img resize "$WORK_FILE" "$DISK_SIZE" >/dev/null 2>&1

msg_ok "Image resized"

STORAGE_TYPE="$(pvesm status -storage "$STORAGE" | awk 'NR>1 {print $2}')"

case "$STORAGE_TYPE" in
nfs|dir|cifs)
DISK_EXT=".qcow2"
DISK_REF="$VMID/"
DISK_IMPORT_FORMAT="qcow2"
THIN=""
;;
btrfs)
DISK_EXT=".raw"
DISK_REF="$VMID/"
DISK_IMPORT_FORMAT="raw"
THIN=""
;;
*)
DISK_EXT=""
DISK_REF=""
DISK_IMPORT_FORMAT="raw"
THIN="discard=on,ssd=1,"
;;
esac

msg_info "Creating VM shell"

QM_CREATE_ARGS=(
"$VMID"
-agent 1
-tablet 0
-localtime 1
-bios ovmf
-cores "$CORE_COUNT"
-memory "$RAM_SIZE"
-name "$HN"
-tags "zabbix-proxy"
-net0 "virtio,bridge=${BRG},macaddr=${MAC}${VLAN}${MTU}"
-onboot 1
-ostype l26
-scsihw virtio-scsi-pci
)

if [[ -n "${MACHINE:-}" ]]; then
MACHINE_ARGS=()
read -r -a MACHINE_ARGS <<< "${MACHINE}"
QM_CREATE_ARGS+=("${MACHINE_ARGS[@]}")
fi

if [[ -n "${CPU_TYPE:-}" ]]; then
CPU_ARGS=()
read -r -a CPU_ARGS <<< "${CPU_TYPE}"
QM_CREATE_ARGS+=("${CPU_ARGS[@]}")
fi

qm create "${QM_CREATE_ARGS[@]}"

msg_ok "Created VM shell"

vm_mark_created

msg_info "Importing disk into ${STORAGE}"

IMPORT_CMD=()

if qm disk import --help >/dev/null 2>&1; then
IMPORT_CMD=(qm disk import)
else
IMPORT_CMD=(qm importdisk)
fi

IMPORT_ARGS=(
"$VMID"
"$WORK_FILE"
"$STORAGE"
)

if [[ -n "${DISK_IMPORT_FORMAT:-}" ]]; then
IMPORT_ARGS+=(--format "$DISK_IMPORT_FORMAT")
fi

IMPORT_OUT="$(
"${IMPORT_CMD[@]}" "${IMPORT_ARGS[@]}" 2>&1
)"

DISK_REF_IMPORTED="$(
printf '%s\n' "$IMPORT_OUT" |
sed -n "s/.*successfully imported disk '\([^']\+\)'.*/\1/p" |
tr -d "\r"'"
)"

if [[ -z "$DISK_REF_IMPORTED" ]]; then
DISK_REF_IMPORTED="$(
pvesm list "$STORAGE" 2>/dev/null |
awk -v id="$VMID" '$5 ~ ("vm-" id "-disk-") {print $1 ":" $5}' |
sort |
tail -n1
)"
fi

if [[ -z "$DISK_REF_IMPORTED" ]]; then
msg_error "Não foi possível determinar o disco importado."
echo "$IMPORT_OUT"
exit 226
fi

msg_ok "Imported disk ${DISK_REF_IMPORTED}"

rm -f "$WORK_FILE"

msg_info "Attaching EFI and root disk"

qm set "$VMID" --efidisk0 "${STORAGE}:0,efitype=4m"
qm set "$VMID" --scsi0 "${DISK_REF_IMPORTED},${DISK_CACHE:-}${THIN%,}"
qm set "$VMID" --boot order=scsi0
qm set "$VMID" --serial0 socket
qm set "$VMID" --agent enabled=1

msg_ok "EFI, disk and Guest Agent configured"

vm_provision "$VMID"

msg_ok "Cloud-Init configured"

qm set "$VMID" --description 
"<div align='center'>

<h2>Zabbix Proxy</h2>
<p>Ubuntu 24.04 LTS</p>
<p>Zabbix Proxy ${ZABBIX_BRANCH} + SQLite</p>
<p>Created by conectaCore/zabbix-proxy-proxmox</p>
</div>"

if [[ "$START_VM" == "yes" ]]; then


msg_info "Starting Zabbix Proxy VM"

qm start "$VMID"

msg_ok "Started Zabbix Proxy VM"


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
      

