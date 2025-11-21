#!/usr/bin/env bash

# =============================================================================
# Gold-VIX Trading Bot - Internal VM Setup Script
# =============================================================================
# Run this script INSIDE the VM after creation
# Usage: bash <(curl -fsSL YOUR_URL/setup-internal.sh)
# =============================================================================

set -e

# Colors
RED=$'\033[0;31m'
GREEN=$'\033[0;32m'
YELLOW=$'\033[1;33m'
BLUE=$'\033[0;34m'
CYAN=$'\033[0;36m'
NC=$'\033[0m'

msg_info() { echo -e "${BLUE}[INFO]${NC} $*"; }
msg_ok() { echo -e "${GREEN}[OK]${NC} $*"; }
msg_error() { echo -e "${RED}[ERROR]${NC} $*"; }
msg_warn() { echo -e "${YELLOW}[WARN]${NC} $*"; }

# Repository URL for bot files
REPO_URL="${REPO_URL:-https://raw.githubusercontent.com/YOUR_REPO/trading-bot-files/main}"

# ASCII Art Header
clear
echo -e "${CYAN}"
cat << "EOF"
╔════════════════════════════════════════════════════════════════╗
║                                                                ║
║        GOLD-VIX TRADING BOT - INTERNAL SETUP                  ║
║        Machine Learning Trading System                         ║
║                                                                ║
╚════════════════════════════════════════════════════════════════╝
EOF
echo -e "${NC}"

msg_info "Starting automated setup..."
echo ""

# Step 1: System update
msg_info "[1/10] Updating system packages..."
sudo apt update -qq
sudo apt upgrade -y -qq
msg_ok "System updated"

# Step 2: Install dependencies
msg_info "[2/10] Installing dependencies..."
sudo apt install -y -qq \
    build-essential git curl wget vim tmux htop \
    software-properties-common ca-certificates
msg_ok "Dependencies installed"

# Step 3: Install Python 3.11
msg_info "[3/10] Installing Python 3.11..."
sudo add-apt-repository -y ppa:deadsnakes/ppa > /dev/null 2>&1
sudo apt update -qq
sudo apt install -y -qq python3.11 python3.11-venv python3.11-dev python3-pip
msg_ok "Python 3.11 installed"

# Step 4: Install Docker
msg_info "[4/10] Installing Docker..."
curl -fsSL https://get.docker.com -o /tmp/get-docker.sh
sudo sh /tmp/get-docker.sh > /dev/null 2>&1
sudo usermod -aG docker $USER
msg_ok "Docker installed"

# Step 5: Install QEMU Guest Agent
msg_info "[5/10] Installing QEMU Guest Agent..."
sudo apt install -y -qq qemu-guest-agent
sudo systemctl enable qemu-guest-agent > /dev/null 2>&1
sudo systemctl start qemu-guest-agent > /dev/null 2>&1
msg_ok "QEMU Guest Agent installed"

# Step 6: Configure firewall
msg_info "[6/10] Configuring firewall..."
sudo apt install -y -qq ufw
sudo ufw --force enable > /dev/null 2>&1
sudo ufw allow 22/tcp > /dev/null 2>&1
sudo ufw allow 6006/tcp > /dev/null 2>&1
sudo ufw allow 8050/tcp > /dev/null 2>&1
msg_ok "Firewall configured"

# Step 7: Create project structure
msg_info "[7/10] Creating project structure..."
mkdir -p ~/trading-bot/gold_vix_bot/{config,data/{raw,processed,models/checkpoints},logs,src,scripts,monitoring,backups}
cd ~/trading-bot/gold_vix_bot
msg_ok "Project structure created"

# Step 8: Download bot files
msg_info "[8/10] Downloading bot files..."

# Download Python files
curl -fsSL "$REPO_URL/data_loader.py" -o src/data_loader.py
curl -fsSL "$REPO_URL/feature_engineering.py" -o src/feature_engineering.py
curl -fsSL "$REPO_URL/environment.py" -o src/environment.py
curl -fsSL "$REPO_URL/train.py" -o scripts/train.py
curl -fsSL "$REPO_URL/config.yaml" -o config/config.yaml
curl -fsSL "$REPO_URL/requirements.txt" -o requirements.txt

chmod +x scripts/train.py
msg_ok "Bot files downloaded"

# Step 9: Setup Python environment
msg_info "[9/10] Setting up Python environment..."
python3.11 -m venv venv
source venv/bin/activate
pip install --quiet --upgrade pip setuptools wheel
pip install --quiet -r requirements.txt
msg_ok "Python environment ready"

# Step 10: Create systemd service
msg_info "[10/10] Creating systemd service..."

sudo tee /etc/systemd/system/trading-bot.service > /dev/null << EOF
[Unit]
Description=Gold-VIX Trading Bot
After=network.target

[Service]
Type=simple
User=$USER
WorkingDirectory=$HOME/trading-bot/gold_vix_bot
Environment="PATH=$HOME/trading-bot/gold_vix_bot/venv/bin"
ExecStart=$HOME/trading-bot/gold_vix_bot/venv/bin/python scripts/train.py
Restart=on-failure
RestartSec=10
StandardOutput=append:$HOME/trading-bot/gold_vix_bot/logs/bot.log
StandardError=append:$HOME/trading-bot/gold_vix_bot/logs/bot_error.log

[Install]
WantedBy=multi-user.target
EOF

sudo systemctl daemon-reload
sudo systemctl enable trading-bot.service
msg_ok "Service created"

# Create control scripts
cat > start.sh << 'EOFSTART'
#!/bin/bash
sudo systemctl start trading-bot.service
echo "Bot started"
sudo systemctl status trading-bot.service
EOFSTART

cat > stop.sh << 'EOFSTOP'
#!/bin/bash
sudo systemctl stop trading-bot.service
echo "Bot stopped"
EOFSTOP

cat > status.sh << 'EOFSTATUS'
#!/bin/bash
sudo systemctl status trading-bot.service
echo ""
echo "Recent logs:"
tail -n 20 ~/trading-bot/gold_vix_bot/logs/bot.log
EOFSTATUS

chmod +x *.sh

# Summary
echo ""
echo -e "${GREEN}╔════════════════════════════════════════════════════════════════╗${NC}"
echo -e "${GREEN}║${NC}  ${WHITE}Setup Completed Successfully!${NC}"
echo -e "${GREEN}╚════════════════════════════════════════════════════════════════╝${NC}"
echo ""
echo -e "${CYAN}Bot Location:${NC} ~/trading-bot/gold_vix_bot"
echo ""
echo -e "${CYAN}Quick Commands:${NC}"
echo -e "  Start:    ${YELLOW}./start.sh${NC}"
echo -e "  Stop:     ${YELLOW}./stop.sh${NC}"
echo -e "  Status:   ${YELLOW}./status.sh${NC}"
echo ""
echo -e "${CYAN}Start Training Now:${NC}"
echo -e "  ${YELLOW}sudo systemctl start trading-bot.service${NC}"
echo ""
echo -e "${CYAN}Monitor:${NC}"
echo -e "  Logs:       ${YELLOW}tail -f logs/bot.log${NC}"
echo -e "  TensorBoard: ${YELLOW}http://$(hostname -I | awk '{print $1}'):6006${NC}"
echo ""
echo -e "${YELLOW}⚠  Important:${NC} Logout and login again for Docker group"
echo ""
