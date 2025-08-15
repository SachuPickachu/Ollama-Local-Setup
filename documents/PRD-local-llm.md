### PRD: Local LLM Stack (Windows, portable, intranet-ready)

**Date**: 2025-08-09  
**Owner**: Local setup on Windows 10 (19045)  
**Primary machine**: GTX 1080 (8 GB VRAM)  
**Secondary machine (later)**: GTX 2070 (8 GB VRAM)  
**Data root (configurable)**: `E:\OLLAMA`

### 1) Goal
- Build a dependable, private local LLM stack for chat, coding assistance, and optional document Q&A (RAG), with low operational overhead, easy portability between PCs, and secure intranet access.

### 2) In scope
- Local inference runtime with model management and REST API.
- Web UI for daily usage.
- Configurable data root for portable state (models cache optional, chats, RAG store, configs).
- Intranet access (LAN) with security boundaries.
- Optional RAG in a later phase.

### 3) Out of scope
- Full fine-tuning or large-scale training on consumer GPUs.
- Serving 13B+ models as a default on 8 GB VRAM.

### 4) Target environment
- Windows 10 (19045), PowerShell.
- NVIDIA GPUs with CUDA (GTX 1080 now; GTX 2070 later). CPU-only fallback acceptable for small models.
- Avoid Docker/WSL2 as default due to Windows friction; may revisit later if needed.

### 5) Architecture (decided)
- Runtime: Ollama (native Windows build) for model pulls, quant support, and REST API.
- UI: Open WebUI (front-end for chat, multi-model, basic RAG later).
- Config: Single env script (`config/env.ps1`) defines the data root and endpoints.
- Data root layout under `E:\OLLAMA`:
  - `models\ollama\` — optional mirror of Ollama model cache (for migration speed)
  - `webui\` — Open WebUI state (users, chats, settings, collections)
  - `rags\chroma\` — on-disk vector store for RAG (Phase 3)
  - `corpus\` — raw documents to ingest
  - `prompts\` — reusable prompts/templates
  - `configs\` — env and config files
  - `exports\` — periodic exports/backups (chats, settings)
- Networking: Bind services to `0.0.0.0` for intranet; firewall restrict to private subnet. Optional reverse proxy (Caddy/Nginx) with basic auth and optional TLS for internal encryption.

### 6) Functional requirements
- Pull and run local GGUF models; swap models without reinstall.
- REST API (local-only by default; LAN-enabled when desired).
- Model configuration: context window, temperature, system prompt, stop tokens.
- UI supports chat history, multi-session, and model switching.
- Optional RAG: document ingestion and retrieval-augmented responses.

### 7) Non-functional requirements
- Privacy-first: no external telemetry; offline-capable after initial downloads.
- Repeatable setup with minimal moving parts; config-driven.
- Reasonable throughput on 7B-class models with 8 GB VRAM.
- Portable state across machines via the data root.

### 8) Baseline models and parameters
- General chat: `Qwen2.5-7B-Instruct` (Q4_K_M)
- Coding: `Qwen2.5-Coder-7B` (Q4_K_M)
- Lightweight fallback: `Phi-3.5-mini-instruct`
- Default context length: 8k tokens (increase only when necessary).
- Quantization: start with Q4_K_M; consider Q5 only if VRAM allows and quality is insufficient at Q4.

### 9) Security and networking
- Bind only to LAN IP (`0.0.0.0:11434` for Ollama) with Windows Firewall scoped to the private subnet.
- Optional reverse proxy: basic auth (or token) and IP allowlist; self-signed TLS if desired.
- CORS: enable only for specific intranet origins if browser apps will call the API.

### 10) Portability/migration
- Portable subfolders: `webui`, `rags\chroma`, `corpus`, `prompts`, `configs`, `exports`.
- Optional: copy `models\ollama` cache to avoid re-downloading models on a new PC.
- Stop services before copying to avoid DB corruption.
- Keep embedding model versions consistent across PCs when using RAG.

### 11) Success metrics
- Cold start to first answer < 10 minutes after initial install (excluding large model downloads).
- 7B Q4 on GPU: ~15–35 tok/s; short responses in 2–5 seconds.
- CPU-only small model remains usable for lightweight tasks.

### 12) Risks and mitigations
- VRAM limits: keep to 7B Q4; avoid 13B on 8 GB VRAM.
- Driver churn: pin stable NVIDIA drivers once performance is satisfactory.
- Long contexts reduce throughput: prefer RAG over very long context windows.
- Windows Docker/WSL2 friction: run native; revisit containers only if needed.

### 13) Rollout plan
- Phase 1: Core runtime + baseline models + Open WebUI + LAN binding + docs.
- Phase 2: API consumers (editor integrations, scripts), exports/backups.
- Phase 3 (optional): RAG with on-disk Chroma; ingestion pipeline and evaluations.

