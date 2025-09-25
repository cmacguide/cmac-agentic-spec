# Script Path Detection Module
# Provides robust script directory detection for both development and release environments

function Get-ScriptDir {
    <#
    .SYNOPSIS
    Get script directory with robust fallback mechanism
    
    .DESCRIPTION
    Attempts multiple methods to determine the current script directory,
    with fallbacks for release environments where standard variables may not be available.
    #>
    
    # Method 1: Try $MyInvocation.MyCommand.Path (works in most development environments)
    try {
        if ($MyInvocation.MyCommand.Path) {
            $scriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
            if (Test-Path $scriptDir) {
                return $scriptDir
            }
        }
    } catch {
        # Continue to next method
    }
    
    # Method 2: Try $PSScriptRoot (PowerShell 3.0+)
    try {
        if ($PSScriptRoot) {
            if (Test-Path $PSScriptRoot) {
                return $PSScriptRoot
            }
        }
    } catch {
        # Continue to next method
    }
    
    # Method 3: Try $PSCommandPath (PowerShell 3.0+)
    try {
        if ($PSCommandPath) {
            $scriptDir = Split-Path -Parent $PSCommandPath
            if (Test-Path $scriptDir) {
                return $scriptDir
            }
        }
    } catch {
        # Continue to next method
    }
    
    # Method 4: Try current location if it looks like a scripts directory
    $currentLocation = Get-Location
    if ($currentLocation.Path -match "scripts" -or $currentLocation.Path -match "powershell") {
        return $currentLocation.Path
    }
    
    # Method 5: Look for .specify/scripts from current directory upward
    $currentDir = Get-Location
    while ($currentDir.Path -ne (Split-Path $currentDir.Path -Qualifier)) {
        $specifyScripts = Join-Path $currentDir.Path ".specify/scripts"
        if (Test-Path $specifyScripts) {
            return $specifyScripts
        }
        $currentDir = Split-Path $currentDir.Path -Parent
    }
    
    # Method 6: Look for scripts directory from current directory upward
    $currentDir = Get-Location
    while ($currentDir.Path -ne (Split-Path $currentDir.Path -Qualifier)) {
        $scriptsPath = Join-Path $currentDir.Path "scripts/powershell"
        if (Test-Path $scriptsPath) {
            return $scriptsPath
        }
        $currentDir = Split-Path $currentDir.Path -Parent
    }
    
    # Method 7: Final fallback - assume we're in a release environment
    $repoRoot = Get-RobustRepoRoot
    if ($repoRoot) {
        # Try .specify/scripts first (release environment)
        $specifyScripts = Join-Path $repoRoot ".specify/scripts"
        if (Test-Path $specifyScripts) {
            return $specifyScripts
        }
        # Fallback to scripts/powershell (development environment)
        $scriptsPath = Join-Path $repoRoot "scripts/powershell"
        if (Test-Path $scriptsPath) {
            return $scriptsPath
        }
    }
    
    # Ultimate fallback - return current directory
    return (Get-Location).Path
}

function Get-RobustRepoRoot {
    <#
    .SYNOPSIS
    Get repository root with robust detection
    
    .DESCRIPTION
    Attempts multiple methods to find the repository root directory,
    working in both git and non-git environments.
    #>
    
    # Try git first
    try {
        $gitRoot = git rev-parse --show-toplevel 2>$null
        if ($LASTEXITCODE -eq 0 -and $gitRoot) {
            return $gitRoot
        }
    } catch {
        # Continue to next method
    }
    
    # Try to find repo root by looking for common files
    $currentDir = Get-Location
    while ($currentDir.Path -ne (Split-Path $currentDir.Path -Qualifier)) {
        $commonFiles = @("pyproject.toml", ".gitignore", "README.md", "CHANGELOG.md")
        foreach ($file in $commonFiles) {
            $filePath = Join-Path $currentDir.Path $file
            if (Test-Path $filePath) {
                return $currentDir.Path
            }
        }
        $currentDir = Split-Path $currentDir.Path -Parent
    }
    
    # Try relative to script directory
    $scriptDir = Get-ScriptDir
    if ($scriptDir) {
        # If we're in .specify/scripts, go up 2 levels
        if ($scriptDir -match "\.specify[/\\]scripts") {
            $repoRoot = Split-Path (Split-Path $scriptDir -Parent) -Parent
            if (Test-Path $repoRoot) {
                return $repoRoot
            }
        }
        # If we're in scripts/powershell, go up 2 levels
        if ($scriptDir -match "scripts[/\\]powershell") {
            $repoRoot = Split-Path (Split-Path $scriptDir -Parent) -Parent
            if (Test-Path $repoRoot) {
                return $repoRoot
            }
        }
        # If we're in scripts, go up 1 level
        if ($scriptDir -match "scripts") {
            $repoRoot = Split-Path $scriptDir -Parent
            if (Test-Path $repoRoot) {
                return $repoRoot
            }
        }
    }
    
    # Final fallback
    return (Get-Location).Path
}

function Test-ScriptPathDetection {
    <#
    .SYNOPSIS
    Test function to verify script path detection
    #>
    
    Write-Host "=== Script Path Detection Test ==="
    Write-Host "Script Directory: $(Get-ScriptDir)"
    Write-Host "Repository Root: $(Get-RobustRepoRoot)"
    
    try {
        Write-Host "MyInvocation.MyCommand.Path: $($MyInvocation.MyCommand.Path)"
    } catch {
        Write-Host "MyInvocation.MyCommand.Path: NOT_AVAILABLE"
    }
    
    try {
        Write-Host "PSScriptRoot: $PSScriptRoot"
    } catch {
        Write-Host "PSScriptRoot: NOT_AVAILABLE"
    }
    
    try {
        Write-Host "PSCommandPath: $PSCommandPath"
    } catch {
        Write-Host "PSCommandPath: NOT_AVAILABLE"
    }
    
    Write-Host "Current Location: $(Get-Location)"
    Write-Host "=================================="
}

function Main {
    param(
        [Parameter(Mandatory=$false)]
        [string]$Command = ""
    )
    
    switch ($Command) {
        "test" {
            Test-ScriptPathDetection
        }
        "script-dir" {
            Get-ScriptDir
        }
        "repo-root" {
            Get-RobustRepoRoot
        }
        default {
            Write-Host "Script Path Detection Module v1.0"
            Write-Host "Usage: script-path-detection.ps1 {test|script-dir|repo-root}"
            Write-Host ""
            Write-Host "Commands:"
            Write-Host "  test        - Run detection tests"
            Write-Host "  script-dir  - Get script directory"
            Write-Host "  repo-root   - Get repository root"
            Write-Host ""
            Write-Host "Functions available for importing:"
            Write-Host "  Get-ScriptDir        - Get current script directory"
            Write-Host "  Get-RobustRepoRoot   - Get repository root"
        }
    }
}

# Execute main function if script is run directly
if ($MyInvocation.InvocationName -ne '.') {
    Main -Command $args[0]
}