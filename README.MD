# 2LMlocal

An on-premise AI platform for small and medium businesses that want to run local language models without relying on external cloud providers.

**Privacy by design — your data never leaves the company network.**

---

## Project Status

| Component |
|---|
| Terraform — VM provisioning | 
| Kubespray — Kubernetes install | 
| Calico — CNI | 
| Helm |
| Traefik — Ingress Controller | via Helm
| Prometheus + Grafana | via Helm
| Metallb | via Helm
| ArgoCD | via Helm
| Ollama — LLM backend | 
| Open WebUI — Frontend | 
| Zabbix — VM monitoring | In progress |
| GitHub repo + ArgoCD sync | In progress |
| GPU support | 📋 Planned |
| Model improvement scripts | 📋 Planned |

---

## Architecture

```
  Intranet Browser
        │
        ▼
  ┌─────────────┐
  │   MetalLB   │  ← IP pool 192.168.0.20-40
  │             │     assegna IP esterno ai servizi
  └──────┬──────┘
         │
         ▼
  ┌───────────┐
  │  Traefik  │  ← IngressController + path-based routing
  └─────┬─────┘
        │
        ▼
  ┌─────────────────┐
  │   Open WebUI    │  ← Multi-user chat interface (post-auth session)
  │   (open-webui   │
  │    namespace)   │
  └────────┬────────┘
           │ REST API (OLLAMA_BASE_URL)
           ▼
  ┌─────────────────┐
  │     Ollama      │  ← LLM backend, shared, always-on
  │  (ollama        │     Models served via NFS from Proxmox host
  │   namespace)    │
  └─────────────────┘

  ┌─────────────────┐     ┌──────────────────────┐
  │   Prometheus    │     │        Zabbix         │
  │   + Grafana     │     │  (VM-level monitoring)│
  │ (cluster-level) │     │   192.168.0.20        │
  └─────────────────┘     └──────────────────────┘
```

---

## Infrastructure

### Hardware

| Host | Specs |
|---|---|
| Proxmox host (lab2) | AMD Ryzen 7 PRO 4750G, 32GB RAM, no dedicated GPU |
| IP | 192.168.0.44 |

### Virtual Machines

| VM | Role | IP | CPU | RAM | Disk |
|---|---|---|---|---|---|
| control-plane | K8s control plane | 192.168.0.100 | 4 vCPU | 6GB | 20GB |
| worker-01 | K8s worker | 192.168.0.101 | 4 vCPU | 6GB | 20GB |
| worker-02 | K8s worker (Ollama) | 192.168.0.102 | 10 vCPU | 20GB | 50GB |
| worker-03 | K8s worker | 192.168.0.103 | 4 vCPU | 6GB | 20GB |

> worker-02 has more resources because it runs Ollama (LLM inference is CPU and RAM intensive)

### Network

| Component | Value |
|---|---|
| VM network | 192.168.0.0/24 |
| Gateway | 192.168.0.1 |
| NFS server (models) | 192.168.0.44 |

---

## Repository Structure

```
2LMlocal/                     # Main repo — infra + cluster setup
├── terraform/                # Proxmox VM provisioning
│   ├── main.tf
│   ├── variables.tf
│   ├── terraform.tfvars
│   └── proxmox/
├── kubespray/                # Kubernetes installation via Ansible
│   ├── inventory/
│   └── sample/
└── docs/                     # Architecture and documentation

2LMlocal-k8s/                 # Separate repo — Kubernetes manifests
├── ollama/                   # LLM backend
│   ├── pv.yaml
│   ├── pvc.yaml
│   ├── pvc-data.yaml
│   ├── deployment.yaml
│   └── service.yaml
├── open-webui/               # Chat UI
│   ├── pvc.yaml
│   ├── deployment.yaml
│   ├── service.yaml
│   └── ingressroute.yaml
├── monitoring/               # Prometheus + Grafana
└── argocd/                   # ArgoCD applications
```

---

## Stack

```
Terraform (bpg/proxmox)
    → Kubespray (Ansible)
        → Kubernetes 1.35.1
            → Calico (CNI)
            → Traefik (Ingress)
            → Ollama (LLM backend)
            → Open WebUI (Frontend)
            → Prometheus + Grafana (Cluster monitoring)
            → ArgoCD (GitOps)
Zabbix (VM-level monitoring) # Coming
```

---

## Models

| Model | Namespace | Type | Hardware |
|---|---|---|---|
| Mistral 7B Instruct Q4_K_M | ollama | General purpose | CPU |
| Qwen 2.5 7B Instruct | ollama | General purpose | CPU |

## Access

| Service | URL |
|---|---|
| Open WebUI | http://openwebui.local |
| Grafana | http://grafana.local (TBD) |
| ArgoCD | http://argocd.local (TBD) |

---



## Notes

- **GPU support**: planned. The architecture is GPU-ready — add `nodeSelector` and NVIDIA/AMD device plugin when hardware is available.
- **Scaling**: Ollama processes one request at a time on CPU. Multiple replicas require multiple copies of the model in RAM.
- **Models storage**: models are stored on the Proxmox host and served via NFS. This avoids downloading models on every pod restart.
- **Open WebUI license**: MIT. Free to use, modify, and redistribute with attribution.