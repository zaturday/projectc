# Ubuntu 22.04 VM Template Setup Guide for vSphere

This guide walks you through creating a golden VM template for Kubernetes nodes.

---

## Prerequisites

- vSphere/ESXi access with permissions to create VMs and templates
- Ubuntu 22.04 ISO image (download from https://ubuntu.com/download/server)
- SSH key pair for node access

---

## Step 1: Create the Virtual Machine in vSphere

### 1.1 Create New VM

1. In vSphere Client, right-click on your cluster or host → **New Virtual Machine**
2. Select **Create a new virtual machine**
3. Name: `ubuntu-22.04-template`
4. Select your **datastore** and **cluster/host**

### 1.2 VM Configuration

| Setting | Value |
|---------|-------|
| **Guest OS** | Linux → Ubuntu Linux (64-bit) |
| **CPU** | 4 vCPU |
| **Memory** | 8 GB |
| **Disk** | 50 GB (Thin Provisioned) |
| **Network** | Your production network (VM Network) |

### 1.3 Add CD-ROM for ISO

1. Add a **CD/DVD Drive**
2. Select **Datastore ISO file**
3. Browse and select your Ubuntu 22.04 ISO
4. Check **Connect at power on**

---

## Step 2: Install Ubuntu Server 22.04

### 2.1 Boot and Start Installation

1. Power on the VM
2. Open console and boot from ISO
3. Select **Try or Install Ubuntu Server**

### 2.2 Installation Steps

Follow the installer:

| Step | Selection |
|------|-----------|
| **Language** | English (or your preference) |
| **Keyboard** | Your keyboard layout |
| **Installation type** | Ubuntu Server (default) |
| **Network** | DHCP is fine for template (we'll use static IPs via cloud-init later) |
| **Proxy** | Leave blank (unless you need one) |
| **Mirror** | Default is fine |
| **Storage** | Use entire disk, default LVM |
| **Profile** | Username: `ubuntu`, Hostname: `template` |
| **SSH** | ✅ **Install OpenSSH Server** (IMPORTANT!) |
| **Featured Snaps** | Skip for now |

### 2.3 Complete Installation

1. Wait for installation to complete
2. Select **Reboot Now**
3. **Eject the ISO** from CD-ROM before boot
4. Remove CD-ROM device (optional, but clean)

---

## Step 3: Install Required Packages

SSH into your new VM or use the console:

```bash
# Login with your ubuntu user

# Update package list
sudo apt update && sudo apt upgrade -y

# Install essential packages
sudo apt install -y \
    cloud-init \
    open-vm-tools \
    qemu-guest-agent \
    vim \
    curl \
    wget \
    git

# Enable services
sudo systemctl enable open-vm-tools
sudo systemctl start open-vm-tools

# Verify cloud-init is installed
cloud-init --version
```

---

## Step 4: Configure cloud-init for vSphere

### 4.1 Enable cloud-init to read from vSphere

```bash
# Create cloud-init configuration for VMware
sudo tee /etc/cloud/cloud.cfg.d/99-vmware-cust.cfg << 'EOF'
datasource_list: [VMware, ConfigDrive, NoCloud, None]
datasource:
  VMware:
    guestinfo:
      metadata:
        encoding: base64
      userdata:
        encoding: text
EOF
```

### 4.2 Verify cloud-init configuration

```bash
# Check cloud-init config
sudo cloud-init status

# Clean any existing cloud-init data (important for template!)
sudo cloud-init clean
```

---

## Step 5: Generalize the Template (IMPORTANT!)

Before converting to template, remove machine-specific data:

```bash
# Remove SSH host keys (will be regenerated on first boot)
sudo rm -f /etc/ssh/ssh_host_*

# Remove cloud-init instance data
sudo cloud-init clean --logs

# Remove machine-id
sudo truncate -s 0 /etc/machine-id
sudo rm -f /var/lib/dbus/machine-id

# Remove any authorized_keys (will be injected via cloud-init)
rm -f /home/ubuntu/.ssh/authorized_keys

# Clear bash history
history -c
history -w

# Remove any network configuration that might conflict
sudo rm -f /etc/netplan/50-cloud-init.yaml 2>/dev/null || true

# Shutdown the VM
sudo poweroff
```

---

## Step 6: Convert to Template in vSphere

### 6.1 Mark as Template

1. In vSphere Client, right-click the VM → **Template** → **Convert to Template**
2. Or keep as VM and clone from it

### 6.2 Alternative: Keep as VM for Cloning

If you prefer to keep it as a VM:
1. Rename to `ubuntu-22.04-cloud-init` (or your chosen name)
2. Add a **Template** tag or move to a Templates folder
3. Use for cloning

---

## Step 7: Verify Template Works

### 7.1 Test with a Small VM

1. Clone the template to a test VM
2. Add this to **VM Options** → **Advanced** → **Edit Configuration**:

| Key | Value |
|-----|-------|
| `guestinfo.userdata` | Your cloud-init YAML (base64 encoded) |
| `guestinfo.userdata.encoding` | `text` or `base64` |

### 7.2 Or Test with Terraform

Use the terraform configuration you already have - it will inject cloud-init via `extra_config`.

---

## Quick Reference: cloud-init Verification

```bash
# Check cloud-init status
sudo cloud-init status

# View cloud-init logs
sudo cat /var/log/cloud-init.log
sudo cat /var/log/cloud-init-output.log

# View applied configuration
sudo cloud-init query --format 'yaml'
```

---

## Troubleshooting

### cloud-init not running

```bash
# Force cloud-init to run on next boot
sudo cloud-init clean
sudo cloud-init init
```

### VMware Tools not working

```bash
# Reinstall
sudo apt install --reinstall open-vm-tools
sudo systemctl restart open-vm-tools
```

### Network not configured

Check that guestinfo properties are set correctly in vSphere:
```bash
vmware-toolbox-cmd config guestinfo get
```

---

## Summary Checklist

- [ ] Ubuntu 22.04 Server installed
- [ ] SSH server installed and working
- [ ] open-vm-tools installed
- [ ] cloud-init installed and configured
- [ ] SSH host keys removed
- [ ] cloud-init data cleaned
- [ ] machine-id cleared
- [ ] VM converted to template (or marked as template)
- [ ] Template name matches `vm_template` in terraform.tfvars

---

## Download Ubuntu 22.04

Official download: https://ubuntu.com/download/server

- Ubuntu Server 22.04.4 LTS (recommended latest point release)
- ISO size: ~1.5 GB
