### Using Ollama with IDEs and tools (Cursor, Tabby, Continue, etc.)

This guide explains how to plug your local Ollama server into common editors and tools. All examples assume your server is running at `http://127.0.0.1:11434` (or `http://<LAN-IP>:11434` on your intranet) and models live in `E:\OLLAMA` per our setup.

### Prerequisites
- Start the server: `scripts/start-ollama.ps1` (binds to LAN per env). Verify:
  - `curl http://127.0.0.1:11434/api/tags`
- Open firewall for port 11434 on Private profile: `scripts/firewall-allow.ps1 -Port 11434`
- Pull models (examples):
  - `qwen2.5:7b-instruct`
  - `qwen2.5-coder:7b`
  - `llama3.2:3b-instruct`

### Cursor (Native Ollama integration)
Cursor can talk to Ollama directly.
- In Cursor settings → Models:
  - Add a local model using provider “Ollama” (or “Local Model”), base URL `http://127.0.0.1:11434`
  - Enter model name exactly as shown by `api/tags`, e.g. `qwen2.5:7b-instruct`
  - Set temperature 0.1–0.3 for code; top_p 0.9; max tokens as needed
- If using across your LAN, use `http://<LAN-IP>:11434` and ensure firewall rules allow your subnet

### VS Code – Continue (highly recommended)
Continue has first-class Ollama support via config.
- Command Palette → “Continue: Open Config” → add entries:
```json
{
  "models": [
    { "title": "Qwen 7B Chat", "provider": "ollama", "model": "qwen2.5:7b-instruct" },
    { "title": "Qwen 7B Code", "provider": "ollama", "model": "qwen2.5-coder:7b" }
  ],
  "embeddingsProvider": { "provider": "ollama", "model": "nomic-embed-text" }
}
```
- If Continue runs on another PC, set `OLLAMA_BASE_URL` and the model config to your `http://<LAN-IP>:11434`

### Tabby (two patterns)
Tabby is a self-hosted code assistant server. You can either:
1) Use Tabby’s own models (managed by Tabby) – independent of Ollama
2) Use OpenAI-compatible requests pointing at an Ollama-to-OpenAI proxy (below)

If you want Tabby (or any OpenAI-only client) to drive Ollama, deploy a lightweight OpenAI-compatible proxy:
- Option A: LiteLLM gateway
  - Install in a Python venv: `pip install litellm`
  - Start gateway (maps OpenAI routes to Ollama):
    - `litellm --host 0.0.0.0 --port 4000 --adapter ollama --ollama_base_url http://127.0.0.1:11434`
  - Client settings:
    - Base URL: `http://<LAN-IP>:4000/v1`
    - API Key: any non-empty string
    - Model: your Ollama tag (e.g., `qwen2.5:7b-instruct`)
- Option B: Other OpenAI-proxy tools (similar wiring)

Notes
- The proxy does not send data to cloud LLMs; it only adapts client API shape to Ollama.
- Keep the proxy on the same host as Ollama for lowest latency.

### Open WebUI (already configured)
- Base URL to Ollama is set via `OLLAMA_BASE_URL` in `config/env.ps1`
- For intranet use, access `http://<LAN-IP>:8080`, create admin, then disable self‑signup in Settings → Authentication

### Model and performance tips
- For code: `qwen2.5-coder:7b` (temp 0.1–0.3)
- For chat: `qwen2.5:7b-instruct` (temp 0.3–0.7)
- Light fallback: `llama3.2:3b-instruct`
- Keep context ~8k on 8 GB VRAM

### Networking and security
- Bind Ollama to all interfaces (already done via env), but restrict inbound traffic to your Private subnet using the firewall script
- For multi-user scenarios, put a reverse proxy (Caddy/Nginx) with basic auth in front of any public endpoints

### Troubleshooting quick checks
- Server up: `curl http://127.0.0.1:11434/api/tags`
- LAN reachability: `curl http://<LAN-IP>:11434/api/tags` from another PC
- Cursor can’t see models: confirm the model tag matches exactly; confirm base URL
- Client expects OpenAI routes: front it with LiteLLM as shown above

### Appendix: Minimal cURL tests
- Basic completion (streaming off):
```powershell
curl -s http://127.0.0.1:11434/api/generate -H "Content-Type: application/json" -d '{
  "model":"qwen2.5:7b-instruct",
  "prompt":"Write a Python function to reverse a string.",
  "stream": false
}'
```
- Chat format:
```powershell
curl -s http://127.0.0.1:11434/api/chat -H "Content-Type: application/json" -d '{
  "model":"qwen2.5:7b-instruct",
  "messages":[{"role":"user","content":"Summarize SOLID principles"}]
}'
```

