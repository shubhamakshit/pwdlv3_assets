# Requires PowerShell 5.1 or later.
# Run this script as Administrator for system-wide installations and PATH modifications.

function Show-Header {
    param (
        [string]$Title = "Script Automation"
    )
    Write-Host ""
    Write-Host "====================================================================" -ForegroundColor Cyan
    Write-Host "  $Title" -ForegroundColor Green
    Write-Host "====================================================================" -ForegroundColor Cyan
    Write-Host ""
}

function Show-SectionHeader {
    param (
        [string]$Title
    )
    Write-Host ""
    Write-Host "--- $Title ---" -ForegroundColor Yellow
    Write-Host ""
}

function Show-Success {
    param (
        [string]$Message
    )
    Write-Host "✅ SUCCESS: $Message" -ForegroundColor Green
}

function Show-Error {
    param (
        [string]$Message
    )
    Write-Host "❌ ERROR: $Message" -ForegroundColor Red
}

function Show-Warning {
    param (
        [string]$Message
    )
    Write-Host "⚠️ WARNING: $Message" -ForegroundColor Yellow
}

function Test-Administrator {
    if (-not ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) {
        Show-Error "This script requires Administrator privileges. Please run PowerShell as Administrator."
        Read-Host "Press Enter to exit..."
        exit 1
    }
}

function Generate-RandomTechyUsername {
    $adjectives = "Cyber", "Tech", "Quantum", "Digital", "Synaptic", "Binary", "Pixel", "Virtual", "Axiom", "Logic", "Nano", "Mega", "Alpha", "Omega"
    $nouns = "Geek", "Byte", "Coder", "Droid", "Bot", "Hacker", "User", "Nexus", "Matrix", "Engine", "Core", "Node", "Fusion", "Wizard"
    $numbers = (Get-Random -Minimum 100 -Maximum 999).ToString()

    $randomAdjective = Get-Random -InputObject $adjectives
    $randomNoun = Get-Random -InputObject $nouns

    $username = "$randomAdjective$randomNoun$numbers"
    return $username
}

# --- Main Script ---
Test-Administrator
Show-Header "Automated Setup Script (Using Chocolatey)"

# 0. Install Chocolatey (if not already installed)
Show-SectionHeader "Installing Chocolatey"
$chocoInstalled = $false
if (Get-Command choco.exe -ErrorAction SilentlyContinue) {
    Show-Success "Chocolatey is already installed."
    $chocoInstalled = $true
} else {
    Show-Warning "Chocolatey not detected. Attempting to install Chocolatey."
    Write-Host "This step will temporarily bypass the execution policy for the current process to install Chocolatey." -ForegroundColor Yellow
    Write-Host "It will use an official Chocolatey installation script." -ForegroundColor Yellow
    Start-Sleep -Seconds 2 # Give user a moment to read warning

    try {
        Set-ExecutionPolicy Bypass -Scope Process -Force
        [System.Net.ServicePointManager]::SecurityProtocol = [System.Net.ServicePointManager]::SecurityProtocol -bor 3072
        iex ((New-Object System.Net.WebClient).DownloadString('https://community.chocolatey.org/install.ps1'))
        
        # Verify Chocolatey installation by checking for choco.exe command
        $i = 0
        while (-not (Get-Command choco.exe -ErrorAction SilentlyContinue) -and ($i -lt 30)) {
            Write-Host "Waiting for Chocolatey to be available... ($($i)s)"
            Start-Sleep -Seconds 1
            $i++
        }

        if (Get-Command choco.exe -ErrorAction SilentlyContinue) {
            Show-Success "Chocolatey installed successfully."
            $chocoInstalled = $true
        } else {
            Show-Error "Failed to install Chocolatey. 'choco.exe' command not found after installation attempt."
        }
    }
    catch {
        Show-Error "An error occurred during Chocolatey installation: $($_.Exception.Message)"
    }
}

if (-not $chocoInstalled) {
    Show-Error "Chocolatey is required for subsequent installations. Aborting script."
    Read-Host "Press Enter to exit..."
    exit 1
}

# 1. Install latest Python
Show-SectionHeader "Installing Python"
# Use 'python3' package for Python 3, 'python' for Python 2.x
# Ensure python3 is available in Choco repository, otherwise use 'python'.
# --confirm or -y confirms all prompts.
try {
    Show-Warning "Installing Python via Chocolatey. This might take a few moments..."
    choco install python3 --confirm -Force -ErrorAction Stop # Use -Force to reinstall if partial install.
    Show-Success "Python installed successfully via Chocolatey."
}
catch {
    Show-Error "Failed to install Python via Chocolatey: $($_.Exception.Message)"
    Show-Warning "Please check Chocolatey logs for more details (choco log)."
}

# 2. Install Git
Show-SectionHeader "Installing Git"
try {
    Show-Warning "Installing Git via Chocolatey. This might take a few moments..."
    choco install git --confirm -Force -ErrorAction Stop
    Show-Success "Git installed successfully via Chocolatey."
}
catch {
    Show-Error "Failed to install Git via Chocolatey: $($_.Exception.Message)"
    Show-Warning "Please check Chocolatey logs for more details (choco log)."
}

# 3. Install FFmpeg
Show-SectionHeader "Installing FFmpeg"
try {
    Show-Warning "Installing FFmpeg via Chocolatey. This might take a few moments..."
    choco install ffmpeg --confirm -Force -ErrorAction Stop
    Show-Success "FFmpeg installed successfully via Chocolatey."
}
catch {
    Show-Error "Failed to install FFmpeg via Chocolatey: $($_.Exception.Message)"
    Show-Warning "Please check Chocolatey logs for more details (choco log)."
}

# 4. Clone https://github.com/shubhamakshit/pwdlv3 to %USERPROFILE%\Documents
Show-SectionHeader "Cloning pwdlv3 Repository"
$repoUrl = "https://github.com/shubhamakshit/pwdlv3"
$destinationPath = Join-Path $env:USERPROFILE "Documents"
$repoFolder = Join-Path $destinationPath "pwdlv3"

# Re-check for Git command after Chocolatey installation
if (-not (Get-Command git -ErrorAction SilentlyContinue)) {
    Show-Error "Git command not found after Chocolatey installation. Cannot clone the repository."
} elseif (Test-Path $repoFolder) {
    Show-Warning "Directory '$repoFolder' already exists. Skipping cloning. Please delete it manually if you want a fresh clone."
} else {
    try {
        New-Item -ItemType Directory -Path $destinationPath -ErrorAction SilentlyContinue | Out-Null
        Write-Host "Cloning '$repoUrl' to '$repoFolder'..."
        git clone $repoUrl $repoFolder
        if ($LASTEXITCODE -eq 0) {
            Show-Success "Repository cloned successfully to '$repoFolder'."
        } else {
            Show-Error "Failed to clone repository. Git exit code: $LASTEXITCODE."
        }
    }
    catch {
        Show-Error "An error occurred during repository cloning: $($_.Exception.Message)"
    }
}

# 5. Modify defaults.json
Show-SectionHeader "Configuring defaults.json"
$defaultsJsonPath = Join-Path $repoFolder "defaults.json"

if (Test-Path $defaultsJsonPath) {
    try {
        $jsonContent = Get-Content $defaultsJsonPath | ConvertFrom-Json

        # Prompt for user ID or generate random
        Write-Host ""
        $chooseId = Read-Host "Do you want to enter a custom user ID (y/n)? (Default: y)"
        if ($chooseId -eq "y" -or $chooseId -eq "") {
            $customUserId = Read-Host "Enter your desired user ID (e.g., your_username_123)"
            if ([string]::IsNullOrWhiteSpace($customUserId)) {
                Show-Warning "No custom user ID entered. Generating a random one."
                $userId = Generate-RandomTechyUsername
            } else {
                $userId = $customUserId
            }
        } else {
            $userId = Generate-RandomTechyUsername
            Show-Warning "Generating a random user ID."
        }

        Show-Success "Setting user_id to: $userId"
        $jsonContent.user_id = $userId
        $jsonContent.user_update_index = -1
        Show-Success "Setting user_update_index to: -1"

        $jsonContent | ConvertTo-Json -Depth 4 | Set-Content $defaultsJsonPath
        Show-Success "defaults.json updated successfully."
    }
    catch {
        Show-Error "Failed to modify defaults.json: $($_.Exception.Message)"
    }
} else {
    Show-Error "defaults.json not found at '$defaultsJsonPath'. Skipping modification."
}

# 6. Install requirements and add pwdlv3 folder to PATH (permanently)
Show-SectionHeader "Installing Python Requirements and Adding to PATH"

# Re-check for Python command after Chocolatey installation
$pythonInstalledCheck = (Get-Command python -ErrorAction SilentlyContinue)
if (-not $pythonInstalledCheck) {
    # Sometimes Python is installed as 'python3' command
    $pythonInstalledCheck = (Get-Command python3 -ErrorAction SilentlyContinue)
}

if ($pythonInstalledCheck -and (Test-Path $repoFolder)) {
    $requirementsPath = Join-Path $repoFolder "requirements.txt"
    if (Test-Path $requirementsPath) {
        try {
            Write-Host "Installing Python requirements from '$requirementsPath'..."
            Set-Location $repoFolder # Change directory to the repository for pip to find files
            
            # Ensure pip is available; choco typically adds it to PATH.
            # Use 'python -m pip' for robustness.
            python -m pip install --upgrade pip setuptools wheel
            python -m pip install -r $requirementsPath
            
            if ($LASTEXITCODE -eq 0) {
                Show-Success "Python requirements installed successfully."
            } else {
                Show-Error "Failed to install Python requirements. Pip exit code: $LASTEXITCODE."
            }
            Set-Location $PSScriptRoot # Change back to original script directory
        }
        catch {
            Show-Error "An error occurred during Python requirements installation: $($_.Exception.Message)"
        }
    } else {
        Show-Warning "requirements.txt not found at '$requirementsPath'. Skipping Python requirements installation."
    }
} else {
    Show-Warning "Python is not installed or repository not cloned. Skipping Python requirements installation."
}


# Add pwdlv3 folder to PATH (permanently)
if (Test-Path $repoFolder) {
    try {
        Show-SectionHeader "Adding '$repoFolder' to System PATH"
        $currentPath = [Environment]::GetEnvironmentVariable("PATH", "Machine")
        if ($currentPath -notlike "*$repoFolder*") {
            $newPath = "$currentPath;$repoFolder"
            [Environment]::SetEnvironmentVariable("PATH", $newPath, "Machine")
            Show-Success "'$repoFolder' added to System PATH permanently."
            Show-Warning "You may need to restart your PowerShell or command prompt for the PATH changes to take effect."
        } else {
            Show-Warning "'$repoFolder' is already in the System PATH. Skipping."
        }
    }
    catch {
        Show-Error "Failed to add '$repoFolder' to System PATH: $($_.Exception.Message)"
    }
} else {
    Show-Error "Repository folder '$repoFolder' not found. Cannot add to PATH."
}

Show-Header "Setup Complete!"
Write-Host "Please review the output for any errors or warnings."
Read-Host "Press Enter to exit..."