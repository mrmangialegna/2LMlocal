terraform {
    required_providers {
        proxmox = {
            source = "bpg/proxmox"
            version = "~> 0.66.0"
        }
    }
}

provider "proxmox" {
    endpoint = var.proxmox_api_url
    api_token = var.pm_api_token_id
    insecure = true
}
