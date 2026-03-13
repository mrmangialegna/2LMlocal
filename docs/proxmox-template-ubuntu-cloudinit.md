# Template Proxmox: Ubuntu 22.04 con cloud-init

Terraform clona un template esistente (`template_id` in tfvars). Qui come creare il template su Proxmox.

## Requisiti

- Proxmox VE con almeno un nodo
- Immagine cloud di Ubuntu 22.04 (ISO o image già scaricata)

## 1. Scaricare l’immagine cloud Ubuntu

Sul nodo Proxmox (SSH o shell):

```bash
# Esempio: storage locale per VM (adatta il path al tuo datastore)
cd /var/lib/vz/template/iso/
# oppure dove hai lo storage per ISO/images
wget https://cloud-images.ubuntu.com/jammy/current/jammy-server-cloudimg-amd64.img
```

## 2. Creare la VM e convertirla in template

- **VM** → Create VM:
  - Nome: es. `ubuntu-22.04-cloudinit`
  - OS: Use existing disk → seleziona `jammy-server-cloudimg-amd64.img`
  - Disk: tipo **SCSI**, size adeguata (es. 32G)
  - CPU: 2, Memory: 2048 (solo per il template)
  - Network: bridge `vmbr0`
- **Options** della VM:
  - **QEMU Guest Agent**: abilitato se disponibile
- **Cloud-Init** (in Hardware o in una sezione dedicata):
  - Configura un disco/datasource cloud-init (in molte installazioni Proxmox lo aggiunge automaticamente con “Add” → Cloud-Init drive)

Se usi la linea di comando (qm):

```bash
# Crea VM (es. vmid 9000)
qm create 9000 --name ubuntu-22.04-cloudinit --memory 2048 --cores 2 --net0 virtio,bridge=vmbr0
qm importdisk 9000 jammy-server-cloudimg-amd64.img local-lvm
qm set 9000 --scsihw virtio-scsi-pci --scsi0 local-lvm:vm-9000-disk-0
qm set 9000 --ide2 local-lvm:cloudinit
qm set 9000 --boot c --bootdisk scsi0
qm set 9000 --serial0 socket --vga serial0
qm template 9000
```

Sostituisci `local-lvm` con il tuo `datastore_id` se diverso. Il vmid (es. `9000`) è il valore da usare come `template_id` in `terraform.tfvars`.

## 3. Collegare il template a Terraform

In `terraform.tfvars`:

- `template_id = 9000` (o il vmid che hai usato)
- Il `template_name` in variables è solo descrittivo; ciò che conta per il clone è `template_id`.

Dopo `terraform apply`, le VM vengono clonate da questo template e ricevono hostname, IP e utente SSH dal blocco `initialization` (cloud-init) in `main.tf`.
