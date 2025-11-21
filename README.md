# 🚀 Gold-VIX Trading Bot - One-Command Proxmox Installation

Automated installation of ML Trading Bot on Proxmox VE with a single command.

## ✨ Features

- **One-command installation** - Complete VM setup in minutes
- **Automated configuration** - No manual steps required
- **Production-ready** - Systemd service, logging, monitoring
- **GPU support** - Optional NVIDIA GPU passthrough
- **Security** - Firewall configured, SSH key support
- **Monitoring** - TensorBoard, logs, status scripts

## 📋 Prerequisites

- Proxmox VE 7.x or 8.x
- Root access to Proxmox host
- Internet connection
- At least 100GB free storage
- 8+ CPU cores, 16GB+ RAM available

## 🚀 Quick Start

### Installation

SSH to your Proxmox host and run:

```bash
bash -c "$(curl -fsSL https://raw.githubusercontent.com/YOUR_USERNAME/trading-bot-proxmox/main/trading-bot-vm.sh)"
```

That's it! The script will:
1. ✅ Download Ubuntu 24.04 cloud image
2. ✅ Create VM with optimal settings
3. ✅ Configure cloud-init for auto-login
4. ✅ Start VM and wait for initialization
5. ✅ Display connection information

### Post-Installation

After VM creation, SSH to the VM and run:

```bash
bash <(curl -fsSL https://raw.githubusercontent.com/YOUR_USERNAME/trading-bot-files/main/setup-internal.sh)
```

This will:
1. ✅ Install Python 3.11 and dependencies
2. ✅ Download trading bot code
3. ✅ Setup virtual environment
4. ✅ Create systemd service
5. ✅ Configure monitoring

## ⚙️ Configuration

### Customize VM Settings

Override defaults with environment variables:

```bash
# Custom VM ID and resources
VM_ID=250 VM_CORES=16 VM_MEMORY=32768 VM_DISK_SIZE=200G \
bash -c "$(curl -fsSL https://raw.githubusercontent.com/YOUR_USERNAME/trading-bot-proxmox/main/trading-bot-vm.sh)"

# Custom credentials
CI_USER=myuser CI_PASSWORD=MySecurePassword123! \
bash -c "$(curl -fsSL https://raw.githubusercontent.com/YOUR_USERNAME/trading-bot-proxmox/main/trading-bot-vm.sh)"

# Custom storage
VM_STORAGE=my-zfs-pool \
bash -c "$(curl -fsSL https://raw.githubusercontent.com/YOUR_USERNAME/trading-bot-proxmox/main/trading-bot-vm.sh)"
```

### Available Options

| Variable | Default | Description |
|----------|---------|-------------|
| `VM_ID` | 200 | Proxmox VM ID |
| `VM_NAME` | trading-bot-ml | VM name |
| `VM_CORES` | 8 | CPU cores |
| `VM_MEMORY` | 16384 | RAM in MB (16GB) |
| `VM_DISK_SIZE` | 100G | Disk size |
| `VM_STORAGE` | local-lvm | Proxmox storage pool |
| `VM_BRIDGE` | vmbr0 | Network bridge |
| `CI_USER` | tradingbot | Username |
| `CI_PASSWORD` | TradingBot2025! | Password (change!) |

## 📊 Usage

### Start Training

```bash
# SSH to VM
ssh tradingbot@<vm-ip>

# Start bot
sudo systemctl start trading-bot.service

# Check status
sudo systemctl status trading-bot.service

# View logs
tail -f ~/trading-bot/gold_vix_bot/logs/bot.log
```

### Monitor Training

```bash
# TensorBoard (from browser)
http://<vm-ip>:6006

# Quick status script
~/trading-bot/gold_vix_bot/status.sh

# Detailed monitoring
~/trading-bot/gold_vix_bot/scripts/monitor.sh
```

### Control Scripts

Inside VM at `~/trading-bot/gold_vix_bot/`:
- `./start.sh` - Start bot
- `./stop.sh` - Stop bot  
- `./status.sh` - Check status
- `./restart.sh` - Restart bot

## 🔧 Management Commands

### From Proxmox Host

```bash
# VM control
qm start 200
qm stop 200
qm reboot 200
qm status 200

# Console access
qm terminal 200

# Snapshot
qm snapshot 200 pre-training

# Backup
vzdump 200 --mode snapshot
```

### Update Bot

```bash
# From Proxmox host
bash -c "$(curl -fsSL https://raw.githubusercontent.com/YOUR_USERNAME/trading-bot-proxmox/main/trading-bot-vm.sh)" install update

# Or manually in VM
cd ~/trading-bot/gold_vix_bot
source venv/bin/activate
git pull  # if using git
pip install --upgrade -r requirements.txt
sudo systemctl restart trading-bot.service
```

### Uninstall

```bash
# From Proxmox host (deletes VM completely!)
bash -c "$(curl -fsSL https://raw.githubusercontent.com/YOUR_USERNAME/trading-bot-proxmox/main/trading-bot-vm.sh)" install uninstall
```

## 🐛 Troubleshooting

### VM won't start

```bash
qm unlock 200
qm start 200
```

### Can't find VM IP

```bash
# Check Proxmox web UI or
qm guest cmd 200 network-get-interfaces
```

### Bot service fails

```bash
# In VM
sudo journalctl -u trading-bot.service -n 50

# Test manually
cd ~/trading-bot/gold_vix_bot
source venv/bin/activate
python scripts/train.py
```

### Out of memory

```bash
# Increase RAM (from Proxmox)
qm set 200 --memory 32768
qm reboot 200

# Or reduce batch_size in config.yaml
```

## 📁 Repository Structure

```
trading-bot-proxmox/
├── build.func              # Helper functions library
├── trading-bot-vm.sh       # Main installation script
├── README.md               # This file
└── examples/
    └── custom-install.sh   # Example custom installation

trading-bot-files/
├── setup-internal.sh       # Internal VM setup
├── data_loader.py          # Bot source files
├── feature_engineering.py
├── environment.py
├── train.py
├── config.yaml
└── requirements.txt
```

## 🔒 Security Notes

- **Change default password!** Set `CI_PASSWORD` environment variable
- Add SSH keys: Place in `~/.ssh/id_rsa.pub` before running script
- Firewall configured automatically (SSH, TensorBoard only)
- Consider VPN for remote access to TensorBoard

## 🌟 Advanced Features

### GPU Passthrough

For GPU acceleration:

1. Identify GPU PCI ID:
```bash
lspci | grep -i nvidia
```

2. Run setup script:
```bash
bash <(curl -fsSL https://raw.githubusercontent.com/YOUR_USERNAME/trading-bot-proxmox/main/setup-gpu.sh)
```

3. Reboot Proxmox host

4. GPU will be available in VM

### Multiple Instances

Deploy multiple bots with different IDs:

```bash
VM_ID=201 VM_NAME=bot-strategy-a bash -c "$(curl -fsSL ...)"
VM_ID=202 VM_NAME=bot-strategy-b bash -c "$(curl -fsSL ...)"
VM_ID=203 VM_NAME=bot-strategy-c bash -c "$(curl -fsSL ...)"
```

### Custom Bot Code

Fork `trading-bot-files` repository and update `REPO_URL`:

```bash
REPO_URL=https://raw.githubusercontent.com/YOUR_USERNAME/my-custom-bot/main \
bash -c "$(curl -fsSL ...)"
```

## 📝 License

MIT License - See LICENSE file

## 🤝 Contributing

Pull requests welcome! Please test on Proxmox 8.x before submitting.

## 📮 Support

- Issues: GitHub Issues
- Discussions: GitHub Discussions
- Documentation: Wiki

## 🎯 Roadmap

- [ ] Support for multiple storage backends
- [ ] Automatic SSL certificates for TensorBoard
- [ ] Integration with Proxmox backup scheduler
- [ ] Web dashboard for multi-bot management
- [ ] Telegram bot for alerts

---

**Made with ❤️ for algorithmic traders**
