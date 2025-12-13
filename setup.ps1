#Requires -Version 5.1
<#
.SYNOPSIS
    Setup script for the ReAct Agent Tutorial project.

.DESCRIPTION
    Automates the installation of:
    - ABxM.Agentic.MCP plugin to Grasshopper Libraries folder
    - uv package manager (if not installed)
    - Python dependencies via uv sync

.NOTES
    Manual steps still required:
    - Sign up for Groq API key at https://console.groq.com
    - Paste your API key into the notebook
    - Open Rhino/Grasshopper and load examples/task_template.gh
#>

param(
    [switch]$SkipPluginCopy,
    [switch]$SkipUvInstall,
    [switch]$SkipDependencies
)

$ErrorActionPreference = "Stop"

# Colors for output
function Write-Step { param($msg) Write-Host "`n>> $msg" -ForegroundColor Cyan }
function Write-Success { param($msg) Write-Host "   [OK] $msg" -ForegroundColor Green }
function Write-Warning { param($msg) Write-Host "   [!] $msg" -ForegroundColor Yellow }
function Write-Err { param($msg) Write-Host "   [X] $msg" -ForegroundColor Red }

Write-Host ""
Write-Host "========================================" -ForegroundColor Magenta
Write-Host "  ReAct Agent Tutorial - Setup Script  " -ForegroundColor Magenta
Write-Host "========================================" -ForegroundColor Magenta

# Get script directory (where this script is located)
$ScriptDir = Split-Path -Parent $MyInvocation.MyCommand.Definition
if (-not $ScriptDir) { $ScriptDir = Get-Location }

# ============================================================================
# Step 1: Copy MCP Plugin to Grasshopper Libraries
# ============================================================================
if (-not $SkipPluginCopy) {
    Write-Step "Copying ABxM.Agentic.MCP plugin to Grasshopper Libraries..."

    # Check if Rhino is running (locks the DLL files)
    $rhinoProcess = Get-Process -Name "Rhino" -ErrorAction SilentlyContinue
    if ($rhinoProcess) {
        Write-Err "Rhino is currently running!"
        Write-Host "   Please close Rhino/Grasshopper before running this script." -ForegroundColor Gray
        Write-Host "   The plugin files are locked while Rhino is open." -ForegroundColor Gray
        exit 1
    }

    $SourcePath = Join-Path $ScriptDir "Libraries\ABxM.Agentic.MCP"
    $GrasshopperLibraries = Join-Path $env:APPDATA "Grasshopper\Libraries"
    $DestPath = Join-Path $GrasshopperLibraries "ABxM.Agentic.MCP"

    # Check source exists
    if (-not (Test-Path $SourcePath)) {
        Write-Err "Source folder not found: $SourcePath"
        Write-Host "   Make sure you're running this script from the project root." -ForegroundColor Gray
        exit 1
    }

    # Create Grasshopper Libraries folder if it doesn't exist
    if (-not (Test-Path $GrasshopperLibraries)) {
        Write-Warning "Grasshopper Libraries folder not found. Creating it..."
        New-Item -ItemType Directory -Path $GrasshopperLibraries -Force | Out-Null
    }

    # Remove existing installation if present
    if (Test-Path $DestPath) {
        Write-Warning "Existing installation found. Removing..."
        try {
            Remove-Item -Path $DestPath -Recurse -Force -ErrorAction Stop
        } catch {
            Write-Err "Failed to remove existing installation."
            Write-Host "   This usually means Rhino is running. Please close it and try again." -ForegroundColor Gray
            exit 1
        }
    }

    # Copy the plugin
    Copy-Item -Path $SourcePath -Destination $DestPath -Recurse -Force
    Write-Success "Plugin copied to: $DestPath"

    # Verify copy
    $GhaFile = Join-Path $DestPath "ABxM.Agentic.MCP.gha"
    if (Test-Path $GhaFile) {
        Write-Success "Verified: ABxM.Agentic.MCP.gha exists"
    } else {
        Write-Err "Verification failed: .gha file not found"
        exit 1
    }
} else {
    Write-Step "Skipping plugin copy (--SkipPluginCopy)"
}

# ============================================================================
# Step 2: Install uv (if not present)
# ============================================================================
if (-not $SkipUvInstall) {
    Write-Step "Checking for uv package manager..."

    $uvPath = Get-Command uv -ErrorAction SilentlyContinue

    if ($uvPath) {
        $uvVersion = & uv --version 2>&1
        Write-Success "uv is already installed: $uvVersion"
    } else {
        Write-Warning "uv not found. Installing..."

        try {
            # Install uv using the official installer
            Invoke-Expression (Invoke-RestMethod https://astral.sh/uv/install.ps1)

            # Refresh PATH for current session
            $env:Path = [System.Environment]::GetEnvironmentVariable("Path", "Machine") + ";" + [System.Environment]::GetEnvironmentVariable("Path", "User")

            # Verify installation
            $uvPath = Get-Command uv -ErrorAction SilentlyContinue
            if ($uvPath) {
                $uvVersion = & uv --version 2>&1
                Write-Success "uv installed successfully: $uvVersion"
            } else {
                Write-Warning "uv installed but not in PATH yet."
                Write-Host "   You may need to restart your terminal." -ForegroundColor Gray
            }
        } catch {
            Write-Err "Failed to install uv: $_"
            Write-Host "   Try installing manually:" -ForegroundColor Gray
            Write-Host "   powershell -ExecutionPolicy ByPass -c `"irm https://astral.sh/uv/install.ps1 | iex`"" -ForegroundColor Gray
            exit 1
        }
    }
} else {
    Write-Step "Skipping uv installation (--SkipUvInstall)"
}

# ============================================================================
# Step 3: Install Python dependencies
# ============================================================================
if (-not $SkipDependencies) {
    Write-Step "Installing Python dependencies with uv sync..."

    # Change to project directory
    Push-Location $ScriptDir

    try {
        # Check if pyproject.toml exists
        if (-not (Test-Path "pyproject.toml")) {
            Write-Err "pyproject.toml not found in $ScriptDir"
            exit 1
        }

        # Run uv sync
        & uv sync

        if ($LASTEXITCODE -eq 0) {
            Write-Success "Dependencies installed successfully"
        } else {
            Write-Err "uv sync failed with exit code $LASTEXITCODE"
            exit 1
        }
    } catch {
        Write-Err "Failed to install dependencies: $_"
        exit 1
    } finally {
        Pop-Location
    }
} else {
    Write-Step "Skipping dependency installation (--SkipDependencies)"
}

# ============================================================================
# Summary and Next Steps
# ============================================================================
Write-Host ""
Write-Host "========================================" -ForegroundColor Green
Write-Host "  Setup Complete!                      " -ForegroundColor Green
Write-Host "========================================" -ForegroundColor Green
Write-Host ""
Write-Host "Next steps (manual):" -ForegroundColor Yellow
Write-Host ""
Write-Host "  1. Get your FREE Groq API key:" -ForegroundColor White
Write-Host "     - Go to: https://console.groq.com" -ForegroundColor Gray
Write-Host "     - Sign up (free, no credit card)" -ForegroundColor Gray
Write-Host "     - Create an API key" -ForegroundColor Gray
Write-Host ""
Write-Host "  2. Open Rhino 8 and Grasshopper:" -ForegroundColor White
Write-Host "     - Open: examples/task_template.gh" -ForegroundColor Gray
Write-Host "     - Verify MCP server is running (port 8089)" -ForegroundColor Gray
Write-Host ""
Write-Host "  3. Launch the tutorial:" -ForegroundColor White
Write-Host "     - VS Code/Cursor: Open notebooks/react_agent_student.ipynb" -ForegroundColor Gray
Write-Host "     - Or run: uv run jupyter notebook notebooks/react_agent_student.ipynb" -ForegroundColor Gray
Write-Host ""
Write-Host "  4. In the notebook, replace 'your-api-key-here' with your Groq key" -ForegroundColor White
Write-Host ""
Write-Host "  5. Test your setup (optional):" -ForegroundColor White
Write-Host "     uv run python test_mcp_connection.py" -ForegroundColor Gray
Write-Host ""
Write-Host "Troubleshooting:" -ForegroundColor Yellow
Write-Host "  - If Grasshopper doesn't see the plugin, restart Rhino" -ForegroundColor Gray
Write-Host "  - Run: uv run python test_mcp_connection.py" -ForegroundColor Gray
Write-Host ""
