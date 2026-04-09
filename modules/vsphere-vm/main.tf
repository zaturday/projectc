# =============================================================================
# vSphere VM Module
# Creates a virtual machine in vSphere with cloud-init configuration
# =============================================================================

variable "vm_template" {
  description = "Name of the VM template to clone"
  type        = string
}

variable "vm_folder" {
  description = "Folder path for the VM"
  type        = string
}

variable "vm_name_prefix" {
  description = "Prefix for VM names"
  type        = string
}

variable "count" {
  description = "Number of VMs to create"
  type        = number
  default     = 1
}

variable "num_cpus" {
  description = "Number of CPUs"
  type        = number
  default     = 2
}

variable "memory" {
  description = "Memory in MB"
  type        = number
  default     = 4096
}

variable "disk_size" {
  description = "Disk size in GB"
  type        = number
  default     = 50
}

variable "network_id" {
  description = "vSphere network ID"
  type        = string
}

variable "datastore_id" {
  description = "vSphere datastore ID"
  type        = string
}

variable "datacenter_id" {
  description = "vSphere datacenter ID"
  type        = string
}

variable "cluster_id" {
  description = "vSphere cluster ID"
  type        = string
}

variable "ip_address" {
  description = "Static IP address for the VM"
  type        = string
}

variable "gateway" {
  description = "Default gateway"
  type        = string
}

variable "netmask" {
  description = "Network mask"
  type        = string
  default     = "255.255.255.0"
}

variable "dns_servers" {
  description = "DNS servers"
  type        = list(string)
  default     = []
}

variable "cloudinit_config" {
  description = "Cloud-init configuration (YAML)"
  type        = string
}

# -----------------------------------------------------------------------------
# Cloud-init Config Drive
# -----------------------------------------------------------------------------
data "cloudinit_config" "vm" {
  count = var.count

  gzip          = false
  base64_encode = false

  part {
    content_type = "text/cloud-config"
    content      = var.cloudinit_config
  }
}

# -----------------------------------------------------------------------------
# VM Resource
# -----------------------------------------------------------------------------
resource "vsphere_virtual_machine" "vm" {
  count = var.count

  name             = "${var.vm_name_prefix}-${count.index + 1}"
  resource_pool_id = var.cluster_id
  datastore_id     = var.datastore_id
  folder           = var.vm_folder

  num_cpus = var.num_cpus
  memory   = var.memory

  guest_id = "ubuntu64Guest"

  network_interface {
    network_id = var.network_id
  }

  disk {
    label            = "disk0"
    size             = var.disk_size
    thin_provisioned = true
  }

  clone {
    template_uuid = data.vsphere_virtual_machine.template.id

    customize {
      linux_options {
        host_name = "${var.vm_name_prefix}-${count.index + 1}"
        domain    = "local"
      }

      network_interface {
        ipv4_address = var.ip_address
        ipv4_netmask = 24
      }

      ipv4_gateway    = var.gateway
      dns_server_list = var.dns_servers
    }
  }

  extra_config = {
    "guestinfo.userdata"          = data.cloudinit_config.vm[count.index].rendered
    "guestinfo.userdata.encoding" = "text"
  }

  # Wait for cloud-init to complete
  wait_for_guest_net_timeout = 0

  lifecycle {
    ignore_changes = [
      clone[0].template_uuid,
    ]
  }
}

# -----------------------------------------------------------------------------
# Data Source: Get Template Info
# -----------------------------------------------------------------------------
data "vsphere_virtual_machine" "template" {
  name          = var.vm_template
  datacenter_id = var.datacenter_id
}

# -----------------------------------------------------------------------------
# Outputs
# -----------------------------------------------------------------------------
output "vm_id" {
  value = vsphere_virtual_machine.vm[*].id
}

output "vm_name" {
  value = vsphere_virtual_machine.vm[*].name
}

output "vm_ip_address" {
  value = vsphere_virtual_machine.vm[*].default_ip_address
}

output "vm_moid" {
  value = vsphere_virtual_machine.vm[*].moid
}
