# Building a Local AI Platform from Scratch — What I Learned Deploying LLMs on Kubernetes

Over the past few weeks I've been working on a portfolio project that pushed me well outside my comfort zone. The goal: build a fully automated, on-premise AI platform for small businesses that want to run local language models without relying on external cloud providers.

No Azure OpenAI. No AWS Bedrock. Just your own hardware, your own data, full control.

Here's what I built — and more importantly, what broke along the way.

---

## The Architecture

The platform runs three specialized LLM namespaces on a multi-node Kubernetes cluster:

- **llm-general** — Mistral 7B for general Q&A and document analysis
- **llm-code** — Deepseek Coder for code generation and debugging
- **llm-multimodal** — LLaVA for image and document understanding

Each namespace runs Ollama as the inference runtime with GGUF quantized models, exposed through Traefik as the ingress controller with path-based routing. A lightweight HTML/JS frontend sits in front of everything with three entry points — one per model.

The full stack: **Terraform → Kubespray → Kubernetes → Traefik → Ollama → Zabbix/Prometheus+Grafana → ArgoCD**

---

## Infrastructure as Code — All the Way Down

One of the goals was to make the entire infrastructure reproducible from a single `terraform apply`.

I used the **bpg/proxmox** Terraform provider to provision four VMs on a Proxmox cluster — one control plane and three worker nodes, each dedicated to a specific LLM. Cloud-init handles OS configuration at first boot: hostname, static IP, SSH key injection, user setup.

```
terraform apply
  → 4 VMs provisioned on Proxmox
  → cloud-init configures each VM at boot
  → Kubespray bootstraps the Kubernetes cluster
  → ArgoCD takes over for continuous deployment
```

Nothing is configured manually. If the cluster dies, `terraform apply` brings it back.

---

## What Actually Broke (and What I Learned)

This is the part nobody talks about in tutorials.

**Nested virtualization** — Running Proxmox inside a VM requires `cpu { type = "host" }` in the Terraform resource. Without it, QEMU exits with code 1 and you get zero useful error messages. The fix is one line. Finding it takes hours.

**Node name mismatch** — My Proxmox node was named `local`, not `pve` (the default). Terraform was cloning VMs onto `pve` which didn't exist. The error message said `hostname lookup 'pve' failed` — which, once you know what to look for, tells you exactly what's wrong. Reading error messages carefully is a skill that only comes with practice.

**cloud-init DataSourceNoCloud** — cloud-init was running but not reading its configuration. The fix was regenerating the cloud-init image from the Proxmox UI after Terraform applied the configuration. A lesson in understanding the difference between Terraform provisioning the hardware and cloud-init configuring the OS — they're two separate phases.

**SSH key management** — Spent more time than I'd like to admit on this. The key insight: cloud-init installs your public key on the VM automatically, but you still need to know which private key to use with `-i` when connecting. Understanding the public/private key flow properly — not just mechanically — made everything click.

---

## Why This Project Matters for a Business

Privacy regulations are tightening. Healthcare, legal, and financial firms increasingly can't send sensitive data to external APIs. A self-hosted LLM platform means:

- Data never leaves the company network
- No per-token billing that scales unpredictably
- Full control over model versions and updates
- Compliance by design, not by policy

The hardware cost for a small deployment (3 nodes, CPU-only, quantized models) is well within reach for a 50-200 person company. The operational complexity is real — which is exactly the gap a DevOps engineer fills.

---

## What's Next

The project is still in progress. On the roadmap:

- Kubespray cluster bootstrap (in progress)
- Traefik ingress with rate limiting per namespace
- HPA for automatic replica scaling under load
- Prometheus + Grafana for LLM-specific metrics
- ArgoCD GitOps pipeline
- NFS persistent storage for model weights

The full repo is public on GitHub: [github.com/mrmangialegna](https://github.com/mrmangialegna)

---

*If you're exploring local AI deployment or have questions about the architecture, I'd love to connect.*

*#DevOps #Kubernetes #AI #LLM #Terraform #OpenSource #Infrastructure #CloudNative*
