### Runbook: Local LLM on Windows (Ollama + Open WebUI)

This runbook captures the exact steps, commands, and health checks to set up and operate the stack using the configurable data root `E:\OLLAMA`.

### Directory layout (portable state)
- `E:\OLLAMA\models\ollama` — model cache
- `E:\OLLAMA\webui` — Open WebUI users, chats, settings
- `E:\OLLAMA\rags\chroma` — RAG vector store (Phase 3)
- `E:\OLLAMA\{corpus|prompts|configs|exports}` — content and backups

### One-time prerequisites
- Windows 10 (19045) or later
- NVIDIA GPU recommended (GTX 1080/2070) or CPU-only for small models
- Install Ollama for Windows (desktop installer). The CLI is typically at:
  - `C:\Users\<YOU>\AppData\Local\Programs\Ollama\ollama.exe`
- Install Python 3.x (for Open WebUI without Docker)
 - Free space guidance (all three locations matter):
   - C: system drive — Visual C++ Build Tools + Windows SDK can need several GB; keep at least 10–15 GB free
   - E: LLM data drive — models and caches (`E:\OLLAMA`) can consume tens of GB; keep ample headroom
   - F: working directory drive — the repo, virtualenv, and temporary build artifacts still need space; keep at least 10 GB free

### Environment (required per session)
Run from the repo root `F:\Workplaces\Ollama-Local-Setup`:

```powershell
cd F:\Workplaces\Ollama-Local-Setup
. .\config\env.ps1
```

### Initialize portable data root
```powershell
.\n+\scripts\setup-data-root.ps1
```

### Start Ollama server (uses `E:\OLLAMA`)
```powershell
.
\scripts\start-ollama.ps1
```

If you need to open the firewall on the Private profile for intranet access:
```powershell
.
\scripts\firewall-allow.ps1 -Port 11434 -RuleName "Ollama 11434 (Private)"
```

### Known-good model pulls
If DNS is unreliable, first set your adapter DNS to 1.1.1.1 and 8.8.8.8, then `ipconfig /flushdns`.

```powershell
$ollama = "$env:LOCALAPPDATA\Programs\Ollama\ollama.exe"
& $ollama --version

# Baseline models (set A)
& $ollama pull qwen2.5:7b-instruct
& $ollama pull qwen2.5-coder:7b
& $ollama pull llama3.2:3b-instruct

# If you see "pull model manifest: file does not exist", your Ollama registry
# may be older. Use these fallback tags (set B):
# General/chat: older but reliable
& $ollama pull llama3.1:8b-instruct
# Coding alternatives (use any one):
& $ollama pull deepseek-coder-v2-lite:instruct
& $ollama pull codegemma:7b-instruct
# Lightweight fallback:
& $ollama pull phi3:mini-4k-instruct
```

### Health checks (cURL)
- List models on localhost:
```powershell
curl http://127.0.0.1:11434/api/tags
```
- Simple generate (replace model if needed):
```powershell
curl -s http://127.0.0.1:11434/api/generate -H "Content-Type: application/json" -d '{"model":"qwen2.5:7b-instruct","prompt":"hello"}'
```
- From another PC on the LAN (replace with your LAN IP):
```powershell
curl http://<LAN-IP>:11434/api/tags
```

### Install and run Open WebUI (single-user, local auth)

#### Simple method (one command)
Uses an installer script that redirects caches to E:, creates a clean venv with Python 3.12/3.11, installs Open WebUI, and starts it.
```powershell
.
\scripts\install-webui-e.ps1
```
If it fails due to missing native toolchain, install Microsoft C++ Build Tools (see note below) and re-run.

#### Manual method (step-by-step)
Create a Python venv in this repo and install Open WebUI:
```powershell
REM Prefer Python 3.12 or 3.11 (Open WebUI currently does not publish wheels for 3.13)
py -3.12 -m venv .venv  # or: py -3.11 -m venv .venv
. .\.venv\Scripts\Activate.ps1
pip config set global.cache-dir "$env:PIP_CACHE_DIR"
pip install --upgrade pip
pip install open-webui
```
Start Open WebUI with our environment variables so data goes to `E:\OLLAMA\webui` and Ollama is pre-wired:
```powershell
. .\config\env.ps1
python -m open_webui
```
Note: If installation shows an error building `chroma-hnswlib` (needed for Chroma’s fast index), install Microsoft C++ Build Tools and re-run install:
- Download and install “Microsoft C++ Build Tools” (Desktop C++ build tools) from [Visual C++ Build Tools](https://visualstudio.microsoft.com/visual-cpp-build-tools/)
- Then re-run: `pip install --upgrade pip && pip install --upgrade open-webui`

If you hit space/permission issues during install:
- Ensure `. .\config\env.ps1` is loaded so `PIP_CACHE_DIR`, `TEMP`, and `TMP` point to `E:\OLLAMA`
- Optionally set persistent user-level variables so new shells inherit the E: paths:
  - `setx PIP_CACHE_DIR E:\OLLAMA\cache\pip`
  - `setx HF_HOME E:\OLLAMA\cache\huggingface`
  - `setx TRANSFORMERS_CACHE E:\OLLAMA\cache\huggingface`
  - `setx PLAYWRIGHT_BROWSERS_PATH E:\OLLAMA\cache\playwright`
  - `setx TEMP E:\OLLAMA\temp`
  - `setx TMP E:\OLLAMA\temp`
  - Reopen the terminal

Open `http://127.0.0.1:8080`:
- Create the admin account
- Disable self-signup in Settings → Authentication

If you want intranet access to Open WebUI:
```powershell
.
\scripts\firewall-allow.ps1 -Port 8080 -RuleName "Open WebUI 8080 (Private)"
```

Optional: run Open WebUI via helper script (after creating the venv):
```powershell
.
\scripts\start-webui.ps1
```

### Everyday usage
- Load environment, ensure server is running, and check models:
```powershell
cd F:\Workplaces\Ollama-Local-Setup
. .\config\env.ps1
curl http://127.0.0.1:11434/api/tags
```
- Launch Open WebUI:
```powershell
. .\.venv\Scripts\Activate.ps1
python -m open_webui
```

### Troubleshooting
- DNS failures when pulling models:
  - Set DNS to 1.1.1.1 and 8.8.8.8 → `ipconfig /flushdns`
  - If still failing: `netsh winsock reset` (reboot)
- Port in use (11434/8080): find owners
```powershell
Get-NetTCPConnection -LocalPort 11434 | Select LocalAddress,State,OwningProcess
Get-Process -Id <OwningProcess>
```
- Desktop app using C: drive:
  - Close the desktop UI and start the server via `scripts\start-ollama.ps1` so it honors `E:\OLLAMA`.
- Avoid desktop app "Web Search/Turbo"; it requires a cloud account. Use Open WebUI and (optionally) self-hosted SearXNG later.

- OperationalError: table embeddings already exists (Chroma)
  - Cause: stale/partial Chroma store at `CHROMA_PERSIST_DIRECTORY`
  - Fix (destructive for RAG index only):
    - Stop WebUI
    - `Rename-Item E:\OLLAMA\rags\chroma E:\OLLAMA\rags\chroma.bak` (or delete it if you don’t need it)
    - Start WebUI; a fresh store will be created
  - Non-destructive alternative: point `CHROMA_PERSIST_DIRECTORY` to a new empty folder in `config\env.ps1` and restart

### Migration and backups
- To move to another PC, copy these folders while services are stopped:
  - `E:\OLLAMA\webui`, `E:\OLLAMA\rags\chroma`, `E:\OLLAMA\corpus`, `E:\OLLAMA\prompts`, `E:\OLLAMA\configs`, `E:\OLLAMA\exports`
  - Optionally copy `E:\OLLAMA\models\ollama` to avoid re-downloading models

### Appendix: Command index
- Load env: `. .\config\env.ps1`
- Start server: `scripts\start-ollama.ps1`
- Allow firewall: `scripts\firewall-allow.ps1 -Port <port>`
- Pull model: `& "$env:LOCALAPPDATA\Programs\Ollama\ollama.exe" pull <model:tag>`
- List models (cURL): `curl http://127.0.0.1:11434/api/tags`
- Test generate (cURL): `curl -s http://127.0.0.1:11434/api/generate -H "Content-Type: application/json" -d '{"model":"<model>","prompt":"hello"}'`
- Start Open WebUI: `python -m open_webui`

