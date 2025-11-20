<#
.SYNOPSIS
    Installer for the b00t environment.
.DESCRIPTION
    This script bootstraps the b00t environment. It checks for prerequisites,
    installs Rust if necessary, clones the b00t repository, builds the core
    CLI as a DLL, and sets up PowerShell shims and the user's path.
.NOTES
    Run this script in a PowerShell terminal with an unrestricted execution policy.
    Example:
    Set-ExecutionPolicy -ExecutionPolicy Unrestricted -Scope Process
    .\install-b00t.ps1
#>

# Stop on any error
$ErrorActionPreference = "Stop"

# --- Configuration ---
$B00tRoot = "$HOME/.b00t"
$B00tSrcPath = Join-Path $B00tRoot "src"
$B00tBinPath = Join-Path $B00tRoot "bin"
# TODO: Replace with the actual repository URL
$RepoUrl = "https://github.com/your-org/your-b00t-repo.git" 

# --- Helper Functions ---

function Test-CommandExists {
    param($command)
    return (Get-Command $command -ErrorAction SilentlyContinue) -ne $null
}

function Add-To-PsProfile {
    param(
        [string]$LineToAdd
    )
    # Ensure the profile file exists
    if (-not (Test-Path $PROFILE)) {
        New-Item -Path $PROFILE -Type File -Force | Out-Null
    }

    # Check if the line is already in the profile
    $profileContent = Get-Content $PROFILE -Raw
    if ($profileContent -notlike "*$LineToAdd*") {
        Write-Host "Adding '$LineToAdd' to your PowerShell profile ($PROFILE)"
        Add-Content -Path $PROFILE -Value $LineToAdd
    } else {
        Write-Host "Path is already configured in your PowerShell profile."
    }
}


# --- Main Logic ---

# 1. Ensure b00t directories exist
Write-Host "--- Ensuring b00t directories exist at $B00tRoot ---"
if (-not (Test-Path $B00tRoot)) {
    New-Item -Path $B00tRoot -ItemType Directory | Out-Null
    New-Item -Path $B00tSrcPath -ItemType Directory | Out-Null
    New-Item -Path $B00tBinPath -ItemType Directory | Out-Null
}

# 2. Check for Git
Write-Host "--- Checking for Git ---"
if (-not (Test-CommandExists "git")) {
    Write-Error "Git is not found. Please install Git and ensure it is in your PATH."
    exit 1
}
Write-Host "Git found."

# 3. Check for Rust/Cargo
Write-Host "--- Checking for Rust (cargo) ---"
if (-not (Test-CommandExists "cargo")) {
    Write-Host "Cargo not found. Installing Rust via rustup..."
    
    # Download and run rustup-init.exe for Windows
    $rustupInstaller = Join-Path $env:TEMP "rustup-init.exe"
    Invoke-WebRequest -Uri "https://win.rustup.rs/" -OutFile $rustupInstaller
    
    # Run the installer non-interactively
    Start-Process -FilePath $rustupInstaller -ArgumentList "-y" -Wait
    
    # Clean up the installer
    Remove-Item $rustupInstaller

    # Add cargo to the current session's PATH to proceed
    Write-Host "Adding cargo to current session's PATH..."
    $env:Path += ";$HOME\.cargo\bin"
}
Write-Host "Rust (cargo) is available."


# 4. Clone or update the repository
Write-Host "--- Cloning/Updating b00t repository ---"
if (Test-Path (Join-Path $B00tSrcPath ".git")) {
    Write-Host "Repository already exists. Pulling latest changes..."
    Push-Location $B00tSrcPath
    git pull
    Pop-Location
} else {
    Write-Host "Cloning repository from $RepoUrl..."
    git clone $RepoUrl $B00tSrcPath
}

# 5. Build the b00t-cli DLL
Write-Host "--- Building b00t-cli library (DLL) ---"
$b00tCliPath = Join-Path $B00tSrcPath "b00t-cli"
Push-Location $b00tCliPath
cargo build --release
Pop-Location
Write-Host "Build complete."


# 6. Install the b00t Python package using uv
Write-Host "--- Installing b00t via uv ---"
$wrapperPath = Join-Path $B00tSrcPath "b00t-py-wrapper"
Push-Location $wrapperPath
# This command builds the Rust extension and installs the 'b00t' command.
uv pip install .
Pop-Location


# --- Final Instructions ---
Write-Host -ForegroundColor Green "`nInstallation complete!"
Write-Host "The 'b00t' command is now available in your shell, managed by uv."
Write-Host "Try it out by running: b00t status"
