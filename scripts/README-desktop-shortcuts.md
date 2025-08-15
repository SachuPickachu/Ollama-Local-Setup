# Desktop Shortcuts for Local LLM Stack

This directory contains scripts to create Windows desktop shortcuts for easily starting and stopping your Local LLM services.

## What These Shortcuts Do

- **Start Local LLM**: Double-click to start both Ollama and Open WebUI services
- **Stop Local LLM**: Double-click to stop both Ollama and Open WebUI services

## How to Create the Shortcuts

### Option 1: PowerShell Script (Recommended)
```powershell
# Navigate to your project directory
cd "F:\Workplaces\Ollama-Local-Setup"

# Run the PowerShell script
.\scripts\create-desktop-shortcuts.ps1

# Or with verbose output
.\scripts\create-desktop-shortcuts.ps1 -Verbose

# To overwrite existing shortcuts
.\scripts\create-desktop-shortcuts.ps1 -Force
```

### Option 2: Batch File
```cmd
# Navigate to your project directory
cd "F:\Workplaces\Ollama-Local-Setup"

# Double-click the batch file
scripts\create-desktop-shortcuts.bat
```

## What Gets Created

The scripts will create two shortcuts on your Windows desktop:

1. **Start Local LLM.lnk** - Points to `scripts\start-all.ps1`
2. **Stop Local LLM.lnk** - Points to `scripts\stop-all.ps1`

## How the Shortcuts Work

Each shortcut:
- Runs PowerShell with the appropriate script
- Sets the working directory to your project root
- Includes a descriptive tooltip
- Can be double-clicked to execute

## Troubleshooting

### Permission Issues
If you encounter permission errors:
1. Right-click the shortcut
2. Select "Run as Administrator"

### Execution Policy Issues
If PowerShell execution policy blocks the scripts:
1. Open PowerShell as Administrator
2. Run: `Set-ExecutionPolicy -ExecutionPolicy RemoteSigned -Scope CurrentUser`

### Shortcut Not Working
- Verify the project path in the shortcut properties
- Check that the PowerShell scripts exist in the `scripts\` folder
- Ensure the working directory is set correctly

## Customization

You can modify the shortcuts by:
1. Right-clicking the shortcut
2. Selecting "Properties"
3. Modifying the target, arguments, or working directory

## Manual Shortcut Creation

If you prefer to create shortcuts manually:

1. Right-click on your desktop
2. Select "New" → "Shortcut"
3. For the target, use: `powershell.exe -ExecutionPolicy Bypass -File "F:\Workplaces\Ollama-Local-Setup\scripts\start-all.ps1"`
4. Set the working directory to: `F:\Workplaces\Ollama-Local-Setup`
5. Name it "Start Local LLM"

Repeat for the stop script with `stop-all.ps1`.

## Security Notes

- The shortcuts run PowerShell scripts with `-ExecutionPolicy Bypass`
- This is necessary for the scripts to function properly
- Only run these shortcuts if you trust the source of the scripts
- Consider running as Administrator if you encounter permission issues
