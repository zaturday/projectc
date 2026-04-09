# Security Best Practices

## Credentials Management

### NEVER Commit Secrets

The following files are gitignored and should **never** be committed:
- `terraform.tfvars` - Contains sensitive values
- `*.tfstate` - Contains actual resource data and secrets
- `.terraform/` - Contains provider plugins

### Setting Credentials Securely

**Option 1: Environment Variables (Recommended)**

```bash
# Set credentials via environment
export TF_VAR_vsphere_user="administrator@vsphere.local"
export TF_VAR_vsphere_password="your-secure-password"
export TF_VAR_vsphere_server="192.168.1.40"

# Run terraform
terraform apply
```

**Option 2: Terraform Cloud/Enterprise**

Use Terraform Cloud's variable management with sensitive flag enabled.

**Option 3: Secrets Manager**

Integrate with HashiCorp Vault, AWS Secrets Manager, or Azure Key Vault.

## SSL/TLS Configuration

For production environments, configure proper SSL certificate verification:

```hcl
# In variables.tf or terraform.tfvars
vsphere_allow_unverified_ssl = false

# Optionally specify CA certificate
vsphere_insecure_path = ""  # Set path to CA cert bundle
```

## SSH Key Management

1. Use strong SSH keys (Ed25519 or RSA 4096-bit)
2. Never commit private keys to version control
3. Consider using SSH agent forwarding:
   ```bash
   ssh-add ~/.ssh/id_rsa
   ```

## Network Security

### Firewall Rules for Kubernetes

Ensure these ports are open between nodes:

| Port | Protocol | Direction | Purpose |
|------|----------|-----------|---------|
| 6443 | TCP | All → Control Plane | Kubernetes API |
| 2379-2380 | TCP | Control Plane ↔ Control Plane | etcd |
| 10250 | TCP | All → All | Kubelet API |
| 10251 | TCP | Control Plane → Control Plane | kube-scheduler |
| 10252 | TCP | Control Plane → Control Plane | kube-controller |
| 10255 | TCP | All → All | Read-only Kubelet |
| 30000-32767 | TCP/UDP | External → Workers | NodePort Services |

### Pod Network Security

- Use Network Policies to restrict pod-to-pod communication
- Consider Calico or Cilium for advanced network policies

## vSphere Permissions

Create a dedicated service account with minimal required permissions:

```
Required vSphere permissions:
- VirtualMachine.Inventory.Create
- VirtualMachine.Inventory.Delete
- VirtualMachine.Provisioning.Clone
- VirtualMachine.Provisioning.Deploy
- VirtualMachine.Interaction.PowerOn
- VirtualMachine.Interaction.PowerOff
- Resource.AssignVMToPool
- Datastore.AllocateSpace
- Network.Assign
```

## Audit Logging

Enable Terraform audit logging:

```bash
export TF_LOG=DEBUG
export TF_LOG_PATH=./terraform.log
```

## State File Security

The `terraform.tfstate` file contains sensitive data:

1. **Never commit** to version control
2. Use **remote backends** with encryption:
   - AWS S3 with SSE
   - Azure Blob Storage with encryption
   - Terraform Cloud with encrypted storage
3. Restrict access to state files

Example remote backend (S3):

```hcl
terraform {
  backend "s3" {
    bucket         = "my-terraform-state"
    key            = "k8s-cluster/terraform.tfstate"
    region         = "us-east-1"
    encrypt        = true
    dynamodb_table = "terraform-locks"
  }
}
```

## Cloud-Init Security

1. SSH keys are injected via guestinfo - ensure vSphere is secured
2. Consider using HashiCorp Boundary or similar for node access
3. Rotate SSH keys periodically

## Checklist Before Production

- [ ] Credentials removed from `terraform.tfvars`
- [ ] SSL verification enabled (or CA cert configured)
- [ ] Remote backend configured with encryption
- [ ] Network policies defined
- [ ] vSphere service account has minimal permissions
- [ ] Audit logging enabled
- [ ] SSH key rotation procedure documented
