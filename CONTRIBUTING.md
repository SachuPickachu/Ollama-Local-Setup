# Contributing to Ollama Local Setup

Thank you for your interest in contributing to Ollama Local Setup! This project aims to provide a robust, portable local LLM stack for Windows users. We welcome contributions from the community.

## 🚀 **Quick Start for Contributors**

1. **Create an Issue** describing what you want to work on
2. **Wait for assignment** from maintainers
3. **Choose your workflow** (see options below)
4. **Create branch**: `git checkout -b feature/42-your-feature-name`
5. **Make changes** and test with `.\scripts\test-production.ps1`
6. **Submit PR** with title: "Fix #42: Your Feature Description"

> **💡 Pro Tip**: Always start with an issue first! This ensures coordination and prevents duplicate work.

## 🎯 **How Can I Contribute?**

### **Types of Contributions We Welcome:**

#### **🐛 Bug Reports & Issues**
- Report bugs you encounter
- Suggest improvements
- Request new features
- Report security vulnerabilities

#### **💻 Code Contributions**
- Fix bugs
- Add new features
- Improve documentation
- Enhance scripts and automation
- Add tests

#### **📚 Documentation**
- Improve README files
- Add examples and tutorials
- Fix typos and clarify instructions
- Translate to other languages

#### **🔧 Scripts & Automation**
- Enhance PowerShell scripts
- Add new utility scripts
- Improve error handling
- Add logging and monitoring

#### **🖥️ Platform Support**
- **Linux support** (high priority)
- **macOS support** (medium priority)
- Cross-platform compatibility improvements

## 🚀 **Getting Started**

### **Issue-First Workflow (Recommended)**

We follow an **issue-first workflow** to ensure clear communication and tracking:

1. **Create an Issue First**
   - 🐛 **Bug Report**: Describe the problem clearly
   - 💡 **Feature Request**: Explain what you want to add
   - 📚 **Documentation**: Point out what needs improvement
   - 🔧 **Enhancement**: Suggest script or automation improvements

2. **Wait for Issue Assignment**
   - Maintainers will review and assign the issue to you
   - This ensures no duplicate work and proper coordination

3. **Use Issue Number in Branch Names**
   ```powershell
   # Branch naming convention:
   # type/issue-number-brief-description
   
   feature/42-add-linux-support
   bugfix/15-fix-path-detection  
   docs/23-update-installation-guide
   security/8-fix-authentication-bug
   ```

4. **Link Everything Together**
   - Branch name includes issue number
   - PR title references issue: "Fix #42: Add Linux Support"
   - GitHub automatically links everything

### **Which Workflow Should I Use?**

#### **🟢 Use Direct Branch (Option 1) if:**
- You have **write access** to the repository
- You're a **trusted contributor** or maintainer
- You want **faster iteration** and collaboration
- You're working on **complex features** with others

#### **🟡 Use Fork + PR (Option 2) if:**
- You're a **new contributor**
- You don't have **write access** yet
- You want to **learn the project** first
- You're making **small changes** or documentation updates

#### **🔄 Workflow Progression:**
```
New Contributor → Fork + PR → Build Trust → Get Write Access → Direct Branch
```

> **💡 Note**: Both workflows result in the same end result - a pull request that gets reviewed and merged. The choice is about your access level and comfort with the project.

### **Prerequisites**
- **Windows 10/11** (for current development)
- **PowerShell 5.1+** or **PowerShell Core 6+**
- **Git** for version control
- **Ollama** installed and working
- **Python 3.11-3.12** for Open WebUI

### **Development Setup**

#### **Option 1: Direct Branch (Trusted Contributors)**
If you have **write access** to the repository:

1. **Clone the repository** directly:
   ```powershell
   git clone https://github.com/SachuPickachu/Ollama-Local-Setup.git
   cd Ollama-Local-Setup
   ```

#### **Option 2: Fork + PR (New Contributors)**
If you're a **new contributor** or don't have write access:

1. **Fork the repository** on GitHub
2. **Clone your fork** locally:
   ```powershell
   git clone https://github.com/YOUR_USERNAME/Ollama-Local-Setup.git
   cd Ollama-Local-Setup
   ```

#### **Common Setup Steps (Both Options)**
3. **Set up the development environment**:
   ```powershell
   . .\config\env.ps1
   .\scripts\test-production.ps1
   ```
4. **Create a feature branch** using issue number and description:
   ```powershell
   # Format: type/issue-number-brief-description
   git checkout -b feature/42-add-linux-support
   git checkout -b bugfix/15-fix-path-detection
   git checkout -b docs/23-update-installation-guide
   ```

## 📝 **Development Guidelines**

### **Branch Naming Conventions**

We use a consistent branch naming scheme for better organization:

```powershell
# Format: type/issue-number-brief-description

# Feature branches
feature/42-add-linux-support
feature/15-implement-cache-management

# Bug fixes
bugfix/23-fix-path-detection
bugfix/8-resolve-authentication-issue

# Documentation
docs/12-update-installation-guide
docs/31-add-troubleshooting-section

# Security fixes
security/5-fix-firewall-rule
security/19-patch-authentication-bug

# Platform support
platform/7-add-macos-support
platform/25-linux-script-conversion

# Script improvements
script/18-enhance-logging
script/33-add-error-handling
```

**Branch Type Prefixes:**
- `feature/` - New functionality
- `bugfix/` - Bug fixes
- `docs/` - Documentation updates
- `security/` - Security-related changes
- `platform/` - Cross-platform support
- `script/` - Script and automation improvements

### **PowerShell Script Standards**

#### **Script Structure**
```powershell
# =============================================================================
# Script Name - Brief Description
# =============================================================================
# This script does X, Y, and Z

param(
    [string]$Parameter1 = "default",
    [switch]$Verbose
)

# Load common functions and environment
$scriptPath = Split-Path $MyInvocation.MyCommand.Path -Parent
$projectRoot = Split-Path $scriptPath -Parent
$functionsPath = Join-Path $projectRoot "config\functions.ps1"

if (Test-Path $functionsPath) {
    . $functionsPath
} else {
    Write-Error "Functions library not found at: $functionsPath"
    exit 1
}

# Initialize logging
if (-not (Initialize-Logging -ScriptName "script-name" -LogLevel $(if ($Verbose) { "DEBUG" } else { "INFO" }))) {
    Write-Error "Failed to initialize logging"
    exit 1
}

# Load and validate environment
if (-not (Load-Environment)) {
    Write-Log "Failed to load environment configuration" "ERROR"
    exit 1
}

# Main script logic here
try {
    Write-Log "Starting script execution" "INFO"
    # Your code here
} catch {
    Write-Log "Error: $($_.Exception.Message)" "ERROR"
    exit 1
}
```

#### **Required Elements**
- ✅ **Parameter validation** with `param()` block
- ✅ **Error handling** with try-catch blocks
- ✅ **Logging** using `Write-Log` function
- ✅ **Environment loading** using `Load-Environment`
- ✅ **Help documentation** with comment-based help
- ✅ **Exit codes** for automation compatibility

### **Documentation Standards**

#### **README Updates**
- Update relevant sections when adding features
- Include examples for new functionality
- Update troubleshooting section for new issues
- Keep OS support information current

#### **Inline Documentation**
- Comment complex logic
- Document function parameters and return values
- Explain why certain approaches were chosen
- Include usage examples

### **Testing Requirements**

#### **Before Submitting**
1. **Run production tests**:
   ```powershell
   .\scripts\test-production.ps1
   ```
2. **Test your changes** on a clean environment
3. **Verify scripts work** from different directories
4. **Check for PowerShell best practices** violations

#### **Test Scenarios**
- ✅ Scripts work from project root
- ✅ Scripts work from subdirectories
- ✅ Scripts work with different PowerShell versions
- ✅ Error conditions are handled gracefully
- ✅ Logging works correctly

## 🔒 **Security Guidelines**

### **Security Considerations**
- **Never hardcode credentials** or sensitive information
- **Validate all user inputs** to prevent injection attacks
- **Use secure defaults** (localhost binding, authentication enabled)
- **Follow principle of least privilege** for network access
- **Document security implications** of new features

### **Security Review Process**
- All security-related changes require review
- Test security scripts in isolated environment
- Verify firewall rules are correctly applied
- Ensure authentication is properly implemented

## 🌐 **Platform Support Guidelines**

### **Current Focus: Windows**
- **PowerShell scripts** are Windows-first
- **Windows Firewall** integration
- **Windows-specific paths** and conventions
- **Native performance** over Docker/WSL2

### **Future Platforms: Linux & macOS**
- **Shell script alternatives** for Linux/macOS
- **Cross-platform compatibility** where possible
- **Platform-specific optimizations** when needed
- **Consistent user experience** across platforms

### **Platform-Specific Contributions**
- **Linux**: Bash scripts, systemd services, firewall rules
- **macOS**: Zsh scripts, launchd services, pf firewall
- **Cross-platform**: Python scripts, Docker containers

## 📋 **Pull Request Process**

### **Before Submitting a PR**
1. **Ensure tests pass** locally
2. **Update documentation** if needed
3. **Follow coding standards** outlined above
4. **Test on clean environment** if possible
5. **Squash commits** for clean history

### **PR Description Template**
```markdown
## Description
Brief description of what this PR accomplishes

## Related Issue
Closes #42 (or Fixes #42, Resolves #42)

## Type of Change
- [ ] Bug fix
- [ ] New feature
- [ ] Documentation update
- [ ] Script enhancement
- [ ] Platform support

## Testing
- [ ] Ran production tests
- [ ] Tested on clean environment
- [ ] Verified error handling
- [ ] Checked logging output

## Breaking Changes
- [ ] No breaking changes
- [ ] Breaking changes documented

## Additional Notes
Any additional information or context
```

### **Review Process**
1. **Automated checks** (if implemented)
2. **Code review** by maintainers
3. **Testing** on different environments
4. **Documentation review**
5. **Final approval** and merge

## 🐛 **Issue Reporting**

### **Bug Report Template**
```markdown
## Bug Description
Clear description of the bug

## Steps to Reproduce
1. Step 1
2. Step 2
3. Step 3

## Expected Behavior
What should happen

## Actual Behavior
What actually happens

## Environment
- Windows Version: [e.g., Windows 10 19045]
- PowerShell Version: [e.g., 5.1.19041.1]
- Ollama Version: [e.g., 0.1.29]
- Python Version: [e.g., 3.12.0]

## Additional Information
Logs, screenshots, error messages
```

### **Feature Request Template**
```markdown
## Feature Description
Clear description of the requested feature

## Use Case
Why this feature is needed

## Proposed Solution
How you think it should work

## Alternatives Considered
Other approaches you've considered

## Additional Context
Any other relevant information
```

## 🏷️ **Labels and Milestones**

### **Issue Labels**
- `bug` - Something isn't working
- `enhancement` - New feature or request
- `documentation` - Improvements or additions to docs
- `good first issue` - Good for newcomers
- `help wanted` - Extra attention is needed
- `platform:windows` - Windows-specific
- `platform:linux` - Linux-specific
- `platform:macos` - macOS-specific
- `security` - Security-related changes
- `scripting` - PowerShell/script improvements

### **Milestones**
- `v1.0` - Initial stable release
- `v1.1` - Bug fixes and minor improvements
- `v1.2` - New features and enhancements
- `v2.0` - Major version with platform expansion

## 📞 **Getting Help**

### **Community Resources**
- **GitHub Issues**: For bugs and feature requests
- **GitHub Discussions**: For questions and general discussion
- **Documentation**: Check existing docs first


### **Before Asking for Help**
1. **Search existing issues** for similar problems
2. **Check documentation** and troubleshooting guides
3. **Run production tests** to verify environment
4. **Provide detailed information** about your issue

## 🔐 **Repository Access & Permissions**

### **Access Levels**

We use a **hybrid permission system** to balance security with collaboration:

#### **🟢 Write Access (Direct Branch)**
- **Who**: Trusted contributors and maintainers
- **What**: Can push directly to feature branches
- **How**: Granted after demonstrating reliability and quality
- **Benefits**: Faster development, better collaboration

#### **🟡 Read Access (Fork + PR)**
- **Who**: New contributors and community members
- **What**: Can view, fork, and submit PRs
- **How**: Default access for all contributors
- **Benefits**: Safe learning environment, controlled contributions

#### **🔒 Branch Protection**
- **Main branch**: Protected from direct pushes
- **Feature branches**: Can be pushed to by write-access users
- **PR reviews**: Required for all changes to main
- **Status checks**: Must pass before merging

### **Getting Write Access**

To progress from fork + PR to direct branch access:

1. **Submit quality PRs** that follow our standards
2. **Participate actively** in the community
3. **Demonstrate reliability** in your contributions
4. **Request access** through issues or discussions
5. **Maintainers review** your contributions and decide

> **💡 Pro Tip**: Quality and consistency matter more than quantity. A few well-done contributions are better than many rushed ones.

## 🎉 **Recognition**

### **Contributor Recognition**
- **Contributors** will be listed in README
- **Significant contributions** will be highlighted
- **Platform-specific contributors** will be acknowledged
- **Security contributions** will be specially recognized

### **Contributor Levels**
- **First-time contributors**: Welcome and guided
- **Regular contributors**: Trusted with more complex changes
- **Maintainers**: Can review and merge PRs
- **Core team**: Project direction and major decisions

## 📜 **Code of Conduct**

This project follows the [Contributor Covenant Code of Conduct](CODE_OF_CONDUCT.md). By participating, you are expected to uphold this code.

## 📄 **License**

By contributing, you agree that your contributions will be licensed under the same [MIT License](LICENSE) that covers the project.

---

**Thank you for contributing to Ollama Local Setup!** 🚀

Your contributions help make local LLM deployment easier and more accessible for everyone.
