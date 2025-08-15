### Collaboration and Operating Rules

**Date**: 2025-08-09

### Process
- Plan → Decide → Implement → Validate → Iterate. No implementation until decisions are documented and approved.
- PRD-first workflow with concise decision records.

### Privacy and security
- Privacy-first: avoid external telemetry and cloud dependencies. Offline after initial model pulls.
- Intranet use is permitted with scoped firewall rules; consider reverse proxy with basic auth for multi-user access.

### Documentation
- `chats/` contains session transcripts or summaries.
- `documents/` contains PRDs, decisions, operating rules, and ops notes.
- Naming:
  - `chats/YYYY-MM-DD-session.md`
  - `documents/PRD-local-llm.md`
  - `documents/decisions-llm-runtime.md`
  - `documents/rules-collaboration.md`

### Change control
- Each material decision is added to `documents/decisions-llm-runtime.md` with a short rationale and date.

### Environment and tooling
- Windows-native first. Avoid Docker/WSL2 by default due to known friction on Windows; may revisit later.
- NVIDIA CUDA preferred; CPU-only acceptable for small models when GPU is busy/unavailable.

### Networking
- Bind services to LAN only when needed; otherwise default to localhost.
- Restrict inbound rules to the private subnet. Add CORS only for trusted intranet origins.

### Portability
- Single data root: `E:\OLLAMA` (configurable). Subfolders for `models/ollama`, `webui`, `rags/chroma`, `corpus`, `prompts`, `configs`, `exports`.
- Stop services before copying state between machines.

### Model usage guidance
- Prioritize 7B Q4 models on 8 GB VRAM (e.g., Qwen2.5 7B Instruct/Coder).
- Default context length 8k; use longer contexts only when necessary. Prefer RAG over very long contexts.

### Backups
- Periodic exports of chats/settings to `exports/`.

