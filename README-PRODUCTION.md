# Local LLM Stack - Production Ready PowerShell Scripts

## 🚀 Overview

This document describes the production-ready PowerShell scripting infrastructure for the Local LLM Stack, featuring Ollama and Open WebUI services. All scripts have been completely rewritten to be robust, maintainable, and production-ready.

## ✨ Key Improvements Made

### 1. **Centralized Configuration Management**
- **Environment Variables**: All hardcoded values (ports, timeouts, paths) moved to `config/env.ps1`
- **Parameterization**: Port numbers, timeouts, and paths are now configurable
- **Validation**: Automatic environment validation and directory creation

### 2. **Common Functions Library**
- **`config/functions.ps1`**: Centralized utility functions for all scripts
- **Path Resolution**: Scripts work from any directory with automatic project root detection
- **Error Handling**: Consistent error handling and logging across all scripts
- **Service Management**: Health checks, process management, and port monitoring

### 3. **Production-Ready Features**
- **Structured Logging**: Comprehensive logging with configurable levels
- **Health Monitoring**: Service health checks and automatic recovery
- **Error Recovery**: Fallback mechanisms and graceful degradation
- **Cross-Script Dependencies**: Proper script calling with error handling

### 4. **Script Standardization**
- **Consistent Structure**: All scripts follow the same pattern and conventions
- **Parameter Support**: Standardized command-line parameters across scripts
- **Exit Codes**: Proper exit codes for automation and monitoring
- **Documentation**: Comprehensive inline documentation and help

## 🏗️ Architecture

```
Ollama-Local-Setup/
├── config/
│   ├── env.ps1              # Environment configuration
│   └── functions.ps1        # Common functions library
├── scripts/
│   ├── status.ps1           # Service status monitoring
│   ├── start-all.ps1        # Start all services
│   ├── stop-all.ps1         # Stop all services
│   ├── start-ollama.ps1     # Start Ollama service
│   ├── start-webui.ps1      # Start Open WebUI service
│   └── test-production.ps1  # Production readiness testing
└── logs/                    # Structured log files
```

## 🔧 Configuration

### Environment Variables (`config/env.ps1`)

```powershell
# Service Configuration
$env:OLLAMA_PORT = "11434"
$env:WEBUI_PORT = "8080"
$env:OLLAMA_BASE_URL = "http://127.0.0.1:11434"
$env:WEBUI_BASE_URL = "http://127.0.0.1:8080"

# Timeout Configuration
$env:OLLAMA_STARTUP_TIMEOUT = "60"
$env:WEBUI_STARTUP_TIMEOUT = "90"
$env:HEALTH_CHECK_TIMEOUT = "10"

# Data and Logging
$env:DATA_ROOT = "E:\OLLAMA"
$env:LOG_DIR = "$env:DATA_ROOT\logs"
$env:LOG_LEVEL = "INFO"
```

### Key Configuration Options

| Variable | Description | Default |
|----------|-------------|---------|
| `OLLAMA_PORT` | Ollama service port | 11434 |
| `WEBUI_PORT` | Open WebUI port | 8080 |
| `OLLAMA_STARTUP_TIMEOUT` | Ollama startup timeout (seconds) | 60 |
| `WEBUI_STARTUP_TIMEOUT` | WebUI startup timeout (seconds) | 90 |
| `HEALTH_CHECK_TIMEOUT` | Health check timeout (seconds) | 10 |
| `LOG_LEVEL` | Logging level (DEBUG/INFO/WARN/ERROR) | INFO |

## 📜 Script Reference

### Core Management Scripts

#### `status.ps1` - Service Status Monitoring
```powershell
.\scripts\status.ps1 [-Verbose] [-NoColor]
```

**Features:**
- Comprehensive service health monitoring
- Process and port status checking
- Disk space monitoring
- Model inventory and size reporting
- Service API health checks

#### `start-all.ps1` - Start All Services
```powershell
.\scripts\start-all.ps1 [-Verbose] [-Force] [-SkipHealthCheck]
```

**Features:**
- Sequential service startup (Ollama → WebUI)
- Health check verification
- Automatic retry mechanisms
- LAN IP detection for intranet access

#### `stop-all.ps1` - Stop All Services
```powershell
.\scripts\stop-all.ps1 [-Verbose] [-Force] [-NoLogging]
```

**Features:**
- Graceful service shutdown
- Fallback process termination
- Port verification
- Comprehensive logging

#### `start-ollama.ps1` - Start Ollama Service
```powershell
.\scripts\start-ollama.ps1 [-Verbose] [-NoLogging]
```

**Features:**
- Automatic Ollama executable detection
- Process health validation
- Environment validation
- Configurable host binding

#### `start-webui.ps1` - Start Open WebUI Service
```powershell
.\scripts\start-webui.ps1 [-Verbose] [-NoLogging]
```

**Features:**
- Python environment validation
- Executable vs. module fallback
- Service health monitoring
- Automatic directory creation

### Testing and Validation

#### `test-production.ps1` - Production Readiness Testing
```powershell
.\scripts\test-production.ps1 [-Verbose] [-SkipStartup] [-SkipShutdown]
```

**Features:**
- Environment configuration validation
- Functions library testing
- Script availability verification
- Service lifecycle testing (optional)

## 🚀 Getting Started

### 1. **Initial Setup**
```powershell
# Navigate to project directory
cd Ollama-Local-Setup

# Test production readiness
.\scripts\test-production.ps1
```

### 2. **Start Services**
```powershell
# Start all services
.\scripts\start-all.ps1

# Check status
.\scripts\status.ps1
```

### 3. **Stop Services**
```powershell
# Stop all services
.\scripts\stop-all.ps1
```

### 4. **Monitor Services**
```powershell
# Check service status
.\scripts\status.ps1

# Check with verbose logging
.\scripts\status.ps1 -Verbose
```

## 🔍 Troubleshooting

### Common Issues

#### Script Path Problems
**Problem**: Scripts fail with "file not found" errors
**Solution**: Scripts now use automatic path resolution - they work from any directory

#### Port Conflicts
**Problem**: Services fail to start due to port conflicts
**Solution**: Check `config/env.ps1` for port configuration and ensure ports are free

#### Environment Variables
**Problem**: Scripts fail due to missing environment variables
**Solution**: Run `.\scripts\test-production.ps1` to validate environment

### Debug Mode
```powershell
# Enable verbose logging
.\scripts\status.ps1 -Verbose
.\scripts\start-all.ps1 -Verbose
```

### Log Files
All scripts create detailed log files in `E:\OLLAMA\logs\` with timestamps and log levels.

## 📊 Monitoring and Automation

### Health Checks
Scripts include built-in health monitoring:
- Process status verification
- Port availability checking
- API endpoint health testing
- Automatic recovery mechanisms

### Exit Codes
All scripts return proper exit codes for automation:
- `0`: Success
- `1`: Error or partial failure

### Logging Levels
- **DEBUG**: Detailed debugging information
- **INFO**: General operational information
- **WARN**: Warning conditions
- **ERROR**: Error conditions

## 🔒 Security Features

### Firewall Integration
Scripts work with existing firewall rules:
- Port 11434 (Ollama API)
- Port 8080 (Open WebUI)
- Automatic LAN IP detection

### Process Isolation
- Services run in separate processes
- Automatic cleanup on shutdown
- Process verification and monitoring

## 🚀 Production Deployment

### Prerequisites
1. **PowerShell 5.1+** or **PowerShell Core 6+**
2. **Ollama** installed and accessible
3. **Python 3.8+** with virtual environment
4. **Open WebUI** installed in virtual environment
5. **E: drive** available for data storage

### Deployment Steps
1. **Clone/Download** the project
2. **Configure** `config/env.ps1` for your environment
3. **Test** with `.\scripts\test-production.ps1`
4. **Deploy** services with `.\scripts\start-all.ps1`
5. **Monitor** with `.\scripts\status.ps1`

### Automation
Scripts can be integrated into:
- Windows Task Scheduler
- Systemd services (Linux)
- CI/CD pipelines
- Monitoring systems

## 📈 Performance Optimizations

### Startup Time
- **Parallel Health Checks**: Services are checked simultaneously
- **Configurable Timeouts**: Adjustable startup timeouts
- **Skip Health Check Option**: Fast startup for development

### Resource Usage
- **Efficient Process Detection**: Optimized process and port checking
- **Minimal Logging**: Configurable log levels
- **Memory Management**: Proper process cleanup

## 🔄 Maintenance

### Regular Tasks
1. **Monitor Logs**: Check `E:\OLLAMA\logs\` for issues
2. **Update Scripts**: Pull latest versions from repository
3. **Validate Environment**: Run `test-production.ps1` periodically
4. **Clean Logs**: Log retention is configurable

### Updates
- Scripts are backward compatible
- Environment changes require restart
- Test thoroughly after configuration changes

## 📚 Additional Resources

### Script Help
```powershell
# Get help for any script
Get-Help .\scripts\status.ps1 -Full
```

### Function Documentation
All functions in `config/functions.ps1` include comprehensive help:
```powershell
# Get help for functions
Get-Help Get-ScriptRoot -Full
Get-Help Test-ServiceHealth -Full
```

### Log Analysis
Log files include structured information for analysis:
- Timestamped entries
- Log levels
- Process IDs
- Error details

## 🎯 Future Enhancements

### Planned Features
- **Metrics Collection**: Performance and usage metrics
- **Configuration UI**: Web-based configuration interface
- **Backup/Restore**: Service state backup and recovery
- **Cluster Support**: Multi-node deployment support

### Contributing
- Follow existing script patterns
- Include comprehensive error handling
- Add logging for all operations
- Test thoroughly before submitting

---

## 🏆 Production Ready Status

✅ **Environment Management**: Centralized and validated  
✅ **Path Resolution**: Works from any directory  
✅ **Error Handling**: Comprehensive and consistent  
✅ **Logging**: Structured and configurable  
✅ **Health Monitoring**: Built-in service health checks  
✅ **Documentation**: Complete inline and external docs  
✅ **Testing**: Automated production readiness testing  
✅ **Security**: Firewall integration and process isolation  

**All scripts are now production-ready and suitable for enterprise deployment!** 🚀
