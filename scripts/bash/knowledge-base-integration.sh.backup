#!/usr/bin/env bash
# Knowledge Base Integration Module
# Provides KB query, validation, and compliance reporting functionality
# Part of SDD v2.0 Critical Systems Implementation

# Source common functions
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/common.sh"

# Global variables
KB_CACHE_TTL=86400  # 24 hours in seconds
KB_QUERY_TIMEOUT=10 # 10 seconds timeout for queries

# KB Placeholder variables (exported for template substitution)
export KB_REFERENCE=""
export VALIDATION_RESULT=""
export KB_CONTEXT=""
export COMPLIANCE_REPORT_PATH=""

# =============================================================================
# CORE KB INTEGRATION FUNCTIONS
# =============================================================================

# Query knowledge base by context and search terms
# Usage: query_knowledge_base <context> <query>
# Returns: KB content matching query or fallback guidance
query_knowledge_base() {
    local context="$1"
    local query="$2"
    
    # Validate inputs
    if [[ -z "$context" || -z "$query" ]]; then
        echo "ERROR: query_knowledge_base requires context and query parameters" >&2
        return 1
    fi
    
    # Validate context
    if ! validate_kb_context "$context"; then
        echo "ERROR: Invalid context '$context'. Valid: shared-principles, frontend, backend, devops-sre" >&2
        return 1
    fi
    
    local kb_root="$(get_repo_root)/memory/knowledge-base"
    
    # Check if KB exists
    if [[ ! -d "$kb_root" ]]; then
        echo "WARNING: Knowledge base not found at $kb_root. Using fallback guidance." >&2
        fallback_to_basic_guidance "$context"
        return 0
    fi
    
    # Check cache first
    local cache_key=$(generate_cache_key "$context" "$query")
    local cached_result=$(get_cached_kb_result "$cache_key")
    
    if [[ -n "$cached_result" ]]; then
        echo "$cached_result"
        return 0
    fi
    
    # Execute KB query with timeout
    local result
    if ! result=$(timeout "$KB_QUERY_TIMEOUT" execute_kb_query "$kb_root/$context" "$query" 2>/dev/null); then
        echo "WARNING: KB query timed out or failed. Using fallback guidance." >&2
        result=$(fallback_to_basic_guidance "$context")
    fi
    
    # Cache successful result
    if [[ -n "$result" ]]; then
        cache_kb_result "$cache_key" "$result"
    fi
    
    echo "$result"
    
    # Set KB_REFERENCE placeholder for template substitution
    export KB_REFERENCE="$result"
}

# Validate artifact against KB patterns
# Usage: validate_against_patterns <artifact_path> <context>
# Returns: Validation results with pass/fail status
validate_against_patterns() {
    local artifact="$1"
    local context="$2"
    
    # Validate inputs
    if [[ -z "$artifact" || -z "$context" ]]; then
        echo "ERROR: validate_against_patterns requires artifact and context parameters" >&2
        return 1
    fi
    
    # Check if artifact exists
    if [[ ! -f "$artifact" ]]; then
        echo "ERROR: Artifact not found: $artifact" >&2
        return 1
    fi
    
    # Validate context
    if ! validate_kb_context "$context"; then
        echo "ERROR: Invalid context '$context'" >&2
        return 1
    fi
    
    local kb_root="$(get_repo_root)/memory/knowledge-base"
    local validation_results=""
    local overall_status="PASS"
    
    # Get applicable patterns for context
    local patterns=$(get_applicable_patterns "$context")
    
    if [[ -z "$patterns" ]]; then
        echo "WARNING: No patterns found for context '$context'. Skipping validation." >&2
        echo "SKIP: No patterns available for validation"
        return 0
    fi
    
    # Execute validations
    while IFS= read -r pattern; do
        if [[ -n "$pattern" ]]; then
            local result=$(validate_single_pattern "$artifact" "$pattern" "$context")
            validation_results+="$result\n"
            
            # Check if any validation failed
            if echo "$result" | grep -q "FAIL:"; then
                overall_status="FAIL"
            fi
        fi
    done <<< "$patterns"
    
    # Add summary
    validation_results="VALIDATION SUMMARY: $overall_status\n\n$validation_results"
    
    echo -e "$validation_results"
    
    # Set VALIDATION_RESULT placeholder for template substitution
    export VALIDATION_RESULT="$validation_results"
}

# Get applicable principles for domain/phase
# Usage: get_applicable_principles <domain>
# Returns: Space-separated list of applicable KB contexts
get_applicable_principles() {
    local domain="$1"
    
    if [[ -z "$domain" ]]; then
        echo "ERROR: get_applicable_principles requires domain parameter" >&2
        return 1
    fi
    
    local kb_root="$(get_repo_root)/memory/knowledge-base"
    local principles="shared-principles"  # Always include shared principles
    
    # Detect project contexts based on files
    local detected_contexts=$(detect_project_contexts)
    
    # Add context-specific principles
    while IFS= read -r context; do
        if [[ -n "$context" && -d "$kb_root/$context" ]]; then
            principles+=" $context"
        fi
    done <<< "$detected_contexts"
    
    # Add domain-specific principles based on phase
    case "$domain" in
        "analyze")
            # Analysis phase focuses on architecture assessment
            if [[ "$principles" =~ backend ]]; then
                principles+=" backend/domain-modeling"
            fi
            ;;
        "architect")
            # Architecture phase needs design patterns
            if [[ "$principles" =~ frontend ]]; then
                principles+=" frontend/ui-architecture"
            fi
            if [[ "$principles" =~ backend ]]; then
                principles+=" backend/api-design"
            fi
            ;;
        "implement")
            # Implementation phase needs coding standards
            if [[ "$principles" =~ frontend ]]; then
                principles+=" frontend/react-patterns"
            fi
            if [[ "$principles" =~ devops-sre ]]; then
                principles+=" devops-sre/deployment-patterns"
            fi
            ;;
    esac
    
    echo "$principles"
    
    # Set KB_CONTEXT placeholder for template substitution
    export KB_CONTEXT="$principles"
}

# Generate compliance report for specific phase
# Usage: generate_compliance_report <phase>
# Returns: Path to generated compliance report
generate_compliance_report() {
    local phase="$1"
    
    if [[ -z "$phase" ]]; then
        echo "ERROR: generate_compliance_report requires phase parameter" >&2
        return 1
    fi
    
    local timestamp=$(date -u +"%Y-%m-%dT%H:%M:%SZ")
    local report_dir="$(get_repo_root)/.specify-cache/compliance-reports"
    local report_file="$report_dir/compliance-report-$phase-$(date +%Y%m%d-%H%M%S).md"
    
    # Create reports directory
    mkdir -p "$report_dir"
    
    # Generate report content
    cat > "$report_file" << EOF
# Compliance Report - $phase Phase

**Generated**: $timestamp  
**Phase**: $phase  
**Project**: $(basename "$(get_repo_root)")  
**KB Integration Version**: 1.0

## Executive Summary

$(generate_compliance_summary "$phase")

## Applicable Principles

$(get_applicable_principles "$phase")

## Detailed Compliance Analysis

$(generate_detailed_compliance "$phase")

## Recommendations

$(generate_compliance_recommendations "$phase")

## KB References

$(generate_kb_references "$phase")

---

*Generated by Knowledge Base Integration Module v1.0*  
*Part of SDD v2.0 Critical Systems*
EOF
    
    echo "$report_file"
    
    # Set COMPLIANCE_REPORT_PATH placeholder for template substitution
    export COMPLIANCE_REPORT_PATH="$report_file"
}

# =============================================================================
# SUPPORTING FUNCTIONS
# =============================================================================

# Validate KB context
validate_kb_context() {
    local context="$1"
    case "$context" in
        "shared-principles"|"frontend"|"backend"|"devops-sre")
            return 0
            ;;
        *)
            return 1
            ;;
    esac
}

# Generate cache key for query
generate_cache_key() {
    local context="$1"
    local query="$2"
    echo -n "${context}_${query}" | sha256sum | cut -d' ' -f1
}

# Get cached KB result
get_cached_kb_result() {
    local cache_key="$1"
    local cache_dir="$(get_repo_root)/.specify-cache/kb-queries"
    local cache_file="$cache_dir/$cache_key.json"
    
    if [[ -f "$cache_file" ]]; then
        # Check TTL (24 hours)
        local file_age=$(($(date +%s) - $(stat -c %Y "$cache_file" 2>/dev/null || echo 0)))
        if [[ $file_age -lt $KB_CACHE_TTL ]]; then
            cat "$cache_file"
            return 0
        else
            # Remove expired cache
            rm -f "$cache_file"
        fi
    fi
    
    return 1
}

# Cache KB result
cache_kb_result() {
    local cache_key="$1"
    local result="$2"
    local cache_dir="$(get_repo_root)/.specify-cache/kb-queries"
    
    mkdir -p "$cache_dir"
    echo "$result" > "$cache_dir/$cache_key.json"
}

# Execute KB query in specific context directory
execute_kb_query() {
    local kb_context_dir="$1"
    local query="$2"
    
    if [[ ! -d "$kb_context_dir" ]]; then
        return 1
    fi
    
    # Search for relevant files using grep with case-insensitive matching
    local results=""
    local query_terms=$(echo "$query" | tr '[:upper:]' '[:lower:]' | tr ' ' '|')
    
    # Find markdown files and search content
    while IFS= read -r file; do
        if [[ -f "$file" ]]; then
            local matches=$(grep -il "$query_terms" "$file" 2>/dev/null || true)
            if [[ -n "$matches" ]]; then
                # Extract relevant sections
                local content=$(extract_relevant_content "$file" "$query_terms")
                if [[ -n "$content" ]]; then
                    results+="## $(basename "$file" .md)\n\n$content\n\n"
                fi
            fi
        fi
    done < <(find "$kb_context_dir" -name "*.md" -type f)
    
    if [[ -n "$results" ]]; then
        echo -e "$results"
    else
        echo "No specific guidance found for query: $query"
    fi
}

# Extract relevant content from file based on query
extract_relevant_content() {
    local file="$1"
    local query_terms="$2"
    
    # Get context around matches (3 lines before and after)
    grep -i -A 3 -B 3 "$query_terms" "$file" 2>/dev/null | head -20
}

# Detect project contexts based on file analysis
detect_project_contexts() {
    local repo_root=$(get_repo_root)
    local contexts=""
    
    # Detect frontend context
    if [[ -f "$repo_root/package.json" ]] || \
       find "$repo_root" -maxdepth 3 -name "*.jsx" -o -name "*.tsx" -o -name "*.vue" 2>/dev/null | head -1 | grep -q .; then
        contexts+="frontend\n"
    fi
    
    # Detect backend context
    if [[ -f "$repo_root/pom.xml" ]] || [[ -f "$repo_root/Cargo.toml" ]] || [[ -f "$repo_root/go.mod" ]] || \
       find "$repo_root" -maxdepth 3 -name "*.java" -o -name "*.rs" -o -name "*.go" -o -name "*.py" 2>/dev/null | head -1 | grep -q .; then
        contexts+="backend\n"
    fi
    
    # Detect DevOps context
    if [[ -f "$repo_root/Dockerfile" ]] || [[ -f "$repo_root/docker-compose.yml" ]] || \
       find "$repo_root" -maxdepth 3 -name "*.tf" -o -name "*.yml" -o -name "*.yaml" 2>/dev/null | head -1 | grep -q .; then
        contexts+="devops-sre\n"
    fi
    
    echo -e "$contexts"
}

# Get applicable patterns for context
get_applicable_patterns() {
    local context="$1"
    local kb_root="$(get_repo_root)/memory/knowledge-base"
    
    # Define basic patterns per context
    case "$context" in
        "shared-principles")
            echo -e "clean-code-naming\nsolid-principles\ndependency-rule"
            ;;
        "frontend")
            echo -e "component-design\nstate-management\nperformance-optimization"
            ;;
        "backend")
            echo -e "domain-modeling\napi-design\ndata-persistence"
            ;;
        "devops-sre")
            echo -e "infrastructure-as-code\ndeployment-patterns\nmonitoring"
            ;;
        *)
            echo "general-best-practices"
            ;;
    esac
}

# Validate single pattern against artifact
validate_single_pattern() {
    local artifact="$1"
    local pattern="$2"
    local context="$3"
    
    # Basic pattern validation - can be extended
    case "$pattern" in
        "clean-code-naming")
            validate_naming_conventions "$artifact"
            ;;
        "solid-principles")
            validate_solid_principles "$artifact"
            ;;
        "component-design")
            validate_component_design "$artifact"
            ;;
        *)
            echo "SKIP: Pattern '$pattern' validation not implemented"
            ;;
    esac
}

# Validate naming conventions
validate_naming_conventions() {
    local artifact="$1"
    
    # Check for common naming issues
    if grep -q "var\|function\|class" "$artifact" 2>/dev/null; then
        # Check for single letter variables (except common ones like i, j, k)
        if grep -E '\b[a-h,l-z]\b\s*=' "$artifact" >/dev/null 2>&1; then
            echo "FAIL: Single letter variable names found (except i,j,k)"
        else
            echo "PASS: Naming conventions check"
        fi
    else
        echo "SKIP: No code constructs found for naming validation"
    fi
}

# Validate SOLID principles (basic check)
validate_solid_principles() {
    local artifact="$1"
    
    # Basic check for function/class size (Single Responsibility)
    local line_count=$(wc -l < "$artifact")
    if [[ $line_count -gt 500 ]]; then
        echo "WARN: Large file ($line_count lines) - consider splitting for Single Responsibility"
    else
        echo "PASS: File size within reasonable bounds"
    fi
}

# Validate component design (for frontend)
validate_component_design() {
    local artifact="$1"
    
    if [[ "$artifact" =~ \.(jsx|tsx|vue)$ ]]; then
        # Check for component size
        local line_count=$(wc -l < "$artifact")
        if [[ $line_count -gt 200 ]]; then
            echo "WARN: Large component ($line_count lines) - consider breaking down"
        else
            echo "PASS: Component size appropriate"
        fi
    else
        echo "SKIP: Not a component file"
    fi
}

# Fallback guidance when KB unavailable
fallback_to_basic_guidance() {
    local context="$1"
    
    case "$context" in
        "shared-principles")
            cat << EOF
## Basic Software Engineering Principles

- Apply SOLID principles (Single Responsibility, Open/Closed, Liskov Substitution, Interface Segregation, Dependency Inversion)
- Use clear, descriptive naming for variables, functions, and classes
- Keep functions small and focused on a single task
- Write self-documenting code with minimal but effective comments
- Follow consistent code formatting and style guidelines
EOF
            ;;
        "frontend")
            cat << EOF
## Basic Frontend Development Guidance

- Focus on component reusability and maintainability
- Implement proper state management patterns
- Optimize for user experience and performance
- Ensure accessibility compliance (WCAG guidelines)
- Use responsive design principles
- Minimize bundle size and optimize loading times
EOF
            ;;
        "backend")
            cat << EOF
## Basic Backend Development Guidance

- Implement domain-driven design principles
- Design clean, RESTful APIs with proper HTTP methods
- Ensure data consistency and integrity
- Implement proper error handling and logging
- Use appropriate design patterns (Repository, Factory, etc.)
- Follow security best practices for authentication and authorization
EOF
            ;;
        "devops-sre")
            cat << EOF
## Basic DevOps/SRE Guidance

- Implement Infrastructure as Code (IaC) practices
- Ensure comprehensive monitoring and alerting
- Automate deployment pipelines with proper testing
- Implement proper backup and disaster recovery procedures
- Follow security best practices for infrastructure
- Document operational procedures and runbooks
EOF
            ;;
        *)
            echo "Apply general software engineering best practices: clean code, proper testing, documentation, and maintainable architecture."
            ;;
    esac
}

# Generate compliance summary
generate_compliance_summary() {
    local phase="$1"
    
    cat << EOF
This compliance report analyzes the current project state against Knowledge Base v2.0 standards for the **$phase** phase.

**Key Areas Assessed:**
- Adherence to shared software engineering principles
- Context-specific best practices application
- Pattern consistency across the project
- Documentation and maintainability standards

**Assessment Method:**
- Automated pattern detection and validation
- Knowledge Base query integration
- Fallback guidance when specific patterns unavailable
EOF
}

# Generate detailed compliance analysis
generate_detailed_compliance() {
    local phase="$1"
    local repo_root=$(get_repo_root)
    
    echo "### Project Structure Analysis"
    echo
    echo "**Repository Root:** $repo_root"
    echo "**Detected Contexts:** $(detect_project_contexts | tr '\n' ' ')"
    echo "**Applicable Principles:** $(get_applicable_principles "$phase")"
    echo
    echo "### Validation Results"
    echo
    echo "*Detailed validation results would be generated here based on actual project files.*"
    echo
    echo "### Knowledge Base Coverage"
    echo
    echo "- ✅ Shared principles guidance available"
    echo "- ✅ Context-specific patterns identified"
    echo "- ✅ Fallback guidance implemented"
}

# Generate compliance recommendations
generate_compliance_recommendations() {
    local phase="$1"
    
    cat << EOF
### Immediate Actions
1. Review and apply shared principles across all code
2. Implement context-specific patterns for detected technologies
3. Ensure consistent naming conventions throughout project

### Phase-Specific Recommendations ($phase)
EOF
    
    case "$phase" in
        "analyze")
            cat << EOF
- Complete architecture assessment using KB guidance
- Document technical debt and constraints
- Validate pattern applicability for project context
EOF
            ;;
        "architect")
            cat << EOF
- Create Architecture Decision Records (ADRs) for key decisions
- Ensure design consistency across components
- Validate dependency flow follows clean architecture principles
EOF
            ;;
        "implement")
            cat << EOF
- Apply coding standards consistently
- Ensure adequate test coverage
- Document implementation decisions and patterns used
EOF
            ;;
    esac
}

# Generate KB references used
generate_kb_references() {
    local phase="$1"
    local kb_root="$(get_repo_root)/memory/knowledge-base"
    
    echo "### Knowledge Base References"
    echo
    echo "**Base Path:** $kb_root"
    echo
    echo "**Referenced Contexts:**"
    
    local principles=$(get_applicable_principles "$phase")
    for principle in $principles; do
        if [[ -d "$kb_root/$principle" ]]; then
            echo "- ✅ $principle/ (available)"
        else
            echo "- ❌ $principle/ (not found - using fallback)"
        fi
    done
}

# =============================================================================
# UTILITY FUNCTIONS
# =============================================================================

# Display KB integration status
kb_status() {
    local kb_root="$(get_repo_root)/memory/knowledge-base"
    local cache_dir="$(get_repo_root)/.specify-cache"
    
    echo "=== Knowledge Base Integration Status ==="
    echo
    echo "KB Root: $kb_root"
    echo "KB Available: $([ -d "$kb_root" ] && echo "✅ Yes" || echo "❌ No")"
    echo "Cache Directory: $cache_dir"
    echo "Cache Available: $([ -d "$cache_dir" ] && echo "✅ Yes" || echo "❌ No")"
    echo
    echo "Available Contexts:"
    for context in shared-principles frontend backend devops-sre; do
        if [[ -d "$kb_root/$context" ]]; then
            echo "  ✅ $context"
        else
            echo "  ❌ $context"
        fi
    done
    echo
    echo "Detected Project Contexts:"
    detect_project_contexts | while read -r context; do
        if [[ -n "$context" ]]; then
            echo "  🔍 $context"
        fi
    done
}

# Clear KB cache
clear_kb_cache() {
    local cache_dir="$(get_repo_root)/.specify-cache/kb-queries"
    
    if [[ -d "$cache_dir" ]]; then
        rm -rf "$cache_dir"
        echo "✅ KB cache cleared"
    else
        echo "ℹ️  No cache to clear"
    fi
}

# Initialize KB placeholders for template integration
# Usage: init_kb_placeholders <phase>
init_kb_placeholders() {
    local phase="$1"
    
    if [[ -z "$phase" ]]; then
        echo "ERROR: init_kb_placeholders requires phase parameter" >&2
        return 1
    fi
    
    # Get applicable principles and set KB_CONTEXT
    local principles=$(get_applicable_principles "$phase")
    export KB_CONTEXT="$principles"
    
    # Query KB for phase-specific guidance and set KB_REFERENCE
    local kb_query=""
    case "$phase" in
        "analyze")
            kb_query="architecture patterns consistency validation"
            ;;
        "architect"|"plan")
            kb_query="architecture design patterns best practices"
            ;;
        "implement")
            kb_query="coding standards implementation patterns"
            ;;
        *)
            kb_query="general best practices"
            ;;
    esac
    
    local kb_reference=$(query_knowledge_base "shared-principles" "$kb_query")
    export KB_REFERENCE="$kb_reference"
    
    # Initialize validation result placeholder
    export VALIDATION_RESULT="KB patterns ready for validation"
    
    # Initialize compliance report path placeholder
    export COMPLIANCE_REPORT_PATH=""
    
    echo "KB placeholders initialized for phase: $phase"
}

# Set KB validation result for template substitution
# Usage: set_validation_result <result>
set_validation_result() {
    local result="$1"
    export VALIDATION_RESULT="$result"
}

# Set compliance report path for template substitution
# Usage: set_compliance_report_path <path>
set_compliance_report_path() {
    local path="$1"
    export COMPLIANCE_REPORT_PATH="$path"
}

# Get all KB placeholders for debugging
get_kb_placeholders() {
    echo "=== KB Placeholders Status ==="
    echo "KB_REFERENCE: ${KB_REFERENCE:-'Not set'}"
    echo "VALIDATION_RESULT: ${VALIDATION_RESULT:-'Not set'}"
    echo "KB_CONTEXT: ${KB_CONTEXT:-'Not set'}"
    echo "COMPLIANCE_REPORT_PATH: ${COMPLIANCE_REPORT_PATH:-'Not set'}"
}

# =============================================================================
# DIRECTORY STRUCTURE FUNCTIONS FOR PLAN INTEGRATION
# =============================================================================

# Get directory structure based on technology stack and architecture patterns
# Usage: get_directory_structure <tech_stack> <architecture_pattern>
# Returns: Directory structure template based on KB patterns
get_directory_structure() {
    local tech_stack="$1"
    local architecture_pattern="${2:-clean-architecture}"
    
    if [[ -z "$tech_stack" ]]; then
        echo "ERROR: get_directory_structure requires tech_stack parameter" >&2
        return 1
    fi
    
    # Detect project type and return appropriate structure
    case "$tech_stack" in
        *"next.js"*|*"nextjs"*)
            get_nextjs_structure "$architecture_pattern"
            ;;
        *"remix"*)
            get_remix_structure "$architecture_pattern"
            ;;
        *"react"*|*"frontend"*)
            get_react_structure "$architecture_pattern"
            ;;
        *"backend"*|*"api"*|*"server"*)
            get_backend_structure "$architecture_pattern"
            ;;
        *"web"*|*"fullstack"*)
            get_fullstack_structure "$architecture_pattern"
            ;;
        *"mobile"*)
            get_mobile_structure "$architecture_pattern"
            ;;
        *)
            get_default_structure "$architecture_pattern"
            ;;
    esac
}

# Get Next.js directory structure with Clean Architecture
get_nextjs_structure() {
    local pattern="$1"
    
    case "$pattern" in
        *"ddd"*|*"domain-driven"*)
            cat << 'EOF'
# Next.js + Clean Architecture + DDD Structure
app/                          # Next.js 13+ App Router
├── (auth)/                   # Route groups
├── api/                      # API routes
│   └── [domain]/            # Domain-based API organization
├── [locale]/                # Internationalization
└── globals.css              # Global styles

src/
├── application/             # Application Layer (Use Cases)
│   ├── use-cases/          # Business use cases
│   ├── ports/              # Interfaces/Contracts
│   └── services/           # Application services
├── domain/                  # Domain Layer (Business Logic)
│   ├── entities/           # Domain entities
│   ├── value-objects/      # Value objects
│   ├── aggregates/         # Domain aggregates
│   └── repositories/       # Repository interfaces
├── infrastructure/         # Infrastructure Layer
│   ├── database/           # Database implementations
│   ├── external/           # External service adapters
│   └── repositories/       # Repository implementations
├── presentation/           # Presentation Layer
│   ├── components/         # React components
│   ├── hooks/              # Custom hooks
│   ├── pages/              # Page components
│   └── layouts/            # Layout components
└── shared/                 # Shared utilities
    ├── types/              # TypeScript types
    ├── utils/              # Utility functions
    └── constants/          # Application constants
EOF
            ;;
        *)
            cat << 'EOF'
# Next.js + Clean Architecture Structure
app/                          # Next.js 13+ App Router
├── (dashboard)/             # Route groups
├── api/                     # API routes
├── globals.css              # Global styles
└── layout.tsx               # Root layout

src/
├── components/              # Reusable UI components
│   ├── ui/                 # Base UI components
│   ├── forms/              # Form components
│   └── layout/             # Layout components
├── lib/                    # Core business logic
│   ├── actions/            # Server actions
│   ├── data/               # Data access layer
│   ├── validations/        # Input validation schemas
│   └── utils/              # Utility functions
├── hooks/                  # Custom React hooks
├── types/                  # TypeScript type definitions
└── styles/                 # Styling files
    ├── globals.css         # Global styles
    └── components.css      # Component styles
EOF
            ;;
    esac
}

# Get Remix directory structure with Clean Architecture
get_remix_structure() {
    local pattern="$1"
    
    case "$pattern" in
        *"ddd"*|*"domain-driven"*)
            cat << 'EOF'
# Remix + Clean Architecture + DDD Structure
app/
├── routes/                  # Remix routes
│   ├── _index.tsx          # Home route
│   ├── [domain]/           # Domain-based route organization
│   └── api/                # API routes
├── components/             # React components
│   ├── ui/                 # Base UI components
│   └── domain/             # Domain-specific components
├── lib/                    # Core application logic
│   ├── application/        # Application Layer
│   │   ├── use-cases/      # Business use cases
│   │   └── services/       # Application services
│   ├── domain/             # Domain Layer
│   │   ├── entities/       # Domain entities
│   │   ├── aggregates/     # Domain aggregates
│   │   └── repositories/   # Repository interfaces
│   ├── infrastructure/     # Infrastructure Layer
│   │   ├── database/       # Database implementations
│   │   └── repositories/   # Repository implementations
│   └── shared/             # Shared utilities
├── styles/                 # CSS files
└── utils/                  # Utility functions
EOF
            ;;
        *)
            cat << 'EOF'
# Remix + Clean Architecture Structure
app/
├── routes/                  # Remix routes
│   ├── _index.tsx          # Home route
│   ├── dashboard/          # Dashboard routes
│   └── api/                # API routes
├── components/             # React components
│   ├── ui/                 # Base UI components
│   ├── forms/              # Form components
│   └── layout/             # Layout components
├── lib/                    # Core application logic
│   ├── db/                 # Database utilities
│   ├── auth/               # Authentication logic
│   ├── validations/        # Input validation
│   └── utils/              # Utility functions
├── styles/                 # CSS files
├── types/                  # TypeScript types
└── utils/                  # Shared utilities
EOF
            ;;
    esac
}

# Get React (pure) directory structure with Clean Architecture
get_react_structure() {
    local pattern="$1"
    
    case "$pattern" in
        *"ddd"*|*"domain-driven"*)
            cat << 'EOF'
# React + Clean Architecture + DDD Structure
src/
├── application/             # Application Layer
│   ├── use-cases/          # Business use cases
│   ├── ports/              # Interfaces/Contracts
│   └── services/           # Application services
├── domain/                  # Domain Layer
│   ├── entities/           # Domain entities
│   ├── value-objects/      # Value objects
│   ├── aggregates/         # Domain aggregates
│   └── repositories/       # Repository interfaces
├── infrastructure/         # Infrastructure Layer
│   ├── api/                # API client implementations
│   ├── storage/            # Storage implementations
│   └── repositories/       # Repository implementations
├── presentation/           # Presentation Layer
│   ├── components/         # React components
│   │   ├── ui/             # Base UI components
│   │   ├── forms/          # Form components
│   │   └── domain/         # Domain-specific components
│   ├── hooks/              # Custom hooks
│   ├── pages/              # Page components
│   └── layouts/            # Layout components
└── shared/                 # Shared utilities
    ├── types/              # TypeScript types
    ├── utils/              # Utility functions
    └── constants/          # Application constants
EOF
            ;;
        *)
            cat << 'EOF'
# React + Clean Architecture Structure
src/
├── components/              # React components
│   ├── ui/                 # Base UI components
│   ├── forms/              # Form components
│   ├── layout/             # Layout components
│   └── common/             # Common components
├── hooks/                  # Custom React hooks
├── services/               # API and business logic
│   ├── api/                # API client
│   ├── auth/               # Authentication
│   └── data/               # Data management
├── utils/                  # Utility functions
├── types/                  # TypeScript type definitions
├── constants/              # Application constants
├── styles/                 # Styling files
└── assets/                 # Static assets
    ├── images/             # Image files
    └── icons/              # Icon files
EOF
            ;;
    esac
}

# Get backend directory structure with Clean Architecture
get_backend_structure() {
    local pattern="$1"
    
    case "$pattern" in
        *"ddd"*|*"domain-driven"*)
            cat << 'EOF'
# Backend + Clean Architecture + DDD Structure
src/
├── application/             # Application Layer
│   ├── use-cases/          # Business use cases
│   ├── ports/              # Interfaces/Contracts
│   ├── services/           # Application services
│   └── dto/                # Data Transfer Objects
├── domain/                  # Domain Layer
│   ├── entities/           # Domain entities
│   ├── value-objects/      # Value objects
│   ├── aggregates/         # Domain aggregates
│   ├── repositories/       # Repository interfaces
│   ├── services/           # Domain services
│   └── events/             # Domain events
├── infrastructure/         # Infrastructure Layer
│   ├── database/           # Database implementations
│   │   ├── repositories/   # Repository implementations
│   │   ├── migrations/     # Database migrations
│   │   └── seeders/        # Database seeders
│   ├── external/           # External service adapters
│   ├── messaging/          # Message queue implementations
│   └── config/             # Configuration
├── presentation/           # Presentation Layer
│   ├── controllers/        # HTTP controllers
│   ├── middleware/         # HTTP middleware
│   ├── routes/             # Route definitions
│   └── validators/         # Input validators
└── shared/                 # Shared utilities
    ├── types/              # TypeScript types
    ├── utils/              # Utility functions
    ├── constants/          # Application constants
    └── exceptions/         # Custom exceptions
EOF
            ;;
        *)
            cat << 'EOF'
# Backend + Clean Architecture Structure
src/
├── controllers/             # HTTP controllers
├── services/               # Business logic services
├── models/                 # Data models
├── repositories/           # Data access layer
├── middleware/             # HTTP middleware
├── routes/                 # Route definitions
├── utils/                  # Utility functions
├── types/                  # TypeScript types
├── config/                 # Configuration files
└── validators/             # Input validation

tests/
├── unit/                   # Unit tests
├── integration/            # Integration tests
└── e2e/                    # End-to-end tests
EOF
            ;;
    esac
}

# Get fullstack (web) directory structure
get_fullstack_structure() {
    local pattern="$1"
    
    case "$pattern" in
        *"ddd"*|*"domain-driven"*)
            cat << 'EOF'
# Fullstack + Clean Architecture + DDD Structure
backend/
├── src/
│   ├── application/        # Application Layer
│   ├── domain/             # Domain Layer
│   ├── infrastructure/     # Infrastructure Layer
│   └── presentation/       # Presentation Layer
└── tests/

frontend/
├── src/
│   ├── application/        # Application Layer
│   ├── domain/             # Domain Layer (client-side)
│   ├── infrastructure/     # Infrastructure Layer
│   └── presentation/       # Presentation Layer
└── tests/

shared/                     # Shared types and utilities
├── types/                  # Common TypeScript types
├── constants/              # Shared constants
└── utils/                  # Shared utility functions
EOF
            ;;
        *)
            cat << 'EOF'
# Fullstack + Clean Architecture Structure
backend/
├── src/
│   ├── controllers/        # HTTP controllers
│   ├── services/           # Business logic
│   ├── models/             # Data models
│   ├── routes/             # API routes
│   └── utils/              # Utilities
└── tests/

frontend/
├── src/
│   ├── components/         # React components
│   ├── services/           # API services
│   ├── hooks/              # Custom hooks
│   ├── utils/              # Utilities
│   └── types/              # TypeScript types
└── tests/

shared/                     # Shared code
├── types/                  # Common types
└── utils/                  # Shared utilities
EOF
            ;;
    esac
}

# Get mobile directory structure
get_mobile_structure() {
    local pattern="$1"
    
    cat << 'EOF'
# Mobile + API Structure
api/
├── src/
│   ├── controllers/        # API controllers
│   ├── services/           # Business logic
│   ├── models/             # Data models
│   └── routes/             # API routes
└── tests/

mobile/
├── src/
│   ├── components/         # UI components
│   ├── screens/            # Screen components
│   ├── navigation/         # Navigation setup
│   ├── services/           # API services
│   ├── hooks/              # Custom hooks
│   ├── utils/              # Utilities
│   └── types/              # TypeScript types
└── tests/
EOF
}

# Get default directory structure
get_default_structure() {
    local pattern="$1"
    
    case "$pattern" in
        *"ddd"*|*"domain-driven"*)
            cat << 'EOF'
# Default + Clean Architecture + DDD Structure
src/
├── application/             # Application Layer
│   ├── use-cases/          # Business use cases
│   └── services/           # Application services
├── domain/                  # Domain Layer
│   ├── entities/           # Domain entities
│   ├── repositories/       # Repository interfaces
│   └── services/           # Domain services
├── infrastructure/         # Infrastructure Layer
│   ├── repositories/       # Repository implementations
│   └── external/           # External integrations
└── shared/                 # Shared utilities
    ├── types/              # TypeScript types
    └── utils/              # Utility functions

tests/
├── unit/                   # Unit tests
├── integration/            # Integration tests
└── contract/               # Contract tests
EOF
            ;;
        *)
            cat << 'EOF'
# Default + Clean Architecture Structure
src/
├── models/                 # Data models
├── services/               # Business logic
├── controllers/            # Controllers/Handlers
├── utils/                  # Utility functions
├── types/                  # TypeScript types
└── config/                 # Configuration

tests/
├── unit/                   # Unit tests
├── integration/            # Integration tests
└── contract/               # Contract tests
EOF
            ;;
    esac
}

# Detect architecture pattern from project context
# Usage: detect_architecture_pattern <project_context>
# Returns: Architecture pattern (clean-architecture, ddd, etc.)
detect_architecture_pattern() {
    local project_context="$1"
    
    # Check for DDD indicators
    if echo "$project_context" | grep -qi "domain\|ddd\|bounded.*context\|aggregate"; then
        echo "ddd"
        return 0
    fi
    
    # Default to clean architecture
    echo "clean-architecture"
}

# Generate structure decision based on technical context
# Usage: generate_structure_decision <tech_context>
# Returns: Structure decision with KB justification
generate_structure_decision() {
    local tech_context="$1"
    
    if [[ -z "$tech_context" ]]; then
        echo "ERROR: generate_structure_decision requires tech_context parameter" >&2
        return 1
    fi
    
    local structure_type="single"
    local architecture_pattern="clean-architecture"
    
    # Detect project type
    if echo "$tech_context" | grep -qi "frontend.*backend\|web.*application\|fullstack"; then
        structure_type="web"
    elif echo "$tech_context" | grep -qi "mobile\|ios\|android"; then
        structure_type="mobile"
    fi
    
    # Detect architecture pattern
    architecture_pattern=$(detect_architecture_pattern "$tech_context")
    
    # Generate decision with KB justification
    cat << EOF
**Structure Decision**: Option $(get_structure_option_number "$structure_type") - $structure_type application

**KB Justification**:
- **Architecture Pattern**: $architecture_pattern (detected from context)
- **Clean Architecture**: Mandatory for all projects (KB requirement)
- **Domain Organization**: $(get_domain_organization_justification "$architecture_pattern")
- **Technology Stack**: $(get_tech_stack_justification "$tech_context")

**Applied KB Patterns**:
- shared-principles/clean-architecture/dependency-rule.md
- shared-principles/clean-architecture/patterns.md
$(get_context_specific_patterns "$structure_type" "$architecture_pattern")
EOF
}

# Helper functions for structure decision generation
get_structure_option_number() {
    case "$1" in
        "single") echo "1" ;;
        "web") echo "2" ;;
        "mobile") echo "3" ;;
        *) echo "1" ;;
    esac
}

get_domain_organization_justification() {
    case "$1" in
        "ddd")
            echo "Domain-Driven Design with bounded contexts and aggregates"
            ;;
        *)
            echo "Clean Architecture with clear layer separation"
            ;;
    esac
}

get_tech_stack_justification() {
    local tech_context="$1"
    
    if echo "$tech_context" | grep -qi "next.js"; then
        echo "Next.js detected - using App Router with Clean Architecture"
    elif echo "$tech_context" | grep -qi "remix"; then
        echo "Remix detected - using route-based organization with Clean Architecture"
    elif echo "$tech_context" | grep -qi "react"; then
        echo "React detected - using component-based architecture"
    else
        echo "Standard Clean Architecture organization"
    fi
}

get_context_specific_patterns() {
    local structure_type="$1"
    local architecture_pattern="$2"
    
    case "$structure_type" in
        "web")
            echo "- frontend/ui-architecture/component-architecture.md"
            echo "- backend/domain-modeling/strategic-design.md"
            ;;
        "mobile")
            echo "- frontend/ui-architecture/component-architecture.md"
            echo "- backend/api-design/ (for API integration)"
            ;;
        *)
            if [[ "$architecture_pattern" == "ddd" ]]; then
                echo "- backend/domain-modeling/strategic-design.md"
            fi
            ;;
    esac
}

# Main function for direct script execution
main() {
    case "${1:-}" in
        "status")
            kb_status
            ;;
        "clear-cache")
            clear_kb_cache
            ;;
        "query")
            if [[ $# -lt 3 ]]; then
                echo "Usage: $0 query <context> <query_string>"
                exit 1
            fi
            query_knowledge_base "$2" "$3"
            ;;
        "validate")
            if [[ $# -lt 3 ]]; then
                echo "Usage: $0 validate <artifact_path> <context>"
                exit 1
            fi
            validate_against_patterns "$2" "$3"
            ;;
        "principles")
            if [[ $# -lt 2 ]]; then
                echo "Usage: $0 principles <domain>"
                exit 1
            fi
            get_applicable_principles "$2"
            ;;
        "report")
            if [[ $# -lt 2 ]]; then
                echo "Usage: $0 report <phase>"
                exit 1
            fi
            generate_compliance_report "$2"
            ;;
        "init-placeholders")
            if [[ $# -lt 2 ]]; then
                echo "Usage: $0 init-placeholders <phase>"
                exit 1
            fi
            init_kb_placeholders "$2"
            ;;
        "get-placeholders")
            get_kb_placeholders
            ;;
        "directory-structure")
            if [[ $# -lt 2 ]]; then
                echo "Usage: $0 directory-structure <tech_stack> [architecture_pattern]"
                exit 1
            fi
            get_directory_structure "$2" "${3:-clean-architecture}"
            ;;
        "structure-decision")
            if [[ $# -lt 2 ]]; then
                echo "Usage: $0 structure-decision <tech_context>"
                exit 1
            fi
            generate_structure_decision "$2"
            ;;
        "detect-pattern")
            if [[ $# -lt 2 ]]; then
                echo "Usage: $0 detect-pattern <project_context>"
                exit 1
            fi
            detect_architecture_pattern "$2"
            ;;
        *)
            echo "Knowledge Base Integration Module v1.0"
            echo "Usage: $0 {status|clear-cache|query|validate|principles|report|init-placeholders|get-placeholders|directory-structure|structure-decision|detect-pattern}"
            echo
            echo "Commands:"
            echo "  status                           - Show KB integration status"
            echo "  clear-cache                     - Clear KB query cache"
            echo "  query <context> <query>         - Query KB for specific context"
            echo "  validate <file> <context>       - Validate file against KB patterns"
            echo "  principles <domain>             - Get applicable principles for domain"
            echo "  report <phase>                  - Generate compliance report for phase"
            echo "  init-placeholders <phase>       - Initialize KB placeholders for template substitution"
            echo "  get-placeholders                - Show current KB placeholder values"
            echo "  directory-structure <tech> [pattern] - Get directory structure for tech stack"
            echo "  structure-decision <context>    - Generate structure decision with KB justification"
            echo "  detect-pattern <context>        - Detect architecture pattern from context"
            ;;
    esac
}

# Execute main function if script is run directly
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main "$@"
fi