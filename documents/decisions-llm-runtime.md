### Decisions: Local LLM Runtime (Windows)

**Date**: 2025-08-09

1) Runtime/UI
- Decision: Ollama (Windows native) + Open WebUI.
- Rationale: Minimal ops, robust model management, clean REST API, simple UX.

2) Models (baseline)
- Decision: `Qwen2.5-7B-Instruct (Q4_K_M)`, `Qwen2.5-Coder-7B (Q4_K_M)`, optional `Phi-3.5-mini-instruct`.
- Rationale: Best quality/throughput at 7B for 8 GB VRAM; coding strength; small fallback.

3) Context length
- Decision: 8k default.
- Rationale: Throughput and memory efficiency; increase only when required.

4) GPU plan
- Decision: Use CUDA on GTX 1080 (now) and GTX 2070 (later). CPU-only fallback for tiny models.
- Rationale: Stable performance on 7B Q4; avoids 13B on 8 GB VRAM.

5) Data root and layout
- Decision: `E:\OLLAMA` as configurable DATA_ROOT. Subfolders: `models/ollama`, `webui`, `rags/chroma`, `corpus`, `prompts`, `configs`, `exports`.
- Rationale: Single portable root makes migration and backup trivial.

6) RAG store (Phase 3)
- Decision: Chroma (on-disk) under `E:\OLLAMA\rags\chroma`.
- Rationale: Simple file-backed store; easy to move across PCs.

7) Chat history storage
- Decision: Open WebUI data under `E:\OLLAMA\webui` with periodic exports to `exports/`.
- Rationale: Centralized, portable history and settings.

8) Intranet access
- Decision: Bind services to LAN (`0.0.0.0`), restrict via Windows Firewall to the private subnet; optional reverse proxy with basic auth and optional TLS.
- Rationale: Usable across the intranet while keeping a security boundary.

9) Model cache migration
- Decision: Prefer re-pulling models per PC; optionally copy `models/ollama` to avoid downloads.
- Rationale: Simpler by default; copy when bandwidth/time is constrained.

10) Configuration mechanism
- Decision: PowerShell env script `config/env.ps1` to set `DATA_ROOT` and service endpoints.
- Rationale: No binary changes; portable across PCs; easy to update.

11) Docker stance
- Decision: Not default on Windows; prefer native. Revisit if requirements change.
- Rationale: Docker/WSL2 friction on Windows; native path is smoother.

