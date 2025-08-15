# Ollama Local LLM Setup

A complete, portable local LLM stack setup for Windows with Ollama, Open WebUI, and RAG capabilities. Designed for privacy, offline operation, and intranet access.

> **⚠️ OS Support**: This project currently supports **Windows only**. Linux and macOS support is planned for future releases.

## 🚀 Quick Start

### Quick Commands Reference
```powershell
# Check status
.\scripts\status.ps1

# Start all services
.\scripts\start-all.ps1

# Stop all services
.\scripts\stop-all.ps1

# Individual service control
.\scripts\start-ollama.ps1
.\scripts\start-webui.ps1
.\scripts\stop-ollama.ps1
.\scripts\stop-webui.ps1

# Pull models
.\scripts\pull-models.ps1
```

### Prerequisites
- Windows 10/11 with Python 3.11 or 3.12
- NVIDIA GPU (GTX 1080+ recommended) or CPU fallback
- At least 24GB free on C: drive (for build tools)
- At least 400GB free (for models and data) - Configurable location
- Microsoft Visual C++ Build Tools (Desktop C++ workload + Windows 10/11 SDK)

## 🖥️ Operating System Support

### **Currently Supported**
- ✅ **Windows 10/11** (64-bit) - Full support
- ✅ **PowerShell 5.1+** or **PowerShell Core 6+**

### **Future Support (Planned)**
- 🔄 **Linux** - In development
- 🔄 **macOS** - In development

### **Why Windows-Only for Now?**
- **PowerShell Scripts**: All automation scripts use PowerShell
- **Windows Firewall**: Security scripts integrate with Windows Firewall
- **Native Performance**: Avoids Docker/WSL2 friction on Windows
- **Focus**: Ensures robust Windows experience before expanding

> **Note**: The core components (Ollama, Open WebUI) work on all platforms, but the automation scripts and security features are Windows-specific.

### First-Time Setup
1. **Clone this repository**
   ```powershell
   git clone <your-repo-url>
   cd Ollama-Local-Setup
   ```

2. **Install Ollama**
   - Download from [ollama.ai](https://ollama.ai)
   - Install and ensure it's in your PATH

3. **Setup data directories**
   ```powershell
   .\scripts\setup-data-root.ps1
   ```

4. **Configure environment**
   ```powershell
   . .\config\env.ps1
   ```

5. **Install Open WebUI**
   ```powershell
   # Option 1: E: drive optimized (recommended for limited C: space)
   .\scripts\install-webui-custom-location.ps1
   
   # Option 2: Standard installation (if C: drive has 24GB+ free)
   .\scripts\install-webui.ps1
   ```

6. **Pull initial models**
   ```powershell
   .\scripts\pull-models.ps1
   ```

   **The script now supports multiple ways to specify models:**
   
   **Option 1: Interactive mode (recommended)**
   ```powershell
   .\scripts\pull-models.ps1
   # Follow prompts to enter model names
   # Press Enter to use default models
   ```
   
   **Option 2: Direct specification**
   ```powershell
   .\scripts\pull-models.ps1 "mistral:7b" "llama3.2:8b"
   ```
   
   **Option 3: Manual commands**
   ```powershell
   # Load environment
   . .\config\env.ps1
   
   # Pull specific models
   ollama pull qwen2.5:7b-instruct
   ollama pull qwen2.5-coder:7b
   ollama pull phi3.5-mini:instruct
   
   # Verify models are loaded
   ollama list
   
   # Test a model
   ollama run qwen2.5:7b-instruct "Hello, how are you?"
   ```

**Note**: By default, data is stored in `E:\OLLAMA`. To use a different location, edit `config\env.ps1` and change the `DATA_ROOT` variable before running the setup scripts.

## 🤖 Model Management

### Available Models
Check what models you have locally:
```powershell
ollama list
```

### Pulling New Models
The `pull-models.ps1` script provides three ways to download models:

1. **Interactive Mode**: Run without parameters and follow prompts
2. **Direct Specification**: Pass model names as arguments
3. **Default Models**: Use pre-configured recommended models

**Examples:**
```powershell
# Interactive mode
.\scripts\pull-models.ps1

# Pull specific models
.\scripts\pull-models.ps1 "mistral:7b" "llama3.2:8b"

# Use default models
.\scripts\pull-models.ps1 ""
```

### Popular Model Options
- **Coding**: `codellama:7b-instruct`, `deepseek-coder:6.7b`
- **Chat**: `llama3.2:8b`, `mistral:7b`, `qwen2.5:7b-instruct`
- **Small**: `llama3.2:3b`, `phi3.5:mini-instruct`

## 🎯 Start/Stop Instructions

### Check Status
```powershell
# Check if services are running
.\scripts\status.ps1
```

### Start the Stack

#### Option 1: Start Everything (Recommended)
```powershell
# Start all services automatically
.\scripts\start-all.ps1
```

**What this script does:**
- Checks if services are already running
- Starts Ollama first, waits for it to be ready
- Starts Open WebUI, waits for it to be ready
- Verifies both services are working
- Shows access URLs and helpful tips

#### Option 2: Start Individual Services
```powershell
# Start Ollama server
.\scripts\start-ollama.ps1

# Start Open WebUI (in new terminal)
.\scripts\start-webui.ps1
```

#### Option 2: Manual Start
```powershell
# Load environment
. .\config\env.ps1

# Start Ollama
$env:OLLAMA_HOST = "0.0.0.0:11434"
$env:OLLAMA_MODELS = "$env:DATA_ROOT\models\ollama"
ollama serve

# Start Open WebUI (in new terminal)
. .\config\env.ps1
. .\.venv\Scripts\Activate.ps1
open-webui serve
```

### Manual Setup (Complete Step-by-Step)
```powershell
# 1. Navigate to working directory
cd F:\Workplaces\Ollama-Local-Setup

# 2. Load environment variables
. .\config\env.ps1

# 3. Create and activate virtual environment
py -3.12 -m venv .venv
. .\.venv\Scripts\Activate.ps1

# 4. Install Open WebUI with cache redirection
pip config set global.cache-dir "$env:PIP_CACHE_DIR"
pip install open-webui==0.6.18

# 5. Start services manually
# Terminal 1: Ollama
$env:OLLAMA_HOST = "0.0.0.0:11434"
$env:OLLAMA_MODELS = "$env:DATA_ROOT\models\ollama"
ollama serve

# Terminal 2: Open WebUI
. .\config\env.ps1
. .\.venv\Scripts\Activate.ps1
open-webui serve
```

### Stop the Stack

#### Option 1: Stop Everything (Recommended)
```powershell
# Stop all services gracefully
.\scripts\stop-all.ps1
```

#### Option 2: Stop Individual Services
```powershell
# Stop Open WebUI gracefully
.\scripts\stop-webui.ps1

# Stop Ollama gracefully
.\scripts\stop-ollama.ps1
```

#### Option 3: Manual Stop (Emergency)
```powershell
# Stop Open WebUI (Ctrl+C in its terminal)
# Stop Ollama
Stop-Process -Name "ollama" -Force

# ⚠️ WARNING: Force killing can cause data corruption
# Use the stop scripts above for normal operation
```

### Verify Services
```powershell
# Check Ollama
curl http://127.0.0.1:11434/api/tags

# Check Open WebUI
curl http://127.0.0.1:8080/api/version
```

## 🌐 Access Points

- **Open WebUI**: http://127.0.0.1:8080 (or http://localhost:8080)
- **Ollama API**: http://127.0.0.1:11434
- **Intranet Access**: http://<your-lan-ip>:8080 and http://<your-lan-ip>:11434

⚠️ **Security Warning**: By default, these endpoints are accessible to anyone on your network without authentication. Use the security scripts to enable authentication and restrict access.

## 📁 Directory Structure

```
$env:DATA_ROOT\ (default: E:\OLLAMA)
├── models\ollama\          # Ollama models
├── webui\                  # Open WebUI data (chats, users, settings)
├── rags\chroma\           # RAG vector database
├── cache\                  # Pip, HuggingFace, Playwright caches
└── exports\                # Chat exports, model backups
```

## 🔧 Configuration

### Environment Variables
- `DATA_ROOT`: Main data directory (default: `E:\OLLAMA`, configurable in `config\env.ps1`)
- `OLLAMA_HOST`: Ollama binding (default: `0.0.0.0:11434` for intranet)
- `OLLAMA_MODELS`: Model storage path (`$env:DATA_ROOT\models\ollama`)
- `DATA_DIR`: Open WebUI data path (`$env:DATA_ROOT\webui`)
- `CHROMA_PERSIST_DIRECTORY`: RAG database path (`$env:DATA_ROOT\rags\chroma`)

### Security Configuration
```powershell
# Set up authentication and access control
.\scripts\setup-security.ps1

# Configure firewall for specific IPs only (recommended)
.\scripts\firewall-restrict.ps1
```

### Firewall Rules
```powershell
# Allow intranet access (run as Administrator)
.\scripts\firewall-allow.ps1

# ⚠️ WARNING: This opens ports to ALL devices on your network
# For production use, consider .\scripts\firewall-restrict.ps1 instead
```

## 🚨 Troubleshooting

### Common Issues

#### 1. "ollama command not found"
**Problem**: Ollama not in PATH

**Solution**: 
```powershell
# Find Ollama location
Get-ChildItem -Path "$env:LOCALAPPDATA\Programs\Ollama" -Recurse -Name "ollama.exe"
# Use full path in scripts or add to PATH
```

#### 2. "No space left on device" during installation
**Problem**: C: drive space insufficient

**Solution**:
```powershell
# Option 1: Use installer which takes custom location from environment variable (recommended)
.\scripts\install-webui-custom-location.ps1

# Option 2: Force all caches to DATA_ROOT drive manually
. .\config\env.ps1
pip config set global.cache-dir "$env:PIP_CACHE_DIR"
```

#### 3. "Python version not supported"
**Problem**: Open WebUI requires Python 3.11-3.12

**Solution**:
```powershell
# Install Python 3.12 alongside existing
winget install Python.Python.3.12
# Create venv with specific version
py -3.12 -m venv .venv
```

#### 4. "table embeddings already exists"
**Problem**: RAG database conflict

**Solution**:
```powershell
# Option 1: Rename existing database
Rename-Item "$env:DATA_ROOT\rags\chroma" "$env:DATA_ROOT\rags\chroma_backup"
# Option 2: Point to new directory in config/env.ps1
$env:CHROMA_PERSIST_DIRECTORY = "$env:DATA_ROOT\rags\chroma_new"
```

#### 5. "Permission denied" on cache
**Problem**: Locked pip cache files

**Solution**:
```powershell
.\scripts\fix-cache-permissions.ps1
# Or manually clear cache
pip cache purge
```

#### 6. Open WebUI not starting
**Problem**: Incorrect startup command

**Solution**:
```powershell
# Use the CLI entrypoint
open-webui serve
# NOT: python -m open_webui
```

#### 7. Models not loading / downloading
**Problem**: Network/DNS issues

**Solution**:
```powershell
# Set reliable DNS
netsh interface ip set dns "Ethernet" static 1.1.1.1
netsh interface ip add dns "Ethernet" 8.8.8.8 index=2
# Flush DNS
ipconfig /flushdns
```

#### 8. "Microsoft C++ Build Tools required"
**Problem**: Missing build tools for RAG dependencies

**Solution**:
```powershell
# Install build tools (requires C: drive space)
winget install Microsoft.VisualStudio.2022.BuildTools
# Select: Desktop C++ workload + Windows 10/11 SDK
```

#### 9. Security and Access Issues
**Problem**: Unauthorized access or security concerns

**Solution**:
```powershell
# Basic security setup
.\scripts\setup-security.ps1

# Restrict network access to specific IPs
.\scripts\firewall-restrict.ps1

# Check current firewall rules
Get-NetFirewallRule | Where-Object {$_.DisplayName -like "*LocalLLM*"}
```

#### 10. No models showing in UI or in ollama
**Problem**: Web-UI and/or Ollama shows no models, when installation is done using custom location script.

**Solution**:
Ollama setup installs ollama as an application. This adds a startup entry in Windows. This starts ollama process without setting up our environment variables, pointing to custom data directory.
You can disable this startup entry to avoid such issues. Our stop scripts do handle and terminate this process. Running stop-all and then start-all scripts will solve this issue.

### Performance Issues

#### Slow Model Loading
- Ensure models are on SSD (DATA_ROOT drive)
- Check GPU memory usage: `nvidia-smi`
- Consider smaller models for initial testing

#### High Memory Usage
- Monitor with Task Manager or `Get-Process ollama`
- Restart services if memory usage exceeds 80%
- Consider CPU-only mode for memory-constrained systems

### Network Issues

#### Intranet Access Not Working
```powershell
# Check firewall rules
Get-NetFirewallRule | Where-Object {$_.DisplayName -like "*Ollama*"}

# Verify binding
netstat -an | findstr "11434"
netstat -an | findstr "8080"

# Test from another PC
curl http://<this-pc-ip>:11434/api/tags
```

#### Port Conflicts
```powershell
# Check what's using the ports
netstat -ano | findstr "11434"
netstat -ano | findstr "8080"

# Kill conflicting processes
Stop-Process -Id <PID> -Force
```

## 📚 Integration

### Development Tools
- **Cursor**: Native Ollama provider or LiteLLM proxy
- **VS Code Continue**: OpenAI-compatible endpoint
- **Tabby**: Direct Ollama integration

### API Usage
```bash
# Chat completion (local access only)
curl -X POST http://127.0.0.1:11434/api/generate \
  -H "Content-Type: application/json" \
  -d '{"model": "qwen2.5:7b-instruct", "prompt": "Hello!"}'

# List models (local access only)
curl http://127.0.0.1:11434/api/tags

# ⚠️ SECURITY: These endpoints are open to your network
# For production use, enable authentication and restrict network access
```

## 🔒 Security

### Current Security Status
- **Open WebUI**: No authentication by default
- **Ollama API**: Completely open to network
- **Network Access**: Bound to `0.0.0.0` (all interfaces)
- **Data Protection**: Minimal - accessible to anyone on network

### Security Recommendations
1. **Enable Open WebUI Authentication**
   - Create admin account on first login
   - Disable self-signup
   - Use strong passwords

2. **Restrict Network Access**
   - Bind to specific LAN IP instead of `0.0.0.0`
   - Use firewall rules to limit access to trusted IPs
   - Consider VPN for remote access

3. **API Security**
   - Use reverse proxy (Nginx/Caddy) with authentication
   - Implement API key authentication for Ollama
   - Monitor access logs

4. **Data Protection**
   - Encrypt sensitive documents before RAG ingestion
   - Regular security audits of chat logs
   - Backup encryption

### Quick Security Setup
```powershell
# Basic security (recommended for home use)
.\scripts\setup-security.ps1

# Advanced security (for production/office use)
.\scripts\firewall-restrict.ps1
.\scripts\setup-reverse-proxy.ps1
```

## 🔄 Maintenance

### Regular Tasks
- **Check free space**: Check disk space on all drives (OS, Data, Working directory)
- **Update models**: Update models with `ollama pull <model>:latest`
- **Clear caches**: `pip cache purge` if space issues
- **Check logs**: Monitor Open WebUI and Ollama output
- **Clear logs**: Review and clean chat logs in `$env:DATA_ROOT\webui\data\chat`
- **Backup data**: Backup entire `$env:DATA_ROOT` directory

### Performance Monitoring
```powershell
# Check GPU memory usage
nvidia-smi

# Monitor Ollama process
Get-Process ollama | Select-Object ProcessName, Id, CPU, WorkingSet

# Check disk space
Get-WmiObject -Class Win32_LogicalDisk | Select-Object DeviceID, Size, FreeSpace
```

### Cache Management
```powershell
# Clear pip cache if C: drive fills up
pip cache purge

# Clear Ollama model cache (frees space)
Remove-Item "$env:DATA_ROOT\models\ollama\.ollama\cache\*" -Recurse -Force

# Clear RAG database if corrupted
Remove-Item "$env:DATA_ROOT\rags\chroma\*" -Recurse -Force
```

### Backup and Recovery
```powershell
# Create backup
$BackupPath = "E:\BACKUP\OLLAMA-$(Get-Date -Format 'yyyy-MM-dd')"
Copy-Item "$env:DATA_ROOT\*" $BackupPath -Recurse

# Restore from backup
Copy-Item "$BackupPath\*" "$env:DATA_ROOT\" -Recurse
```

### Migration to New PC
1. Copy entire `$env:DATA_ROOT` directory
2. Install Ollama and Python 3.11/3.12
3. Run setup scripts
4. Update firewall rules for new network
5. Update environment variables in `config\env.ps1`

## 📖 Documentation

- **PRD**: `documents/PRD-local-llm.md` - Product requirements and goals
- **Runbook**: `documents/runbook-local-llm.md` - Detailed setup and operation guide
- **Decisions**: `documents/decisions-llm-runtime.md` - Technical decisions made
- **Integrations**: `documents/integrations-ollama-tools.md` - Tool integration guides
- **Future Scope**: `documents/future-scope.md` - Roadmap and planned features


## 🤝 Contributing

We welcome contributions from the community! Please see our contributing guidelines:

- **[CONTRIBUTING.md](CONTRIBUTING.md)** - How to contribute to this project
- **[CODE_OF_CONDUCT.md](CODE_OF_CONDUCT.md)** - Community behavior standards

### **Quick Start for Contributors**
1. Fork the repository
2. Create a feature branch
3. Make your changes
4. Test with `.\scripts\test-production.ps1`
5. Submit a pull request

**Areas we'd love help with:**
- 🐛 Bug fixes and improvements
- 🖥️ Linux and macOS support
- 📚 Documentation enhancements
- 🔧 Script optimizations
- 🧪 Testing and validation

## 🆘 Getting Help

1. Check the troubleshooting section above
2. Review existing issues and discussions
3. Check Open WebUI and Ollama logs for error details
4. Verify environment variables are set correctly
5. Ensure sufficient disk space on all drives

## 📝 License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

**Dependencies:**
- **Ollama**: MIT License
- **Open WebUI**: BSD 3-Clause License  
- **Chroma**: Apache 2.0 License

All dependencies are open source and compatible with this project's MIT License.

---

**Remember**: This is a local setup - all data stays on your machine. No external services or accounts required! 