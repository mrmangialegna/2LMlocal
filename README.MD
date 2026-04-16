# 2LMlocal

An on-premise AI platform for small and medium businesses that want to run local language models without relying on external cloud providers.

**Privacy by design — your data never leaves the company network.**

---

## Project Status

| Component | Status| Notes |
|---|---|---|
| Terraform — VM provisioning | Done | 
| Kubespray — Kubernetes install | Done | 
| Calico — CNI | Done | 
| Helm | Done | 
| MetalLB | Done | via Helm 
| Traefik — Ingress Controller | Done | via Helm 
| Prometheus + Grafana |  Done | via Helm 
| ArgoCD |  Done | via Helm 
| Ollama — LLM backend | Done | 
| Ollama Exporter | Done | Prometheus metrics proxy |
| Open WebUI — Frontend | Done | 
| Docker Registry | Done | Dedicated node, NodePort 30964 |
| Zabbix — VM monitoring | In progress | 
| GPU support | Planned | 
| Model improvement scripts |  Planned | 

---

## Architecture

```
  Intranet Browser
        │
        ▼
  ┌─────────────┐
  │   MetalLB   │  ← IP pool 192.168.0.20-40
  │             │     assigns external IP to LoadBalancer services
  └──────┬──────┘
         │
         ▼
  ┌───────────┐
  │  Traefik  │  ← IngressController + Host-based routing
  └─────┬─────┘
        │
        ▼
  ┌─────────────────┐
  │   Open WebUI    │  ← Multi-user chat interface
  │  (open-webui    │     authentication, sessions, chat history
  │   namespace)    │
  └────────┬────────┘
           │ REST API
           ▼
  ┌──────────────────────┐
  │   ollama-exporter    │  ← Transparent proxy + Prometheus metrics
  │   (ollama namespace) │     collects: requests, latency, tokens/s
  └────────┬─────────────┘
           │
           ▼
  ┌─────────────────┐
  │     Ollama      │  ← LLM backend, shared, always-on
  │  (ollama        │     Models served via NFS from Proxmox host
  │   namespace)    │
  └─────────────────┘

  ┌─────────────────┐     ┌──────────────────────┐
  │   Prometheus    │     │        Zabbix         │
  │   + Grafana     │     │  (VM-level monitoring)│
  │ (cluster-level) │     │   planned             │
  └─────────────────┘     └──────────────────────┘

  ┌─────────────────┐
  │ Docker Registry │  ← Private image registry
  │ (registry node) │     NodePort 30964
  └─────────────────┘
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
| llm-worker | K8s worker — Ollama | 192.168.0.102 | 10 vCPU | 20GB | 50GB |
| registry | K8s worker — Docker Registry | 192.168.0.22 | 1 vCPU | 2GB | 50GB |

> llm-worker is intentionally over-provisioned — LLM inference is CPU and RAM intensive.
> registry node has a dedicated taint: `dedicated=registry:NoSchedule`

### Network

| Component | Value |
|---|---|
| VM network | 192.168.0.0/24 |
| Gateway | 192.168.0.1 |
| NFS server (models) | 192.168.0.44 |
| MetalLB IP pool | 192.168.0.20 — 192.168.0.40 |
| Traefik external IP | 192.168.0.201 |
| Docker Registry | 192.168.0.22:30964 |

### DNS — /etc/hosts (client machines)

```
192.168.0.201  openwebui.local
192.168.0.201  grafana.local
192.168.0.201  prometheus.local
192.168.0.201  argocd.local
192.168.0.22   registry.local
```

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

k8s-LLM/                      # Separate repo — Kubernetes manifests
├── metalLB/                  # MetalLB config + all IngressRoutes
├── ollama/                   # LLM backend
├── ollama-exporter/          # Prometheus metrics proxy
├── open-webui/               # Chat UI
└── registry/                 # Docker Registry
```

---

## Stack

```
Terraform (bpg/proxmox)
    → Kubespray (Ansible)
        → Kubernetes 1.35.1
            → Calico (CNI)
            → MetalLB (LoadBalancer)
            → Traefik (Ingress)
            → Ollama (LLM backend)
            → Ollama Exporter (Prometheus proxy)
            → Open WebUI (Frontend)
            → Docker Registry (Private image registry)
            → Prometheus + Grafana (Cluster monitoring)
            → ArgoCD (GitOps)
Zabbix (VM-level monitoring) — planned
```

---

## Models

| Model | Type | Hardware |
|---|---|---|
| Mistral 7B Instruct Q4_K_M | General purpose | CPU |
| Qwen 2.5 7B Instruct | General purpose | CPU |
| Deepseek Coder V2 Lite 7B | Code | CPU / GPU — planned |
| LLaVA 1.6 13B | Multimodal | GPU recommended — planned |

Models are stored on the Proxmox host at `/usr/share/ollama/.ollama` and served to the cluster via NFS.

---

## Prerequisites

### NFS on Proxmox host (lab2)

```bash
apt install nfs-kernel-server -y
echo "/usr/share/ollama/.ollama 192.168.0.0/24(rw,sync,no_subtree_check,no_root_squash)" >> /etc/exports
exportfs -ra
systemctl restart nfs-kernel-server

# verify
showmount -e 192.168.0.44
```

### NFS client on all worker nodes

```bash
sudo apt install nfs-common -y
```

### Docker on lab2 (for building images)

```bash
apt install docker.io -y

# configure insecure registry
cat > /etc/docker/daemon.json <<EOF
{
  "insecure-registries": ["192.168.0.22:30964"]
}
EOF

systemctl restart docker
```

### StorageClass

```bash
kubectl apply -f https://raw.githubusercontent.com/rancher/local-path-provisioner/master/deploy/local-path-storage.yaml
```

### Helm components

```bash
# MetalLB
helm repo add metallb https://metallb.github.io/metallb
helm install metallb metallb/metallb -n metallb --create-namespace

# Traefik
helm repo add traefik https://traefik.github.io/charts
helm install traefik traefik/traefik -n kube-system

# Prometheus + Grafana
helm repo add prometheus-community https://prometheus-community.github.io/helm-charts
helm install prometheus prometheus-community/kube-prometheus-stack \
  -n monitoring --create-namespace --server-side

# ArgoCD
helm repo add argo https://argoproj.github.io/argo-helm
helm install argocd argo/argo-cd -n argocd --create-namespace
```

---

## Access

| Service | URL |
|---|---|
| Open WebUI | http://openwebui.local |
| Grafana | http://grafana.local |
| Prometheus | http://prometheus.local |
| ArgoCD | http://argocd.local |
| Docker Registry API | http://registry.local:30964/v2/ |

---

## Notes

- GPU support: planned. Architecture is GPU-ready — add `nodeSelector` and NVIDIA/AMD device plugin when hardware is available.
- Scaling: Ollama processes one request at a time on CPU. Multiple replicas require multiple copies of the model in RAM.
- Models storage: models are stored on the Proxmox host and served via NFS. This avoids re-downloading models on every pod restart.
- ollama-exporter: acts as a transparent proxy between Open WebUI and Ollama. All requests pass through it and metrics are exposed to Prometheus.
- Docker Registry: private registry running on a dedicated node with taint `dedicated=registry:NoSchedule`. Exposed via NodePort 30964.
- Open WebUI license: MIT. Free to use, modify, and redistribute with attribution.