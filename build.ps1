param (
    [switch]$Watch
)

$ErrorActionPreference = "Continue"

# 1. Ensure ps2exe is installed
if (-not (Get-Module -ListAvailable -Name ps2exe)) {
    Write-Host "Installing ps2exe module for compiling. This may take a moment..." -ForegroundColor Cyan
    # Ensure NuGet provider is ready so it doesn't prompt
    Install-PackageProvider -Name NuGet -MinimumVersion 2.8.5.201 -Force -Scope CurrentUser | Out-Null
    Install-Module -Name ps2exe -Scope CurrentUser -Force -AllowClobber 
}

Import-Module ps2exe

function Build-App {
    Write-Host "`n[$(Get-Date -Format 'HH:mm:ss')] Starting build process..." -ForegroundColor Cyan
    
    $sourceFile = "$PSScriptRoot\Clean-Autodesk.ps1"
    $exeOut = "$PSScriptRoot\Autodesk-Fixer.exe"
    $iconPng = "$PSScriptRoot\assets\icon.png"
    $iconIco = "$PSScriptRoot\assets\icon.ico"

    # 2. Skip icon generation since PNG to ICO conversion creates invalid files for CSC compiler
    $iconIco = $null

    # 3. Compile to EXE using ps2exe
    $ps2exeArgs = @{
        inputFile = $sourceFile
        outputFile = $exeOut
        noConsole = $true
        RequireAdmin = $true
        title = "Autodesk Windows Fixer"
        description = "A powerful UI cleaner for Autodesk software."
        version = "1.0.0.0"
    }

    if ($iconIco -and (Test-Path $iconIco)) {
        $ps2exeArgs.iconFile = $iconIco
    }

    try {
        Invoke-ps2exe @ps2exeArgs -ErrorAction Stop
        Write-Host "[$(Get-Date -Format 'HH:mm:ss')] Build successful! -> $exeOut" -ForegroundColor Green
    } catch {
        Write-Host "[$(Get-Date -Format 'HH:mm:ss')] Build failed: $_" -ForegroundColor Red
    }
}

# Run build once immediately
Build-App

# 4. Watch loop if requested
if ($Watch) {
    Write-Host "`nWatching for changes in Clean-Autodesk.ps1..." -ForegroundColor Yellow
    Write-Host "Press Ctrl+C to stop auto-building.`n" -ForegroundColor DarkGray
    
    $watcher = New-Object IO.FileSystemWatcher $PSScriptRoot, "Clean-Autodesk.ps1"
    $watcher.EnableRaisingEvents = $true

    while ($true) {
        $result = $watcher.WaitForChanged([System.IO.WatcherChangeTypes]::Changed, 1000)
        if ($result.TimedOut -eq $false) {
            # Debounce quick consecutive saves
            Start-Sleep -Milliseconds 1000
            Build-App
            Write-Host "`nWatching for changes..." -ForegroundColor Yellow
        }
    }
}
