# =============================================================================
# Kubernetes Cluster Provisioning on VMware vSphere
# =============================================================================

terraform {
  required_version = ">= 1.5.0"

  required_providers {
    vsphere = {
      source  = "hashicorp/vsphere"
      version = "~> 2.5"
    }
    cloudinit = {
      source  = "hashicorp/cloudinit"
      version = "~> 2.3"
    }
  }
}

# -----------------------------------------------------------------------------
# vSphere Provider Configuration
# -----------------------------------------------------------------------------
provider "vsphere" {
  user           = var.vsphere_user
  password       = var.vsphere_password
  vsphere_server = var.vsphere_server
  allow_unverified_ssl = var.vsphere_allow_unverified_ssl
}

provider "cloudinit" {}

# -----------------------------------------------------------------------------
# Data Sources
# -----------------------------------------------------------------------------
data "vsphere_datacenter" "dc" {
  name = var.vsphere_datacenter
}

data "vsphere_datastore" "datastore" {
  name          = var.vsphere_datastore
  datacenter_id = data.vsphere_datacenter.dc.id
}

data "vsphere_compute_cluster" "cluster" {
  name          = var.vsphere_cluster
  datacenter_id = data.vsphere_datacenter.dc.id
}

data "vsphere_network" "network" {
  name          = var.vsphere_network
  datacenter_id = data.vsphere_datacenter.dc.id
}

# -----------------------------------------------------------------------------
# Local Values
# -----------------------------------------------------------------------------
locals {
  control_plane_count = var.control_plane_count
  worker_count        = var.worker_count

  cluster_name = var.cluster_name
  cluster_domain = var.cluster_domain

  # SSH key for node access
  ssh_public_key = file(var.ssh_public_key_path)
  ssh_private_key = file(var.ssh_private_key_path)
}

# -----------------------------------------------------------------------------
# Module: Network Resources (optional - for custom network setup)
# -----------------------------------------------------------------------------

# -----------------------------------------------------------------------------
# Module: Control Plane Nodes
# -----------------------------------------------------------------------------
module "control_plane" {
  source = "./modules/vsphere-vm"

  vm_template   = var.vm_template
  vm_folder     = "${var.cluster_name}/control-plane"
  vm_name_prefix = "${var.cluster_name}-cp"
  count         = local.control_plane_count

  num_cpus  = var.control_plane_cpus
  memory    = var.control_plane_memory
  disk_size = var.control_plane_disk_size

  network_id     = data.vsphere_network.network.id
  datastore_id   = data.vsphere_datastore.datastore.id
  datacenter_id  = data.vsphere_datacenter.dc.id
  cluster_id     = data.vsphere_compute_cluster.cluster.id

  ip_address = var.control_plane_ips[count.index]
  gateway    = var.gateway
  netmask    = var.netmask
  dns_servers = var.dns_servers

  cloudinit_config = templatefile("${path.module}/templates/cloudinit-controlplane.yaml", {
    hostname        = "${var.cluster_name}-cp-${count.index + 1}"
    ssh_public_key  = local.ssh_public_key
    cluster_name    = local.cluster_name
    cluster_domain  = local.cluster_domain
    pod_cidr        = var.pod_cidr
    service_cidr    = var.service_cidr
    is_first_cp     = count.index == 0
    control_plane_ip = var.control_plane_ips[0]
  })
}

# -----------------------------------------------------------------------------
# Module: Worker Nodes
# -----------------------------------------------------------------------------
module "workers" {
  source = "./modules/vsphere-vm"

  vm_template   = var.vm_template
  vm_folder     = "${var.cluster_name}/workers"
  vm_name_prefix = "${var.cluster_name}-worker"
  count         = local.worker_count

  num_cpus  = var.worker_cpus
  memory    = var.worker_memory
  disk_size = var.worker_disk_size

  network_id     = data.vsphere_network.network.id
  datastore_id   = data.vsphere_datastore.datastore.id
  datacenter_id  = data.vsphere_datacenter.dc.id
  cluster_id     = data.vsphere_compute_cluster.cluster.id

  ip_address = var.worker_ips[count.index]
  gateway    = var.gateway
  netmask    = var.netmask
  dns_servers = var.dns_servers

  cloudinit_config = templatefile("${path.module}/templates/cloudinit-worker.yaml", {
    hostname        = "${var.cluster_name}-worker-${count.index + 1}"
    ssh_public_key  = local.ssh_public_key
    control_plane_ip = var.control_plane_ips[0]
    cluster_name    = local.cluster_name
  })
}

# -----------------------------------------------------------------------------
# Outputs
# -----------------------------------------------------------------------------
output "cluster_info" {
  value = {
    name = var.cluster_name
    control_plane_ips = module.control_plane[*].vm_ip_address
    worker_ips = module.workers[*].vm_ip_address
    kubeconfig_instructions = "SSH to first control plane node and run: sudo cat /etc/kubernetes/admin.conf"
  }
  sensitive = false
}

output "ssh_command" {
  value = "ssh -i ${var.ssh_private_key_path} ubuntu@${module.control_plane[0].vm_ip_address}"
}
