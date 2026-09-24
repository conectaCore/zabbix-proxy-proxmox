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
export CLOUDINIT_ENABLE="yes"
CLOUDINIT_NETWORK_MODE="dhcp"
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
    _cs_clear
    echo
    echo "========================================"
    echo "          ZABBIX PROXY VM"
    echo "========================================"
    echo
}

get_image_url() {
    local arch="$(vm_arch)"
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

validate_zabbix_inputs() {
    [[ "$ZABBIX_SERVER" =~ ^[A-Za-z0-9._:/-]+$ ]] || {
        msg_error "Endereço do Zabbix Server inválido: ${ZABBIX_SERVER}"
        exit 1
    }
    [[ "$ZABBIX_SERVER_PORT" =~ ^[0-9]+$ ]] && ((ZABBIX_SERVER_PORT >= 1 && ZABBIX_SERVER_PORT <= 65535)) || {
        msg_error "Porta do Zabbix Server inválida: ${ZABBIX_SERVER_PORT}"
        exit 1
    }
    [[ -n "$ZABBIX_PROXY_NAME" ]] || {
        msg_error "Nome do Proxy não pode ficar vazio."
        exit 1
    }
    [[ "$ZABBIX_PROXY_MODE" == "0" || "$ZABBIX_PROXY_MODE" == "1" ]] || {
        msg_error "ProxyMode inválido: ${ZABBIX_PROXY_MODE}"
        exit 1
    }
}

prompt_zabbix_settings() {
    while true; do
        ZABBIX_SERVER="$(whiptail \
            --backtitle "Proxmox VE Helper Scripts" \
            --title "ZABBIX SERVER" \
            --inputbox \
            "Informe o IP ou DNS do Zabbix Server." \
            9 70 \
            "${ZABBIX_SERVER}" \
            --cancel-button Exit-Script \
            3>&1 1>&2 2>&3)" || exit_script

        if [[ -n "$ZABBIX_SERVER" ]]; then
            break
        fi

        whiptail \
            --backtitle "Proxmox VE Helper Scripts" \
            --title "CAMPO OBRIGATÓRIO" \
            --msgbox "O endereço do Zabbix Server não pode ficar vazio." 8 58
    done

    ZABBIX_SERVER_PORT="$(whiptail \
        --backtitle "Proxmox VE Helper Scripts" \
        --title "ZABBIX SERVER PORT" \
        --inputbox "Porta do Zabbix Server." \
        8 58 \
        "${ZABBIX_SERVER_PORT}" \
        --cancel-button Exit-Script \
        3>&1 1>&2 2>&3)" || exit_script

    ZABBIX_SERVER_PORT="${ZABBIX_SERVER_PORT:-10051}"

    ZABBIX_PROXY_NAME="$(whiptail \
        --backtitle "Proxmox VE Helper Scripts" \
        --title "PROXY NAME" \
        --inputbox \
        "Nome do Zabbix Proxy.\n\nUse exatamente o mesmo nome que será cadastrado no Zabbix Server." \
        10 72 \
        "${ZABBIX_PROXY_NAME:-$HN}" \
        --cancel-button Exit-Script \
        3>&1 1>&2 2>&3)" || exit_script

    ZABBIX_PROXY_NAME="${ZABBIX_PROXY_NAME:-$HN}"

    ZABBIX_PROXY_MODE="$(whiptail \
        --backtitle "Proxmox VE Helper Scripts" \
        --title "PROXY MODE" \
        --radiolist \
        "Escolha o modo de operação do Zabbix Proxy." \
        12 78 2 \
        "0" "Active - Proxy conecta ao Server" ON \
        "1" "Passive - Server conecta ao Proxy" OFF \
        --cancel-button Exit-Script \
        3>&1 1>&2 2>&3)" || exit_script

    if [[ "$ZABBIX_PROXY_MODE" == "1" ]]; then
        ZABBIX_LISTEN_PORT="$(whiptail \
            --backtitle "Proxmox VE Helper Scripts" \
            --title "PROXY LISTEN PORT" \
            --inputbox \
            "Porta TCP em que o Proxy Passive irá escutar." \
            8 64 \
            "${ZABBIX_LISTEN_PORT}" \
            --cancel-button Exit-Script \
            3>&1 1>&2 2>&3)" || exit_script
        ZABBIX_LISTEN_PORT="${ZABBIX_LISTEN_PORT:-10051}"
    fi

    validate_zabbix_inputs

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

select_cloud_init() {
    vm_prompt_cloud_init "root"
    if [[ "$OS_TYPE" == "ubuntu" && "${USE_CLOUD_INIT:-no}" != "yes" ]]; then
        USE_CLOUD_INIT="yes"
        export CLOUDINIT_ENABLE="yes"
        msg_warn "Ubuntu requer Cloud-Init; habilitando automaticamente."
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

    if vm_confirm_advanced_settings "Ready to create a Zabbix Proxy VM?"; then
        echo -e "${CREATING}${BOLD}${DGN}Creating a Zabbix Proxy VM using the above advanced settings${CL}"
    else
        header_info
        echo -e "${ADVANCED}${BOLD}${RD}Using Advanced Settings${CL}"
        advanced_settings
    fi
}

create_installer_files() {
    INSTALL_DIR="$(mktemp -d)"
    INSTALL_CONFIG="${INSTALL_DIR}/zabbix-proxy-install.conf"
    INSTALL_SCRIPT="${INSTALL_DIR}/install-zabbix-proxy.sh"
    SERVICE_FILE="${INSTALL_DIR}/zabbix-proxy-firstboot.service"

    {
        printf 'ZABBIX_BRANCH=%q\n' "$ZABBIX_BRANCH"
        printf 'ZABBIX_SERVER=%q\n' "$ZABBIX_SERVER"
        printf 'ZABBIX_SERVER_PORT=%q\n' "$ZABBIX_SERVER_PORT"
        printf 'ZABBIX_PROXY_NAME=%q\n' "$ZABBIX_PROXY_NAME"
        printf 'ZABBIX_PROXY_MODE=%q\n' "$ZABBIX_PROXY_MODE"
        printf 'ZABBIX_LISTEN_PORT=%q\n' "$ZABBIX_LISTEN_PORT"
    } > "$INSTALL_CONFIG"

    cat > "$INSTALL_SCRIPT" <<'ZABBIX_INSTALLER'
#!/usr/bin/env bash
set -Eeuo pipefail

LOG_FILE="/var/log/zabbix-proxy-install.log"
CONFIG_FILE="/etc/zabbix-proxy-install.conf"
DONE_FILE="/var/lib/zabbix/.zabbix-proxy-installed"

exec > >(tee -a "$LOG_FILE") 2>&1

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

for _ in {1..60}; do
    if getent hosts repo.zabbix.com >/dev/null 2>&1; then
        break
    fi
    sleep 2
done

apt-get update
apt-get install -y ca-certificates wget sqlite3

REPO_DEB="/tmp/zabbix-release_latest+ubuntu24.04_all.deb"
wget -q "https://repo.zabbix.com/zabbix/${ZABBIX_BRANCH}/ubuntu/pool/main/z/zabbix-release/zabbix-release_latest+ubuntu24.04_all.deb" -O "$REPO_DEB"
dpkg -i "$REPO_DEB"
apt-get update

systemctl stop zabbix-proxy 2>/dev/null || true
apt-get install -y zabbix-proxy-sqlite3 zabbix-sql-scripts
systemctl stop zabbix-proxy 2>/dev/null || true

DB_DIR="/var/lib/zabbix"
DB_FILE="${DB_DIR}/zabbix_proxy.db"
install -d -o zabbix -g zabbix "$DB_DIR"

if [[ ! -s "$DB_FILE" ]]; then
    SCHEMA="/usr/share/zabbix-sql-scripts/sqlite3/proxy.sql"
    if [[ ! -f "$SCHEMA" ]]; then
        echo "Schema SQLite não encontrado: $SCHEMA"
        exit 1
    fi
    sqlite3 "$DB_FILE" < "$SCHEMA"
fi

chown zabbix:zabbix "$DB_FILE"

CONF="/etc/zabbix/zabbix_proxy.conf"

set_conf() {
    local key="$1"
    local value="$2"
    if grep -qE "^[[:space:]]*#?[[:space:]]*${key}=" "$CONF"; then
        sed -i -E "s|^[[:space:]]*#?[[:space:]]*${key}=.*|${key}=${value}|" "$CONF"
    else
        printf '%s=%s\n' "$key" "$value" >> "$CONF"
    fi
}

set_conf "ProxyMode" "$ZABBIX_PROXY_MODE"
set_conf "Server" "$ZABBIX_SERVER"
set_conf "ServerPort" "$ZABBIX_SERVER_PORT"
set_conf "Hostname" "$ZABBIX_PROXY_NAME"
set_conf "DBName" "$DB_FILE"

if [[ "$ZABBIX_PROXY_MODE" == "1" ]]; then
    set_conf "ListenPort" "$ZABBIX_LISTEN_PORT"
fi

systemctl daemon-reload
systemctl enable zabbix-proxy
systemctl restart zabbix-proxy
sleep 5

if ! systemctl is-active --quiet zabbix-proxy; then
    echo "Zabbix Proxy não iniciou."
    systemctl status zabbix-proxy --no-pager || true
    journalctl -u zabbix-proxy -n 50 --no-pager || true
    exit 1
fi

install -d -m 0755 /var/lib/zabbix
touch "$DONE_FILE"
chown zabbix:zabbix "$DONE_FILE"
rm -f "$REPO_DEB" "$CONFIG_FILE" /root/install-zabbix-proxy.sh
systemctl disable zabbix-proxy-firstboot.service >/dev/null 2>&1 || true

echo
echo "========================================"
echo "      ZABBIX PROXY INSTALADO"
echo "========================================"
echo
echo "Proxy Name : ${ZABBIX_PROXY_NAME}"
echo "Server     : ${ZABBIX_SERVER}"
echo "Mode       : ${ZABBIX_PROXY_MODE}"
echo "Log        : ${LOG_FILE}"
ZABBIX_INSTALLER

    chmod 700 "$INSTALL_SCRIPT"

    cat > "$SERVICE_FILE" <<'SYSTEMD_SERVICE'
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
SYSTEMD_SERVICE
}

cleanup_install_files() {
    [[ -n "${INSTALL_DIR:-}" && -d "$INSTALL_DIR" ]] && rm -rf "$INSTALL_DIR"
}

header_info
vm_preflight
vm_start_script "Use Default Settings?" 12 60
prompt_zabbix_settings
vm_select_storage "$HN"
vm_ensure_virt_customize

URL="$(get_image_url)"
CACHE_FILE="$(vm_image_cache_path "$URL")"
mkdir -p "$(dirname "$CACHE_FILE")"

msg_info "Retrieving the URL for the ${OS_DISPLAY} Disk Image"
msg_ok "${CL}${BL}${URL}${CL}"
vm_fetch_image "$URL" "$CACHE_FILE" --cache --min-bytes "$((100 * 1024 * 1024))" || exit 115
msg_ok "Ubuntu image available"

STORAGE_TYPE="$(pvesm status -storage "$STORAGE" | awk 'NR>1 {print $2}')"
vm_apply_storage_layout "$STORAGE_TYPE"

WORK_FILE="$(mktemp --suffix=.qcow2)"
cp "$CACHE_FILE" "$WORK_FILE"

msg_info "Preparing ${OS_DISPLAY} image"
vm_prepare_cloud_image "$WORK_FILE" "$HN"
msg_ok "Image prepared"

msg_info "Resizing image to ${DISK_SIZE}"
qemu-img resize "$WORK_FILE" "${DISK_SIZE}" >/dev/null 2>&1
msg_ok "Image resized"

create_installer_files

msg_info "Adding Zabbix Proxy first-boot installer"
VC_ARGS=(-q -a "$WORK_FILE" \
    --upload "$INSTALL_SCRIPT:/root/install-zabbix-proxy.sh" \
    --upload "$INSTALL_CONFIG:/etc/zabbix-proxy-install.conf" \
    --upload "$SERVICE_FILE:/etc/systemd/system/zabbix-proxy-firstboot.service" \
    --run-command "chmod 700 /root/install-zabbix-proxy.sh" \
    --run-command "mkdir -p /etc/systemd/system/multi-user.target.wants" \
    --run-command "ln -sf ../zabbix-proxy-firstboot.service /etc/systemd/system/multi-user.target.wants/zabbix-proxy-firstboot.service")
virt-customize "${VC_ARGS[@]}" >/dev/null
msg_ok "First-boot installer configured"

cleanup_install_files

msg_info "Creating Zabbix Proxy VM shell"
QM_CREATE_ARGS=("$VMID" -agent 1 -tablet 0 -localtime 1 -bios ovmf -cores "$CORE_COUNT" -memory "$RAM_SIZE" -name "$HN" -tags community-script,zabbix-proxy -net0 "virtio,bridge=$BRG,macaddr=$MAC$VLAN$MTU" -onboot 1 -ostype l26 -scsihw virtio-scsi-pci)

if [[ -n "${MACHINE:-}" ]]; then
    read -r -a MACHINE_ARGS <<< "${MACHINE}"
    QM_CREATE_ARGS+=("${MACHINE_ARGS[@]}")
fi

if [[ -n "${CPU_TYPE:-}" ]]; then
    read -r -a CPU_ARGS <<< "${CPU_TYPE}"
    QM_CREATE_ARGS+=("${CPU_ARGS[@]}")
fi

qm create "${QM_CREATE_ARGS[@]}"
msg_ok "Created VM shell"

msg_info "Importing disk into ${STORAGE}"
if qm disk import --help >/dev/null 2>&1; then
    IMPORT_CMD=(qm disk import)
else
    IMPORT_CMD=(qm importdisk)
fi

IMPORT_ARGS=("$VMID" "$WORK_FILE" "$STORAGE")
if [[ -n "${DISK_IMPORT_FORMAT:-}" ]]; then
    IMPORT_ARGS+=("--format" "$DISK_IMPORT_FORMAT")
fi
IMPORT_OUT="$("${IMPORT_CMD[@]}" "${IMPORT_ARGS[@]}" 2>&1)"
DISK_REF_IMPORTED="$(printf '%s\n' "$IMPORT_OUT" | sed -n "s/.*successfully imported disk '\([^']*\)'.*/\1/p" | tr -d '\r\"')"

if [[ -z "$DISK_REF_IMPORTED" ]]; then
    DISK_REF_IMPORTED="$(pvesm list "$STORAGE" 2>/dev/null | awk -v id="$VMID" '$0 ~ ("vm-" id "-disk-") {print $1 ":" $5}' | sort | tail -n1)"
fi

if [[ -z "$DISK_REF_IMPORTED" ]]; then
    msg_error "Não foi possível determinar o disco importado."
    echo "$IMPORT_OUT"
    exit 226
fi

msg_ok "Imported disk"

rm -f "$WORK_FILE"

EFI_REF="${STORAGE}:0${FORMAT:-,efitype=4m}"

qm set "$VMID" --efidisk0 "$EFI_REF" >/dev/null
qm set "$VMID" --scsi0 "${DISK_REF_IMPORTED},${DISK_CACHE:-}${THIN%,}" >/dev/null
qm set "$VMID" --boot order=scsi0 >/dev/null
qm set "$VMID" --serial0 socket >/dev/null
qm set "$VMID" --agent enabled=1 >/dev/null

msg_ok "Disk and Guest Agent configured"

qm set "$VMID" --description "<div align='center'><h2>Zabbix Proxy</h2><p>Ubuntu 24.04 LTS</p><p>Zabbix Proxy ${ZABBIX_BRANCH} + SQLite</p><p>conectaCore/zabbix-proxy-proxmox</p></div>" >/dev/null

msg_info "Configuring Cloud-Init"
vm_provision "$VMID" || msg_warn "Cloud-Init provisioning did not complete"
msg_ok "Cloud-Init configured"

if [[ "$START_VM" == "yes" ]]; then
    msg_info "Starting Zabbix Proxy VM"
    qm start "$VMID"
    msg_ok "Started Zabbix Proxy VM"
fi

VM_IP=""
if [[ "$START_VM" == "yes" ]]; then
    set +e
    for _ in {1..15}; do
        VM_IP="$(qm guest cmd "$VMID" network-get-interfaces 2>/dev/null | jq -r '.[] | select(.name != "lo") | ."ip-addresses"[]? | select(."ip-address-type" == "ipv4") | ."ip-address"' 2>/dev/null | grep -v '^127\.' | head -n1)"
        [[ -n "$VM_IP" ]] && break
        sleep 3
    done
    set -e
fi

if declare -F display_cloud_init_info >/dev/null 2>&1; then
    display_cloud_init_info "$VMID" "$HN" 2>/dev/null || true
fi

echo
echo "========================================"
echo "       ZABBIX PROXY VM CRIADA"
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
[[ -n "$VM_IP" ]] && echo "IP Address    : ${VM_IP}"
echo
echo "A instalação do Zabbix Proxy será executada automaticamente no primeiro boot."
echo "Log na VM: /var/log/zabbix-proxy-install.log"
echo
