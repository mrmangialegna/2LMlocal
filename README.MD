!!!PROJECT AT PLANNING STAGE!!!

TITLE: 2LMlocal

An on-premise AI platform for small and medium businesses that want to run local language models without relying on external cloud providers.

Privacy by design — your data never leaves the company network.

---

# Architecture -- Ideally something like that

```
  Intranet Browser
        │
        ▼
  ┌───────────┐
  │  Traefik  │  ← IngressController + path-based routing
  └─────┬─────┘
        │
  ┌─────┼──────────────────────┐
  │     │                      │
  ▼     ▼                      ▼
┌──────────┐  ┌────────────┐  ┌───────────────┐
│llm-code  │  │llm-general │  │llm-multimodal │
│          │  │            │  │               │
│ Ollama   │  │  Ollama    │  │   Ollama      │
│ Deepseek │  │  Mistral   │  │   LLaVA       │
│ Coder 7B │  │  7B        │  │   1.6         │
│          │  │            │  │               │
│2 replicas│  │2 replicas  │  │ 2 replicas    │
└──────────┘  └────────────┘  └───────────────┘

        ┌─────────────┐
        │  monitoring │  ← Prometheus + Graphana namespace
        └─────────────┘
```

---

## Models -- they may vary

| Namespace | Model | Hardware |
|---|---|---|
| `llm-code` | Deepseek Coder V2 Lite 7B (GGUF Q4) | CPU / GPU optional |
| `llm-general` | Mistral 7B Instruct (GGUF Q4) | CPU / GPU optional |
| `llm-multimodal` | LLaVA 1.6 13B (GGUF Q4) | GPU recommended |

---

## Repository Structure -- just a draft

```
/
├── docs/                     # Architecture, models, hardware requirements
├── k8s/
│   ├── traefik/              # IngressController and routing
│   ├── llm-code/             # Namespace, Deployment, Service
│   ├── llm-general/          # Namespace, Deployment, Service
│   ├── llm-multimodal/       # Namespace, Deployment, Service
│   └── monitoring/           # Zabbix
├── frontend/                 # Welcome page HTML/JS
└── scripts/                  # Setup and utilities
```

