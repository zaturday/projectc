# =============================================================================
# vSphere VM Module - Outputs
# =============================================================================

output "vm_id" {
  description = "VMware VM IDs"
  value       = vsphere_virtual_machine.vm[*].id
}

output "vm_name" {
  description = "VM names"
  value       = vsphere_virtual_machine.vm[*].name
}

output "vm_ip_address" {
  description = "VM IP addresses"
  value       = vsphere_virtual_machine.vm[*].default_ip_address
}

output "vm_moid" {
  description = "VM MOID (Managed Object Reference ID)"
  value       = vsphere_virtual_machine.vm[*].moid
}

output "vm_uuid" {
  description = "VM UUIDs"
  value       = vsphere_virtual_machine.vm[*].uuid
}
