# Authentication (endpoint = https://<host>:8006/api2/json — path richiesto da Proxmox VE)
variable "proxmox_api_url" {
  description = "Proxmox VE API base URL"
  type        = string
}

variable "proxmox_api_token" {
    description = "Proxmox API"
    type = string
    sensitive = true
}

variable "ssh_key" {
    description = "SSH key"
    type = string
    sensitive = true
}

#Nodes
variable "node" {
    description = "Proxmox node name"
    type = string
    default = "pve"
}

variable "node_2" {
    description = "Proxmox node name"
    type = string
    default = "lab2"
}

variable "nodes" {
    description = "Node definitions"
    type = map(object({
        cpu = number
        memory = number
        disk = string
        datastore_id = string
        role = string
        vm_ip = number
        template_id = number
       # datastore_id = string
    }))
}

variable "nodes_2" {
  description = "VM DB"
  type = map(object({
    cpu         = number
    memory      = number
    disk        = string
    datastore_id = string
    role        = string
    template_id = number
  }))
  default = {}
}

variable "template_name" {
    description = "OS template name"
    type = string
    default = "ubuntu-22.04-cloudinit"
}


variable "vm_user"{
    description = "VM user"
    type = string
    default = "ubuntu"
}

variable "vm_count" {
    description = "Number of VMs to provision"
    type= number
    default = 3
#forse aggiungere un'idea di scaling? ma forse no
}

variable "vm_name_prefix" {
    description = "Prefix for VMs"
    type= string
    default = "llm-worker"
}

#Network 1
variable "network_subnet" {
    description = "Network subnet for Vms"
    type = string
    default = "192.168.122.0/24"
}

variable "vm_ip_start" {
    description = "IPs for VMs"
    type = number
    default = 20
}

variable "gateway_ip" {
    description = "Gw Ip address"
    type = string
    default = "192.168.122.1"
}

variable "dns_servers" {
    description = "DNS Servers"
    type = list(string)
    default = ["1.1.1.1", "1.0.0.1"]
}

variable "vm_ip_start_2" {
    description = "IPs for VMs"
    type = number
    default = 200
}

/*variable "proxmox_api_url_2" {
    description = "Proxmox API URL"
    type = string
}

variable "pm_api_token_id" {
    description = "API token ID"
    type = string
}



variable "proxmox_api_token_2" {
    description = "Proxmox API"
    type = string
    sensitive = true
}


variable "template_name_2" {
    description = "OS template name"
    type = string
    default = "ubuntu-22.04-cloudinit"
}



variable "vm_user_2"{
    description = "VM user"
    type = string
    default = "ubuntu"
}

#Network 2

variable "network_subnet_2" {
    description = "Network subnet for Vms"
    type = string
    default = "192.168.0.0/24"
}

variable "vm_ip_start_2" {
    description = "IPs for VMs"
    type = number
    default = 30
}

variable "gateway_ip_2" {
    description = "Gw Ip address"
    type = string
    default = "192.168.0.1"
}

variable "dns_servers_2" {
    description = "DNS Servers"
    type = list(string)
    default = ["1.1.1.1", "1.0.0.1"]
}
*/

