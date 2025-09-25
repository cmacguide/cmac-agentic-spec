# Script to fix MyInvocation.MyCommand.Path issues in all PowerShell scripts
# This script updates all PowerShell scripts to use robust path detection

param(
    [switch]$WhatIf = $false
)

# Function to update a script with robust ScriptDir detection
function Update-ScriptDir {
    param(
        [string]$FilePath
    )
    
    Write-Host "Updating $FilePath..." -ForegroundColor Yellow
    
    if ($WhatIf) {
        Write-Host "  [WHATIF] Would update script path detection" -ForegroundColor Cyan
        return
    }
    
    # Create backup
    $backupFile = "$FilePath.backup"
    Copy-Item $FilePath $backupFile -Force
    
    # Read the file content
    $content = Get-Content $FilePath -Raw
    
    # Replace the ScriptDir line with robust version
    $robustScriptDir = @'
# Get script directory with robust fallback
try {
    if ($MyInvocation.MyCommand.Path) {
        $ScriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
    } elseif ($PSScriptRoot) {
        $ScriptDir = $PSScriptRoot
    } else {
        # Fallback for release environments
        $ScriptDir = Split-Path -Parent $PSCommandPath
    }
} catch {
    # Ultimate fallback - search for dependencies in common locations
    $ScriptDir = Get-Location
    $commonLocations = @(".specify/scripts", "scripts/powershell", "../powershell", ".")
    foreach ($location in $commonLocations) {
        $testPath = Join-Path $location "common.ps1"
        if (Test-Path $testPath) {
            $ScriptDir = Resolve-Path $location
            break
        }
    }
}
'@
    
    # Replace the old pattern
    $patterns = @(
        '\$ScriptDir = Split-Path -Parent \$MyInvocation\.MyCommand\.Path',
        '\$ScriptDir = Split-Path -Parent \$MyInvocation\.MyCommand\.Path'
    )
    
    foreach ($pattern in $patterns) {
        if ($content -match $pattern) {
            $content = $content -replace $pattern, $robustScriptDir
            break
        }
    }
    
    # Write the updated content back
    $content | Out-File -FilePath $FilePath -Encoding UTF8
    
    Write-Host "  ✅ Updated $FilePath" -ForegroundColor Green
}

# Function to update execution check
function Update-ExecutionCheck {
    param(
        [string]$FilePath
    )
    
    Write-Host "Updating execution check in $FilePath..." -ForegroundColor Yellow
    
    if ($WhatIf) {
        Write-Host "  [WHATIF] Would update execution check" -ForegroundColor Cyan
        return
    }
    
    # Read the file content
    $content = Get-Content $FilePath -Raw
    
    # Replace the execution check with robust version
    $robustExecutionCheck = 'if ($MyInvocation.InvocationName -ne ''.'' -and $MyInvocation.MyCommand.Name -ne $null) {'
    
    $patterns = @(
        'if \(\$MyInvocation\.InvocationName -ne ''\.''\) \{',
        'if \(\$MyInvocation\.InvocationName -ne "\."\) \{'
    )
    
    foreach ($pattern in $patterns) {
        if ($content -match $pattern) {
            $content = $content -replace $pattern, $robustExecutionCheck
            break
        }
    }
    
    # Write the updated content back
    $content | Out-File -FilePath $FilePath -Encoding UTF8
    
    Write-Host "  ✅ Updated execution check in $FilePath" -ForegroundColor Green
}

# Get script directory
$currentScriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path

# List of scripts to update
$scriptsToUpdate = @(
    "$currentScriptDir\knowledge-base-integration.ps1",
    "$currentScriptDir\update-agent-context.ps1",
    "$currentScriptDir\..\tests\kb-integration-tests.ps1",
    "$currentScriptDir\..\tests\artifact-integration-tests.ps1"
)

Write-Host "=== Fixing MyInvocation.MyCommand.Path issues in PowerShell scripts ===" -ForegroundColor Magenta

if ($WhatIf) {
    Write-Host "Running in WHATIF mode - no changes will be made" -ForegroundColor Yellow
}

foreach ($script in $scriptsToUpdate) {
    if (Test-Path $script) {
        $content = Get-Content $script -Raw
        
        # Check if script has ScriptDir line to update
        if ($content -match '\$ScriptDir = Split-Path -Parent \$MyInvocation\.MyCommand\.Path') {
            Update-ScriptDir -FilePath $script
        }
        
        # Check if script has execution check to update
        if ($content -match 'if \(\$MyInvocation\.InvocationName -ne') {
            Update-ExecutionCheck -FilePath $script
        }
    } else {
        Write-Host "⚠️  Script not found: $script" -ForegroundColor Red
    }
}

Write-Host ""
Write-Host "=== Summary ===" -ForegroundColor Magenta
if (-not $WhatIf) {
    Write-Host "✅ All PowerShell scripts have been updated with robust path handling" -ForegroundColor Green
    Write-Host "📁 Backup files created with .backup extension" -ForegroundColor Cyan
} else {
    Write-Host "📋 WHATIF mode completed - no changes were made" -ForegroundColor Yellow
}
Write-Host ""
Write-Host "The scripts now:" -ForegroundColor White
Write-Host "  - Use fallback detection when MyInvocation.MyCommand.Path is not available" -ForegroundColor White
Write-Host "  - Search for dependencies in common locations (.specify/scripts, scripts/powershell, etc.)" -ForegroundColor White
Write-Host "  - Handle execution checks robustly for release environments" -ForegroundColor White
Write-Host ""
Write-Host "To test the changes, you can run:" -ForegroundColor Cyan
Write-Host "  .\scripts\powershell\script-path-detection.ps1 test" -ForegroundColor Cyan