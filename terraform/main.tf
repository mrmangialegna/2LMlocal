resource "proxmox_virtual_environment_vm" "nodes" {
    for_each = var.nodes
    node = each.value.node 
    name = each.key 
    cpu = each.value.cpu
    memory = each.value.memory
    disk = each.value.disk
    clone = var.template_name  
}

