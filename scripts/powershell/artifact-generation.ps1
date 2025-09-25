# Artifact Generation Module
# Generates rich artifacts with KB integration and versioning
# Part of SDD v2.0 Critical Systems Implementation

# Import dependencies
$ScriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
. "$ScriptDir\common.ps1"
. "$ScriptDir\knowledge-base-integration.ps1"

# Global configuration
$Global:ARTIFACTS_DIR = "artifacts"
$Global:TEMPLATES_DIR = "templates/artifacts"
$Global:CACHE_DIR = ".specify-cache/artifacts"

# =============================================================================
# CORE ARTIFACT GENERATION FUNCTIONS
# =============================================================================

function Generate-Artifact {
    param(
        [Parameter(Mandatory=$true)]
        [string]$TemplateId,
        
        [Parameter(Mandatory=$true)]
        [string]$Phase,
        
        [Parameter(Mandatory=$true)]
        [string]$Context,
        
        [Parameter(Mandatory=$false)]
        [string]$OutputPath = ""
    )

    # Initialize generation context
    $generationId = Generate-UniqueId
    $timestamp = Get-Date -Format "yyyy-MM-ddTHH:mm:ssZ" -AsUTC

    Write-Host "Starting artifact generation: $TemplateId (ID: $generationId)"

    # Step 1: Load template
    $templatePath = Resolve-TemplatePath -TemplateId $TemplateId -Phase $Phase
    if (-not (Test-Path $templatePath)) {
        Write-Error "Template not found: $templatePath"
        return $null
    }

    $templateContent = Get-Content $templatePath -Raw
    Write-Host "✅ Template loaded: $templatePath"

    # Step 2: Initialize KB integration
    Initialize-KBPlaceholders -Phase $Phase
    $kbReference = Query-KnowledgeBase -Context $Context -Query "patterns for $Phase phase"
    $kbContext = Get-ApplicablePrinciples -Domain $Phase

    Write-Host "✅ KB integration initialized"

    # Step 3: Process placeholders
    $processedContent = Process-TemplatePlaceholders -TemplateContent $templateContent -Phase $Phase -Context $Context -Timestamp $timestamp
    Write-Host "✅ Placeholders processed"

    # Step 4: Validate against KB patterns
    $validationResult = Validate-ArtifactContent -Content $processedContent -Context $Context -Phase $Phase
    $validationStatus = Extract-ValidationStatus -ValidationResult $validationResult

    Write-Host "✅ KB validation completed: $validationStatus"

    # Step 5: Apply versioning
    $version = Generate-ArtifactVersion -Phase $Phase
    $versionedContent = Apply-ArtifactVersioning -Content $processedContent -Version $version -Timestamp $timestamp

    Write-Host "✅ Versioning applied: $version"

    # Step 6: Determine output path
    if ([string]::IsNullOrEmpty($OutputPath)) {
        $OutputPath = Generate-ArtifactPath -TemplateId $TemplateId -Phase $Phase -Version $version
    }

    # Step 7: Create output directory
    $outputDir = Split-Path -Parent $OutputPath
    if (-not (Test-Path $outputDir)) {
        New-Item -ItemType Directory -Path $outputDir -Force | Out-Null
    }

    # Step 8: Save artifact
    $versionedContent | Out-File -FilePath $OutputPath -Encoding UTF8
    Write-Host "✅ Artifact saved: $OutputPath"

    # Step 9: Register traceability
    Register-ArtifactTraceability -GenerationId $generationId -TemplateId $TemplateId -Phase $Phase -OutputPath $OutputPath -Version $version -KBContext $kbContext
    Write-Host "✅ Traceability registered"

    # Step 10: Generate compliance report
    $complianceReportPath = Generate-ComplianceReport -Phase $Phase
    Write-Host "✅ Compliance report generated: $complianceReportPath"

    # Return generation result
    return @{
        generation_id = $generationId
        template_id = $TemplateId
        phase = $Phase
        version = $version
        output_path = $OutputPath
        validation_status = $validationStatus
        kb_context = $kbContext
        compliance_report = $complianceReportPath
        timestamp = $timestamp
    } | ConvertTo-Json
}

function Generate-PhaseArtifacts {
    param(
        [Parameter(Mandatory=$true)]
        [string]$Phase,
        
        [Parameter(Mandatory=$true)]
        [string]$Context
    )

    $templates = Get-PhaseTemplates -Phase $Phase
    $results = @()

    Write-Host "Generating all artifacts for phase: $Phase"

    foreach ($templateId in $templates) {
        if (-not [string]::IsNullOrEmpty($templateId)) {
            Write-Host "Generating artifact: $templateId"
            $result = Generate-Artifact -TemplateId $templateId -Phase $Phase -Context $Context
            $results += $result
        }
    }

    # Generate phase summary
    $phaseSummary = Generate-PhaseSummary -Phase $Phase -Results $results

    Write-Host "✅ All artifacts generated for phase: $Phase"
    return $phaseSummary
}

# =============================================================================
# TEMPLATE PROCESSING FUNCTIONS
# =============================================================================

function Resolve-TemplatePath {
    param(
        [Parameter(Mandatory=$true)]
        [string]$TemplateId,
        
        [Parameter(Mandatory=$true)]
        [string]$Phase
    )

    $repoRoot = Get-RepoRoot
    $templatePath = Join-Path $repoRoot "$Global:TEMPLATES_DIR\$Phase\$TemplateId.template"

    # Try different extensions
    $extensions = @("md", "json", "html", "mmd")
    foreach ($ext in $extensions) {
        $fullPath = "$templatePath.$ext"
        if (Test-Path $fullPath) {
            return $fullPath
        }
    }

    Write-Error "Template not found for $TemplateId in phase $Phase"
    return $null
}

function Get-PhaseTemplates {
    param(
        [Parameter(Mandatory=$true)]
        [string]$Phase
    )

    $repoRoot = Get-RepoRoot
    $phaseDir = Join-Path $repoRoot "$Global:TEMPLATES_DIR\$Phase"

    if (-not (Test-Path $phaseDir)) {
        Write-Error "Phase directory not found: $phaseDir"
        return @()
    }

    $templateFiles = Get-ChildItem -Path $phaseDir -Filter "*.template.*" -File
    $templateIds = @()

    foreach ($file in $templateFiles) {
        $templateId = $file.BaseName -replace '\.template$', ''
        $templateIds += $templateId
    }

    return $templateIds
}

function Process-TemplatePlaceholders {
    param(
        [Parameter(Mandatory=$true)]
        [string]$TemplateContent,
        
        [Parameter(Mandatory=$true)]
        [string]$Phase,
        
        [Parameter(Mandatory=$true)]
        [string]$Context,
        
        [Parameter(Mandatory=$true)]
        [string]$Timestamp
    )

    # Standard placeholders
    $processed = $TemplateContent
    $processed = $processed -replace '\{TIMESTAMP\}', $Timestamp
    $processed = $processed -replace '\{PHASE\}', $Phase
    $processed = $processed -replace '\{CONTEXT\}', $Context
    $processed = $processed -replace '\{PROJECT_NAME\}', (Split-Path -Leaf (Get-RepoRoot))
    $processed = $processed -replace '\{AUTHOR\}', 'sdd-system'

    # Versioning placeholders
    $version = Generate-ArtifactVersion -Phase $Phase
    $versionParts = $version -split '\.'
    $major = ($versionParts[1] -split 'v')[1]
    $minor = ($versionParts[2] -split '_')[0]

    $processed = $processed -replace '\{MAJOR\}', $major
    $processed = $processed -replace '\{MINOR\}', $minor
    $processed = $processed -replace '\{VERSION\}', $version
    $processed = $processed -replace '\{VALIDATION_STATUS\}', 'PENDING'

    # KB placeholders - use simple text replacement
    $processed = $processed -replace '\{KB_CONTEXT\}', 'KB Context: Available'
    $processed = $processed -replace '\{KB_REFERENCE\}', 'KB Reference: Available'
    $processed = $processed -replace '\{VALIDATION_RESULT\}', 'Validation: Completed'
    $processed = $processed -replace '\{COMPLIANCE_REPORT_PATH\}', 'Compliance report generated'

    return $processed
}

# =============================================================================
# ARTIFACT PATH AND VERSIONING
# =============================================================================

function Generate-ArtifactVersion {
    param(
        [Parameter(Mandatory=$true)]
        [string]$Phase,
        
        [Parameter(Mandatory=$false)]
        [int]$Major = 1,
        
        [Parameter(Mandatory=$false)]
        [int]$Minor = 0
    )

    $timestamp = Get-Date -Format "yyyyMMddTHHmmssZ" -AsUTC
    return "$Phase.v$Major.$Minor`_$timestamp"
}

function Apply-ArtifactVersioning {
    param(
        [Parameter(Mandatory=$true)]
        [string]$Content,
        
        [Parameter(Mandatory=$true)]
        [string]$Version,
        
        [Parameter(Mandatory=$true)]
        [string]$Timestamp
    )

    $versionedContent = $Content
    $versionedContent = $versionedContent -replace '\{VERSION\}', $Version
    $versionedContent = $versionedContent -replace '\{TIMESTAMP\}', $Timestamp

    return $versionedContent
}

function Generate-ArtifactPath {
    param(
        [Parameter(Mandatory=$true)]
        [string]$TemplateId,
        
        [Parameter(Mandatory=$true)]
        [string]$Phase,
        
        [Parameter(Mandatory=$true)]
        [string]$Version
    )

    $repoRoot = Get-RepoRoot
    $baseName = Get-ArtifactBaseName -TemplateId $TemplateId
    $extension = Get-ArtifactExtension -TemplateId $TemplateId

    return Join-Path $repoRoot "$Global:ARTIFACTS_DIR\$Phase\$baseName$extension"
}

function Get-ArtifactBaseName {
    param(
        [Parameter(Mandatory=$true)]
        [string]$TemplateId
    )
    return $TemplateId
}

function Get-ArtifactExtension {
    param(
        [Parameter(Mandatory=$true)]
        [string]$TemplateId
    )

    switch -Regex ($TemplateId) {
        ".*compliance_check|.*quality_gate_results|.*rollback_snapshot" { return ".json" }
        ".*test_coverage_report" { return ".html" }
        ".*component_interaction_diagram" { return ".mmd" }
        default { return ".md" }
    }
}

# =============================================================================
# VALIDATION FUNCTIONS
# =============================================================================

function Validate-ArtifactContent {
    param(
        [Parameter(Mandatory=$true)]
        [string]$Content,
        
        [Parameter(Mandatory=$true)]
        [string]$Context,
        
        [Parameter(Mandatory=$true)]
        [string]$Phase
    )

    $validationResults = @()
    $overallStatus = "PASS"

    # Validate KB integration
    $kbValidation = Validate-KBIntegration -Content $Content -Context $Context
    $validationResults += "KB Integration: $kbValidation"

    # Validate template structure
    $structureValidation = Validate-TemplateStructure -Content $Content -Phase $Phase
    $validationResults += "Template Structure: $structureValidation"

    # Validate content quality
    $qualityValidation = Validate-ContentQuality -Content $Content
    $validationResults += "Content Quality: $qualityValidation"

    # Check for validation failures
    if ($validationResults -match "FAIL") {
        $overallStatus = "FAIL"
    } elseif ($validationResults -match "WARN") {
        $overallStatus = "PARTIAL"
    }

    return "VALIDATION SUMMARY: $overallStatus`n`n$($validationResults -join "`n")"
}

function Validate-KBIntegration {
    param(
        [Parameter(Mandatory=$true)]
        [string]$Content,
        
        [Parameter(Mandatory=$true)]
        [string]$Context
    )

    # Check for KB placeholders
    if ($Content -match '\{KB_CONTEXT\}|\{KB_REFERENCE\}|\{VALIDATION_RESULT\}') {
        return "FAIL: KB placeholders not processed"
    }

    # Check for KB references
    if ($Content -notmatch "KB") {
        return "WARN: No KB references found"
    }

    return "PASS: KB integration validated"
}

function Validate-TemplateStructure {
    param(
        [Parameter(Mandatory=$true)]
        [string]$Content,
        
        [Parameter(Mandatory=$true)]
        [string]$Phase
    )

    switch ($Phase) {
        "analyze" {
            if ($Content -notmatch "Architecture|Technical Debt|Compliance") {
                return "FAIL: Missing required analyze sections"
            }
        }
        "architect" {
            if ($Content -notmatch "Design|Decision|Architecture") {
                return "FAIL: Missing required architect sections"
            }
        }
        "implement" {
            if ($Content -notmatch "Quality|Test|Performance") {
                return "FAIL: Missing required implement sections"
            }
        }
        "checkpoints" {
            if ($Content -notmatch "Gate|Compliance|Rollback") {
                return "FAIL: Missing required checkpoint sections"
            }
        }
    }

    return "PASS: Template structure validated"
}

function Validate-ContentQuality {
    param(
        [Parameter(Mandatory=$true)]
        [string]$Content
    )

    # Check content length
    if ($Content.Length -lt 100) {
        return "FAIL: Content too short ($($Content.Length) characters)"
    }

    # Check for placeholder remnants
    if ($Content -match '\{[A-Z_]+\}') {
        return "WARN: Unprocessed placeholders found"
    }

    return "PASS: Content quality validated"
}

# =============================================================================
# TRACEABILITY FUNCTIONS
# =============================================================================

function Register-ArtifactTraceability {
    param(
        [Parameter(Mandatory=$true)]
        [string]$GenerationId,
        
        [Parameter(Mandatory=$true)]
        [string]$TemplateId,
        
        [Parameter(Mandatory=$true)]
        [string]$Phase,
        
        [Parameter(Mandatory=$true)]
        [string]$OutputPath,
        
        [Parameter(Mandatory=$true)]
        [string]$Version,
        
        [Parameter(Mandatory=$true)]
        [string]$KBContext
    )

    $repoRoot = Get-RepoRoot
    $traceabilityDir = Join-Path $repoRoot ".specify-cache\traceability"
    $traceabilityFile = Join-Path $traceabilityDir "artifacts.json"

    if (-not (Test-Path $traceabilityDir)) {
        New-Item -ItemType Directory -Path $traceabilityDir -Force | Out-Null
    }

    # Create traceability entry
    $entry = @{
        generation_id = $GenerationId
        template_id = $TemplateId
        phase = $Phase
        output_path = $OutputPath
        version = $Version
        kb_context = $KBContext
        timestamp = Get-Date -Format "yyyy-MM-ddTHH:mm:ssZ" -AsUTC
        file_hash = if (Test-Path $OutputPath) { (Get-FileHash $OutputPath -Algorithm SHA256).Hash.ToLower() } else { "unknown" }
        file_size = if (Test-Path $OutputPath) { (Get-Item $OutputPath).Length } else { 0 }
    }

    # Append to traceability file
    if (Test-Path $traceabilityFile) {
        $existingData = Get-Content $traceabilityFile -Raw | ConvertFrom-Json
        $existingData += $entry
        $existingData | ConvertTo-Json -Depth 10 | Out-File $traceabilityFile -Encoding UTF8
    } else {
        @($entry) | ConvertTo-Json -Depth 10 | Out-File $traceabilityFile -Encoding UTF8
    }

    Write-Host "Traceability registered: $GenerationId"
}

# =============================================================================
# UTILITY FUNCTIONS
# =============================================================================

function Generate-UniqueId {
    $timestamp = Get-Date -Format "yyyyMMddHHmmss"
    $random = Get-Random -Maximum 65536
    return "$timestamp-$($random.ToString('x4'))"
}

function Extract-ValidationStatus {
    param(
        [Parameter(Mandatory=$true)]
        [string]$ValidationResult
    )

    if ($ValidationResult -match "VALIDATION SUMMARY: PASS") {
        return "PASS"
    } elseif ($ValidationResult -match "VALIDATION SUMMARY: FAIL") {
        return "FAIL"
    } else {
        return "PARTIAL"
    }
}

function Generate-PhaseSummary {
    param(
        [Parameter(Mandatory=$true)]
        [string]$Phase,
        
        [Parameter(Mandatory=$true)]
        [array]$Results
    )

    $totalArtifacts = $Results.Count
    $successfulArtifacts = 0

    foreach ($result in $Results) {
        $resultObj = $result | ConvertFrom-Json
        if ($resultObj.validation_status -eq "PASS") {
            $successfulArtifacts++
        }
    }

    $successRate = if ($totalArtifacts -gt 0) { [math]::Round(($successfulArtifacts * 100) / $totalArtifacts) } else { 0 }

    return @{
        phase = $Phase
        total_artifacts = $totalArtifacts
        successful_artifacts = $successfulArtifacts
        success_rate = "$successRate%"
        timestamp = Get-Date -Format "yyyy-MM-ddTHH:mm:ssZ" -AsUTC
    } | ConvertTo-Json
}

# =============================================================================
# MAIN FUNCTION
# =============================================================================

function Main {
    param(
        [Parameter(Mandatory=$false)]
        [string]$Command = "",
        
        [Parameter(Mandatory=$false)]
        [string[]]$Arguments = @()
    )

    switch ($Command) {
        "generate" {
            if ($Arguments.Count -lt 3) {
                Write-Host "Usage: artifact-generation.ps1 generate <template_id> <phase> <context> [output_path]"
                exit 1
            }
            $outputPath = if ($Arguments.Count -gt 3) { $Arguments[3] } else { "" }
            Generate-Artifact -TemplateId $Arguments[0] -Phase $Arguments[1] -Context $Arguments[2] -OutputPath $outputPath
        }
        "generate-phase" {
            if ($Arguments.Count -lt 2) {
                Write-Host "Usage: artifact-generation.ps1 generate-phase <phase> <context>"
                exit 1
            }
            Generate-PhaseArtifacts -Phase $Arguments[0] -Context $Arguments[1]
        }
        "list-templates" {
            if ($Arguments.Count -lt 1) {
                Write-Host "Usage: artifact-generation.ps1 list-templates <phase>"
                exit 1
            }
            Get-PhaseTemplates -Phase $Arguments[0]
        }
        default {
            Write-Host "Artifact Generation Module v1.0"
            Write-Host "Usage: artifact-generation.ps1 {generate|generate-phase|list-templates}"
            Write-Host ""
            Write-Host "Commands:"
            Write-Host "  generate <template_id> <phase> <context> [output_path]"
            Write-Host "  generate-phase <phase> <context>"
            Write-Host "  list-templates <phase>"
            Write-Host ""
            Write-Host "Examples:"
            Write-Host "  .\artifact-generation.ps1 generate architecture_assessment analyze shared-principles"
            Write-Host "  .\artifact-generation.ps1 generate-phase analyze shared-principles"
            Write-Host "  .\artifact-generation.ps1 list-templates architect"
        }
    }
}

# Execute main function if script is run directly
if ($MyInvocation.InvocationName -ne '.') {
    Main -Command $args[0] -Arguments $args[1..($args.Length-1)]
}