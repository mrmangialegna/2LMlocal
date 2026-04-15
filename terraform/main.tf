resource "proxmox_virtual_environment_vm" "nodes" {
    provider = proxmox
    for_each = var.nodes
    node_name = var.node 
    name = each.key 
    boot_order = ["scsi0", "net0"]
    cpu {
        cores = each.value.cpu
        type = "host"
    }
    memory {
        dedicated = each.value.memory
    }
    disk {
        size = tonumber(replace(upper(each.value.disk), "G", ""))
        datastore_id = each.value.datastore_id
        interface = "scsi0"
        file_format = "raw"
    }
    clone  {
        vm_id = each.value.template_id
        node_name = var.node 
    }
    network_device {
        bridge = "vmbr0"
        
    }
    initialization {
    dns {
        servers = var.dns_servers
    }
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
    lifecycle {
        ignore_changes = [
            initialization
        ]
    }
}


resource "proxmox_virtual_environment_vm" "nodes_2" {
    provider = proxmox
    for_each = var.nodes_2
    node_name = var.node_2
    name = "db"
    boot_order = ["scsi0", "net0"]
    cpu {
        cores = each.value.cpu
    }

    memory {
        dedicated = each.value.memory
    }

    disk {
        size = tonumber(replace(upper(each.value.disk), "G", ""))
        datastore_id = each.value.datastore_id
        interface = "scsi0"
        file_format = "raw"
    }

     clone  {
        vm_id = each.value.template_id
        node_name = var.node 
    }
    network_device {
        bridge = "vmbr0"
        
    }

    initialization {
    dns {
        servers = var.dns_servers
    }

    ip_config {
        ipv4 {
            address = "${cidrhost(var.network_subnet, var.vm_ip_start_2)}/24"
            gateway = var.gateway_ip
        }
    }

    user_account {
        username = var.vm_user
        password = "terraform"
        keys = [var.ssh_key]
    }
    }
    lifecycle {
        ignore_changes = [
            initialization
        ]
    }
}
   












