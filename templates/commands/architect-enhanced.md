---
description: Execute architectural design with Knowledge-Base integration, Rich Artifacts generation, and Checkpoint validation
scripts:
  sh: scripts/bash/check-prerequisites.sh --json --require-plan
  ps: scripts/powershell/check-prerequisites.ps1 -Json -RequirePlan
---

The user input can be provided directly by the agent or as a command argument - you **MUST** consider it before proceeding with the prompt (if not empty).

User input:

$ARGUMENTS

## Artifact Generation Setup (MANDATORY)

**CRITICAL**: Before proceeding with architecture, MUST initialize artifact generation system:

1. **Source Artifact Generation Module**:

   ```bash
   source scripts/bash/artifact-generation.sh
   ```

2. **Initialize Architecture Artifacts**:

   ```bash
   ARTIFACT_CONTEXT="${ARGUMENTS:-architect}"
   ARTIFACT_PHASE="architect"
   ```

3. **Prepare Architecture Artifacts**:

   ```bash
   # Generate architecture artifacts automatically
   echo "Generating architecture artifacts..."
   generate_phase_artifacts "$ARTIFACT_PHASE" "$ARTIFACT_CONTEXT"
   ```

## Knowledge Base Integration for Architecture (MANDATORY)

**CRITICAL**: Before proceeding with architectural design, MUST execute KB integration for architectural validation:

1. **Source KB Integration Module**:

   ```bash
   source scripts/bash/knowledge-base-integration.sh
   ```

2. **Query KB for Architecture Context**:

   ```bash
   KB_CONTEXT=$(get_applicable_principles "architect")
   KB_REFERENCE=$(query_knowledge_base "shared-principles" "architecture patterns design consistency")
   ```

3. **Prepare Architectural Validation**:

   ```bash
   # Will be used during architecture design to validate decisions
   VALIDATION_RESULT="KB patterns ready for architectural validation"
   ```

4. **Fallback Handling**: If KB unavailable, continue with built-in architectural patterns but note limitation in final report.

## Architecture Execution Steps

1. **KB Integration Setup** (MANDATORY):
   Execute KB integration steps above. Store results in variables:

   - `{KB_REFERENCE}` - Architectural patterns and design guidance from KB
   - `{VALIDATION_RESULT}` - Pattern validation status
   - `{KB_CONTEXT}` - Applicable principles for architecture phase

2. Run `{SCRIPT}` from repo root and parse FEATURE_DIR and AVAILABLE_DOCS list. All paths must be absolute.

3. **Load and analyze the architectural context with KB integration**:

   - **REQUIRED**: Read plan.md for tech stack, architecture decisions, and constraints
   - **REQUIRED**: Read spec.md for functional and non-functional requirements
   - **IF EXISTS**: Read data-model.md for entities and relationships
   - **IF EXISTS**: Read contracts/ for API specifications
   - **IF EXISTS**: Read research.md for technical decisions and rationale
   - **IF EXISTS**: Read tasks.md for implementation scope
   - **KB ENHANCEMENT**: Cross-reference all artifacts against `{KB_REFERENCE}` architectural patterns

4. **Architectural design process with KB pattern validation**:

   - **Requirements Analysis**: Extract architectural requirements from spec and plan
   - **Pattern Selection**: Choose appropriate patterns based on KB guidance
   - **Component Design**: Define system components with KB validation
   - **Integration Design**: Plan component interactions following KB patterns
   - **Quality Attributes**: Address performance, security, scalability per KB standards
   - **KB Pattern Mapping**: Map each architectural decision to applicable KB patterns

5. **Architecture documentation with KB compliance**:

   - **System Design Document**: Comprehensive architectural documentation
   - **Architecture Decision Records (ADRs)**: Document key decisions with KB references
   - **Component Interaction Diagrams**: Visual representation of system architecture
   - **Validation Reports**: KB compliance and pattern validation results
   - **KB Pattern Application**: Document how KB patterns were applied

6. **Enhanced validation and quality assurance**:

   - **Pattern Consistency**: Validate architectural patterns against KB standards
   - **Dependency Analysis**: Ensure clean dependency flow per KB principles
   - **Integration Validation**: Verify component interactions follow KB patterns
   - **Quality Metrics**: Assess design quality against KB benchmarks
   - **KB Compliance Validation**: Generate compliance report using `generate_compliance_report "architect"`

## Quality Gate and Checkpoint Integration (MANDATORY)

**CRITICAL**: After completing architecture, MUST execute quality gate validation and checkpoint creation:

1. **Execute Quality Gate Validation**:

   ```bash
   source scripts/bash/checkpoint-system.sh
   QUALITY_GATE_RESULT=$(validate_quality_gate "architect")
   QUALITY_GATE_STATUS=$(extract_quality_gate_status "$QUALITY_GATE_RESULT")
   ```

2. **Create Checkpoint on Success**:

   ```bash
   if [[ "$QUALITY_GATE_STATUS" = "PASS" ]]; then
     CHECKPOINT_RESULT=$(create_checkpoint "architect_complete" "architect" "Architecture phase completed successfully")
     echo "✅ Architecture checkpoint created successfully"
   else
     echo "❌ Quality gate failed - architecture requires remediation before proceeding"
     echo "Quality Gate Details: $QUALITY_GATE_RESULT"
     echo "🔄 Available rollback options:"
     list_checkpoints "analyze"
   fi
   ```

## KB Integration Compliance Report

At completion, generate and display:

### Architecture Compliance Summary

- **Total Architectural Decisions**: [count]
- **KB Patterns Applied**: [list]
- **Compliance Status**: ✅ PASS / ❌ FAIL / ⚠️ PARTIAL
- **Pattern Violations**: [count and severity]
- **Remediation Required**: [yes/no with details]

### Architecture Artifacts Generated

- **System Design Document**: `artifacts/architect/system_design_document.md`
- **Architecture Decision Record**: `artifacts/architect/architecture_decision_record.md`
- **Component Interaction Diagram**: `artifacts/architect/component_interaction_diagram.mmd`
- **Validation Report**: `artifacts/architect/validation_report.md`

### KB Pattern Application Results

| Decision              | KB Pattern      | Status     | Issues                | Remediation             |
| --------------------- | --------------- | ---------- | --------------------- | ----------------------- |
| API Design            | api-design      | ✅ PASS    | None                  | N/A                     |
| Database Architecture | domain-modeling | ⚠️ PARTIAL | Missing entity bounds | Define clear boundaries |

### Quality Gate and Checkpoint Status

- **Quality Gate Status**: ✅ PASS / ❌ FAIL / ⚠️ PARTIAL
- **Checkpoint Created**: [checkpoint_id] / N/A (if failed)
- **Snapshot Path**: [snapshot_path] / N/A (if failed)
- **Next Phase Approved**: ✅ YES / ❌ NO

### Architecture Quality Metrics

| Metric                | Target | Actual  | Status   |
| --------------------- | ------ | ------- | -------- |
| Design Consistency    | > 90%  | [value] | ✅/⚠️/❌ |
| Pattern Compliance    | 100%   | [value] | ✅/⚠️/❌ |
| KB Reference Coverage | > 80%  | [value] | ✅/⚠️/❌ |
| ADR Completeness      | 100%   | [value] | ✅/⚠️/❌ |

### Final Recommendations

- **Immediate Actions**: [critical architectural issues to resolve]
- **Future Improvements**: [enhancement opportunities]
- **KB References**: [links to relevant KB sections]
- **Artifact Access**: All architecture artifacts available in `artifacts/architect/` directory
- **Traceability**: Complete architectural history available in `.specify-cache/traceability/artifacts.json`

---

**Note**: This command assumes complete planning artifacts exist (plan.md, spec.md). If planning is incomplete, suggest running `/plan` first.

**KB Integration**: This enhanced architecture command integrates Knowledge Base v1.0 patterns and validation throughout the architectural design process, ensuring design quality and consistency with established best practices.

**Artifact Generation**: This command now includes automatic generation of rich architectural artifacts (system design documents, ADRs, component diagrams, and validation reports) with full KB integration and traceability. All artifacts are automatically generated during the architecture process and stored in the `artifacts/architect/` directory with complete version control and compliance tracking.

**System Integration**: The architecture process now seamlessly integrates with the SDD v2.0 systems (Knowledge-Base, Artifacts, and Checkpoints), providing comprehensive documentation, validation, and rollback capabilities while maintaining full compatibility with existing workflows.
