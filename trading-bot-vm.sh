#!/usr/bin/env bash

# =============================================================================
# Gold-VIX Trading Bot - Proxmox VM Installation Script
# =============================================================================
# One-command installation for ML trading bot on Proxmox VE
# Usage: bash -c "$(curl -fsSL YOUR_URL/trading-bot-vm.sh)"
# =============================================================================

# Source build functions
source <(curl -fsSL https://raw.githubusercontent.com/YOUR_REPO/trading-bot-proxmox/main/build.func)

# Application information
APP="Gold-VIX Trading Bot"
APP_DESCRIPTION="Machine Learning Trading Bot with Reinforcement Learning"
VERSION="1.0.0"

# VM Configuration (can be overridden with environment variables)
VM_ID="${VM_ID:-200}"
VM_NAME="${VM_NAME:-trading-bot-ml}"
VM_CORES="${VM_CORES:-8}"
VM_MEMORY="${VM_MEMORY:-16384}"  # 16GB in MB
VM_DISK_SIZE="${VM_DISK_SIZE:-100G}"
VM_STORAGE="${VM_STORAGE:-local-lvm}"
VM_BRIDGE="${VM_BRIDGE:-vmbr0}"

# Cloud-init configuration
CI_USER="${CI_USER:-tradingbot}"
CI_PASSWORD="${CI_PASSWORD:-TradingBot2025!}"  # CHANGE THIS!
SSH_KEY_FILE="${SSH_KEY_FILE:-$HOME/.ssh/id_rsa.pub}"

# Ubuntu Cloud Image
UBUNTU_VERSION="${UBUNTU_VERSION:-24.04}"
IMAGE_URL="https://cloud-images.ubuntu.com/releases/${UBUNTU_VERSION}/release/ubuntu-${UBUNTU_VERSION}-server-cloudimg-amd64.img"
IMAGE_FILE="/var/lib/vz/template/iso/ubuntu-${UBUNTU_VERSION}-cloudimg.img"

# Repository URL for internal setup script
REPO_URL="${REPO_URL:-https://raw.githubusercontent.com/YOUR_REPO/trading-bot-proxmox/main}"

# =============================================================================
# Main Installation Function
# =============================================================================

main() {
    # Enable error handling
    catch_errors

    # Display header
    header_info "$APP"

    echo -e "${CYAN}╔══════════════════════════════════════════════════════════════╗${NC}"
    echo -e "${CYAN}║${NC} ${WHITE}VM Configuration${NC}"
    echo -e "${CYAN}╠══════════════════════════════════════════════════════════════╣${NC}"
    echo -e "${CYAN}║${NC}  VM ID:        ${YELLOW}$VM_ID${NC}"
    echo -e "${CYAN}║${NC}  Name:         ${YELLOW}$VM_NAME${NC}"
    echo -e "${CYAN}║${NC}  CPU Cores:    ${YELLOW}$VM_CORES${NC}"
    echo -e "${CYAN}║${NC}  Memory:       ${YELLOW}$((VM_MEMORY / 1024)) GB${NC}"
    echo -e "${CYAN}║${NC}  Disk:         ${YELLOW}$VM_DISK_SIZE${NC}"
    echo -e "${CYAN}║${NC}  Storage:      ${YELLOW}$VM_STORAGE${NC}"
    echo -e "${CYAN}║${NC}  Network:      ${YELLOW}$VM_BRIDGE${NC}"
    echo -e "${CYAN}║${NC}  Username:     ${YELLOW}$CI_USER${NC}"
    echo -e "${CYAN}║${NC}  OS:           ${YELLOW}Ubuntu $UBUNTU_VERSION LTS${NC}"
    echo -e "${CYAN}╚══════════════════════════════════════════════════════════════╝${NC}"
    echo ""

    read -p "$(echo -e ${YELLOW}Continue with installation? [Y/n]: ${NC})" -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Yy]$ ]] && [[ -n $REPLY ]]; then
        msg_info "Installation cancelled"
        exit 0
    fi

    # Pre-flight checks
    msg_info "Running pre-flight checks..."
    check_proxmox
    check_vm_id "$VM_ID"
    check_storage "$VM_STORAGE"

    # Download Ubuntu Cloud Image
    if [ ! -f "$IMAGE_FILE" ]; then
        download_file "$IMAGE_URL" "$IMAGE_FILE"
    else
        msg_ok "Cloud image already exists"
    fi

    # Create VM
    create_vm "$VM_ID" "$VM_NAME" "$VM_CORES" "$VM_MEMORY" "$VM_STORAGE" "$VM_BRIDGE"

    # Import and attach disk
    import_disk "$VM_ID" "$IMAGE_FILE" "$VM_STORAGE"

    msg_info "Attaching disk to VM..."
    qm set "$VM_ID" --scsi0 "${VM_STORAGE}:vm-${VM_ID}-disk-0" >> "$LOG_FILE" 2>&1
    msg_ok "Disk attached"

    # Add Cloud-Init drive
    msg_info "Adding Cloud-Init drive..."
    qm set "$VM_ID" --ide2 "${VM_STORAGE}:cloudinit" >> "$LOG_FILE" 2>&1
    msg_ok "Cloud-Init drive added"

    # Configure boot
    msg_info "Configuring boot settings..."
    qm set "$VM_ID" --boot c --bootdisk scsi0 >> "$LOG_FILE" 2>&1
    qm set "$VM_ID" --serial0 socket --vga serial0 >> "$LOG_FILE" 2>&1
    msg_ok "Boot configured"

    # Configure Cloud-Init
    msg_info "Configuring Cloud-Init..."

    # Set DHCP (or static if configured)
    qm set "$VM_ID" --ipconfig0 ip=dhcp >> "$LOG_FILE" 2>&1

    # Set user and password
    qm set "$VM_ID" --ciuser "$CI_USER" --cipassword "$CI_PASSWORD" >> "$LOG_FILE" 2>&1

    # Add SSH key if exists
    if [ -f "$SSH_KEY_FILE" ]; then
        qm set "$VM_ID" --sshkey "$SSH_KEY_FILE" >> "$LOG_FILE" 2>&1
        msg_ok "Cloud-Init configured with SSH key"
    else
        msg_ok "Cloud-Init configured (no SSH key found)"
    fi

    # Resize disk
    msg_info "Resizing disk to $VM_DISK_SIZE..."
    qm resize "$VM_ID" scsi0 "$VM_DISK_SIZE" >> "$LOG_FILE" 2>&1
    msg_ok "Disk resized"

    # Additional VM settings
    msg_info "Applying additional settings..."
    qm set "$VM_ID" --agent enabled=1 >> "$LOG_FILE" 2>&1
    qm set "$VM_ID" --description "Gold-VIX ML Trading Bot\nVersion: $VERSION\nCreated: $(date)" >> "$LOG_FILE" 2>&1
    msg_ok "Settings applied"

    # Start VM
    msg_info "Starting VM..."
    qm start "$VM_ID" >> "$LOG_FILE" 2>&1
    msg_ok "VM started"

    # Wait for cloud-init
    msg_info "Waiting for cloud-init to complete (60 seconds)..."
    sleep 60

    # Try to get IP
    VM_IP=$(get_vm_ip "$VM_ID" 30) || VM_IP="check-proxmox-web-ui"

    # Print summary
    print_summary "$VM_ID" "$VM_IP" "$CI_USER" "$CI_PASSWORD"

    # Additional instructions
    echo -e "${MAGENTA}╔══════════════════════════════════════════════════════════════╗${NC}"
    echo -e "${MAGENTA}║${NC}  ${WHITE}Next Steps - Install Trading Bot${NC}"
    echo -e "${MAGENTA}╠══════════════════════════════════════════════════════════════╣${NC}"
    echo -e "${MAGENTA}║${NC}"
    echo -e "${MAGENTA}║${NC}  1. Wait 60 seconds for cloud-init"
    echo -e "${MAGENTA}║${NC}  2. SSH to VM:"
    echo -e "${MAGENTA}║${NC}     ${YELLOW}ssh $CI_USER@$VM_IP${NC}"
    echo -e "${MAGENTA}║${NC}"
    echo -e "${MAGENTA}║${NC}  3. Run bot installation:"
    echo -e "${MAGENTA}║${NC}     ${YELLOW}bash <(curl -fsSL $REPO_URL/setup-internal.sh)${NC}"
    echo -e "${MAGENTA}║${NC}"
    echo -e "${MAGENTA}║${NC}  4. Monitor training:"
    echo -e "${MAGENTA}║${NC}     ${YELLOW}http://$VM_IP:6006${NC} (TensorBoard)"
    echo -e "${MAGENTA}║${NC}"
    echo -e "${MAGENTA}╚══════════════════════════════════════════════════════════════╝${NC}"
    echo ""
}

# =============================================================================
# Update Function (for future updates)
# =============================================================================

update() {
    header_info "$APP"

    if ! qm status "$VM_ID" &>/dev/null; then
        msg_error "VM $VM_ID not found!"
        exit 1
    fi

    msg_info "Updating $APP..."

    # Get VM IP
    VM_IP=$(get_vm_ip "$VM_ID" 10)

    if [ "$VM_IP" = "unknown" ]; then
        msg_error "Could not connect to VM"
        exit 1
    fi

    msg_info "Connecting to VM and updating..."

    ssh -o StrictHostKeyChecking=no "$CI_USER@$VM_IP" << 'EOF'
cd ~/trading-bot/gold_vix_bot
source venv/bin/activate
pip install --upgrade -r requirements.txt
sudo systemctl restart trading-bot.service
EOF

    msg_ok "Update completed"
    exit 0
}

# =============================================================================
# Uninstall Function
# =============================================================================

uninstall() {
    header_info "$APP"

    if ! qm status "$VM_ID" &>/dev/null; then
        msg_error "VM $VM_ID not found!"
        exit 1
    fi

    msg_warn "This will DELETE VM $VM_ID ($VM_NAME)"
    read -p "$(echo -e ${RED}Are you sure? [y/N]: ${NC})" -n 1 -r
    echo

    if [[ $REPLY =~ ^[Yy]$ ]]; then
        msg_info "Stopping VM..."
        qm stop "$VM_ID" >> "$LOG_FILE" 2>&1 || true

        msg_info "Deleting VM..."
        qm destroy "$VM_ID" --purge >> "$LOG_FILE" 2>&1

        msg_ok "VM deleted successfully"
    else
        msg_info "Uninstall cancelled"
    fi

    exit 0
}

# =============================================================================
# Script Entry Point
# =============================================================================

# Parse command line arguments
case "${1:-install}" in
    install)
        main
        ;;
    update)
        update
        ;;
    uninstall)
        uninstall
        ;;
    *)
        echo "Usage: $0 {install|update|uninstall}"
        exit 1
        ;;
esac
