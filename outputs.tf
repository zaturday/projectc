# =============================================================================
# Root Module Outputs
# =============================================================================

output "control_plane_vms" {
  description = "Control plane VM information"
  value = {
    names = module.control_plane[*].vm_name
    ips   = module.control_plane[*].vm_ip_address
    ids   = module.control_plane[*].vm_id
  }
}

output "worker_vms" {
  description = "Worker VM information"
  value = {
    names = module.workers[*].vm_name
    ips   = module.workers[*].vm_ip_address
    ids   = module.workers[*].vm_id
  }
}

output "kubeconfig_info" {
  description = "Instructions for accessing the Kubernetes cluster"
  value = <<-EOT
    ================================================
    Kubernetes Cluster Access
    ================================================

    1. SSH to the first control plane node:
       ssh -i ${var.ssh_private_key_path} ubuntu@${module.control_plane[0].vm_ip_address}

    2. The kubeconfig is located at:
       /etc/kubernetes/admin.conf

    3. To use kubectl locally, copy the config:
       scp -i ${var.ssh_private_key_path} ubuntu@${module.control_plane[0].vm_ip_address}:/etc/kubernetes/admin.conf ~/.kube/config-${var.cluster_name}
       export KUBECONFIG=~/.kube/config-${var.cluster_name}

    4. Install a CNI plugin (if not already done):
       kubectl apply -f https://github.com/flannel-io/flannel/releases/latest/download/kube-flannel.yml

    5. Verify cluster status:
       kubectl get nodes
       kubectl get pods -A
    ================================================
    EOT
}
