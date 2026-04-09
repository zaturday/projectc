# =============================================================================
# vSphere Configuration Variables
# =============================================================================

variable "vsphere_user" {
  description = "vSphere username"
  type        = string
  sensitive   = true
}

variable "vsphere_password" {
  description = "vSphere password"
  type        = string
  sensitive   = true
}

variable "vsphere_server" {
  description = "vSphere server hostname or IP"
  type        = string
}

variable "vsphere_allow_unverified_ssl" {
  description = "Allow unverified SSL certificates (set to false and configure CA cert for production)"
  type        = bool
  default     = false
}

variable "vsphere_datacenter" {
  description = "vSphere datacenter name"
  type        = string
  default     = "Datacenter"
}

variable "vsphere_datastore" {
  description = "vSphere datastore name"
  type        = string
  default     = "datastore1"
}

variable "vsphere_cluster" {
  description = "vSphere compute cluster name"
  type        = string
  default     = "Cluster"
}

variable "vsphere_network" {
  description = "vSphere network name for VMs"
  type        = string
}

# =============================================================================
# Cluster Configuration Variables
# =============================================================================

variable "cluster_name" {
  description = "Name of the Kubernetes cluster"
  type        = string
  default     = "k8s-cluster"
}

variable "cluster_domain" {
  description = "Kubernetes cluster domain"
  type        = string
  default     = "cluster.local"
}

variable "control_plane_count" {
  description = "Number of control plane nodes"
  type        = number
  default     = 1
}

variable "worker_count" {
  description = "Number of worker nodes"
  type        = number
  default     = 2
}

variable "pod_cidr" {
  description = "CIDR range for pods"
  type        = string
  default     = "10.244.0.0/16"
}

variable "service_cidr" {
  description = "CIDR range for services"
  type        = string
  default     = "10.96.0.0/12"
}

# =============================================================================
# Network Configuration Variables
# =============================================================================

variable "control_plane_ips" {
  description = "Static IP addresses for control plane nodes"
  type        = list(string)
}

variable "worker_ips" {
  description = "Static IP addresses for worker nodes"
  type        = list(string)
}

variable "gateway" {
  description = "Default gateway IP"
  type        = string
}

variable "netmask" {
  description = "Network mask (e.g., 255.255.255.0)"
  type        = string
  default     = "255.255.255.0"
}

variable "netmask_cidr" {
  description = "Network mask in CIDR notation (e.g., 24 for 255.255.255.0)"
  type        = number
  default     = 24
}

variable "dns_servers" {
  description = "DNS server IP addresses"
  type        = list(string)
  default     = ["8.8.8.8", "8.8.4.4"]
}

# =============================================================================
# VM Resource Configuration Variables
# =============================================================================

variable "vm_template" {
  description = "vSphere VM template name (Ubuntu 22.04 with containerd recommended)"
  type        = string
}

variable "control_plane_cpus" {
  description = "Number of CPUs for control plane nodes"
  type        = number
  default     = 4
}

variable "control_plane_memory" {
  description = "Memory (MB) for control plane nodes"
  type        = number
  default     = 8192
}

variable "control_plane_disk_size" {
  description = "Disk size (GB) for control plane nodes"
  type        = number
  default     = 100
}

variable "worker_cpus" {
  description = "Number of CPUs for worker nodes"
  type        = number
  default     = 4
}

variable "worker_memory" {
  description = "Memory (MB) for worker nodes"
  type        = number
  default     = 8192
}

variable "worker_disk_size" {
  description = "Disk size (GB) for worker nodes"
  type        = number
  default     = 100
}

# =============================================================================
# SSH Configuration Variables
# =============================================================================

variable "ssh_public_key_path" {
  description = "Path to SSH public key"
  type        = string
  default     = "~/.ssh/id_rsa.pub"
}

variable "ssh_private_key_path" {
  description = "Path to SSH private key"
  type        = string
  default     = "~/.ssh/id_rsa"
}
