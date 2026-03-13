resource "proxmox_virtual_environment_vm" "nodes" {
    for_each = var.nodes
    node_name = var.node 
    name = each.key 
    cpu {
        cores = each.value.cpu
        type = "host"
    }
    memory {
        dedicated = each.value.memory
    }
    disk {
        size = 20
        datastore_id = each.value.datastore_id
        interface = "scsi0"
    }
    clone  {
        vm_id = each.value.template_id
        node_name = var.node 
    }
    network_device {
        bridge = "vmbr0"
        
    }
    initialization {
        #hostname = each.key
        
        ip_config {
            ipv4 {
                address = "${cidrhost(var.network_subnet, var.vm_ip_start + index(keys(var.nodes), each.key))}/24" 
                gateway = var.gateway_ip
            }
        }    
        user_account {
            username = var.vm_user
            password = "terraform"
            keys = [var.ssh_key]
        }

    }
}









