---
description: Execute the implementation plan by processing and executing all tasks defined in tasks.md
scripts:
  sh: scripts/bash/check-prerequisites.sh --json --require-tasks --include-tasks
  ps: scripts/powershell/check-prerequisites.ps1 -Json -RequireTasks -IncludeTasks
---

The user input can be provided directly by the agent or as a command argument - you **MUST** consider it before proceeding with the prompt (if not empty).

User input:

$ARGUMENTS

## Artifact Generation Setup (MANDATORY)

**CRITICAL**: Before proceeding with implementation, MUST initialize artifact generation system:

1. **Source Artifact Generation Module**:

   ```bash
   source scripts/bash/artifact-generation.sh
   ```

2. **Initialize Artifact Generation Context**:

   ```bash
   ARTIFACT_CONTEXT="${ARGUMENTS:-implement}"
   ARTIFACT_PHASE="implement"
   ```

3. **Prepare Implementation Artifacts**:

   ```bash
   # Generate implementation artifacts automatically
   echo "Generating implementation artifacts..."
   generate_phase_artifacts "$ARTIFACT_PHASE" "$ARTIFACT_CONTEXT"
   ```

## Knowledge Base Integration for Implementation (MANDATORY)

**CRITICAL**: Before proceeding with implementation, MUST execute KB integration for coding standards validation:

1. **Source KB Integration Module**:

   ```bash
   source scripts/bash/knowledge-base-integration.sh
   ```

2. **Query KB for Implementation Context**:

   ```bash
   KB_CONTEXT=$(get_applicable_principles "implement")
   KB_REFERENCE=$(query_knowledge_base "shared-principles" "coding standards implementation patterns")
   ```

3. **Prepare Pattern Validation**:

   ```bash
   # Will be used during implementation to validate each created file
   VALIDATION_RESULT="KB patterns ready for implementation validation"
   ```

4. **Fallback Handling**: If KB unavailable, continue with built-in coding standards but note limitation in final report.

## Implementation Execution Steps

1. **KB Integration Setup** (MANDATORY):
   Execute KB integration steps above. Store results in variables:

   - `{KB_REFERENCE}` - Coding standards and implementation patterns from KB
   - `{VALIDATION_RESULT}` - Pattern validation status
   - `{KB_CONTEXT}` - Applicable principles for implementation phase

2. Run `{SCRIPT}` from repo root and parse FEATURE_DIR and AVAILABLE_DOCS list. All paths must be absolute.

3. **Load and analyze the implementation context with KB integration**:

   - **REQUIRED**: Read tasks.md for the complete task list and execution plan
   - **REQUIRED**: Read plan.md for tech stack, architecture, and file structure
   - **IF EXISTS**: Read data-model.md for entities and relationships
   - **IF EXISTS**: Read contracts/ for API specifications and test requirements
   - **IF EXISTS**: Read research.md for technical decisions and constraints
   - **IF EXISTS**: Read quickstart.md for integration scenarios
   - **KB ENHANCEMENT**: Cross-reference all artifacts against `{KB_REFERENCE}` implementation patterns

4. **Parse tasks.md structure with KB pattern mapping**:

   - **Task phases**: Setup, Tests, Core, Integration, Polish
   - **Task dependencies**: Sequential vs parallel execution rules
   - **Task details**: ID, description, file paths, parallel markers [P]
   - **Execution flow**: Order and dependency requirements
   - **KB Pattern Mapping**: Map each task to applicable KB coding standards

5. **Execute implementation following the task plan with KB validation and artifact generation**:

   - **Phase-by-phase execution**: Complete each phase before moving to the next
   - **Respect dependencies**: Run sequential tasks in order, parallel tasks [P] can run together
   - **Follow TDD approach**: Execute test tasks before their corresponding implementation tasks
   - **File-based coordination**: Tasks affecting the same files must run sequentially
   - **KB Pattern Validation**: Validate each created/modified file against KB standards
   - **Artifact Generation**: Generate implementation artifacts after each major milestone
   - **Validation checkpoints**: Verify each phase completion AND KB compliance before proceeding

6. **Implementation execution rules with KB compliance and artifact generation**:

   - **Setup first**: Initialize project structure, dependencies, configuration
     - Apply KB infrastructure patterns
     - Validate setup against KB best practices
     - Generate setup artifacts: `generate_artifact "code_quality_report" "implement" "$ARTIFACT_CONTEXT"`
   - **Tests before code**: Write tests for contracts, entities, and integration scenarios
     - Follow KB testing patterns and standards
     - Ensure test quality meets KB guidelines
     - Generate test artifacts: `generate_artifact "test_coverage_report" "implement" "$ARTIFACT_CONTEXT"`
   - **Core development**: Implement models, services, CLI commands, endpoints
     - Apply KB coding standards (naming, structure, patterns)
     - Validate each file against KB principles during creation
     - Generate performance artifacts: `generate_artifact "performance_benchmarks" "implement" "$ARTIFACT_CONTEXT"`
   - **Integration work**: Database connections, middleware, logging, external services
     - Follow KB integration patterns
     - Apply KB security and performance standards
   - **Polish and validation**: Unit tests, performance optimization, documentation
     - Ensure KB documentation standards
     - Validate final implementation against all KB patterns
     - Generate API documentation: `generate_artifact "api_documentation" "implement" "$ARTIFACT_CONTEXT"`

7. **Enhanced progress tracking, error handling, and artifact management**:

   - Report progress after each completed task WITH KB compliance status AND artifact generation status
   - Halt execution if any non-parallel task fails OR violates critical KB patterns
   - For parallel tasks [P], continue with successful tasks, report failed ones
   - **KB Validation**: After each file creation/modification, run:
     ```bash
     validate_against_patterns "$created_file" "$detected_context"
     ```
   - **Artifact Tracking**: After each milestone, update artifact status:
     ```bash
     echo "Milestone completed: $(date)" >> artifacts/implement/implementation_progress.log
     ```
   - Provide clear error messages with context for debugging AND KB guidance
   - Suggest next steps if implementation cannot proceed, including KB remediation
   - **IMPORTANT** For completed tasks, mark as [X] in tasks file AND log KB compliance status AND artifact generation status

8. **Enhanced completion validation with KB compliance report and artifact summary**:
   - Verify all required tasks are completed
   - Check that implemented features match the original specification
   - Validate that tests pass and coverage meets requirements
   - Confirm the implementation follows the technical plan
   - **KB Compliance Validation**:
     - Generate final compliance report using `generate_compliance_report "implement"`
     - Validate all created files against KB patterns
     - Document any deviations with justifications
     - Ensure coding standards compliance across all artifacts
   - **Artifact Generation Summary**:
     - Generate final artifact summary: `generate_phase_summary "implement" "$ARTIFACT_CONTEXT"`
     - Validate all implementation artifacts are generated and complete
     - Ensure artifact traceability is properly recorded
     - Generate implementation completion report
   - Report final status with summary of completed work, KB compliance metrics, AND artifact generation results

## Implementation Completion Report

At completion, generate and display:

### Implementation Compliance Summary

- **Total Files Created**: [count]
- **KB Patterns Applied**: [list]
- **Compliance Status**: ✅ PASS / ❌ FAIL / ⚠️ PARTIAL
- **Violations Found**: [count and severity]
- **Remediation Required**: [yes/no with details]

### Artifact Generation Summary

- **Total Artifacts Generated**: [count]
- **Artifact Types**:
  - ✅ Code Quality Report (`artifacts/implement/code_quality_report.json`)
  - ✅ Test Coverage Report (`artifacts/implement/test_coverage_report.html`)
  - ✅ Performance Benchmarks (`artifacts/implement/performance_benchmarks.md`)
  - ✅ API Documentation (`artifacts/implement/api_documentation.md`)
- **Artifact Status**: ✅ ALL GENERATED / ⚠️ PARTIAL / ❌ FAILED
- **Traceability**: [generation IDs and versions]

### KB Pattern Application Results

| File               | KB Pattern      | Status     | Issues                 | Remediation          |
| ------------------ | --------------- | ---------- | ---------------------- | -------------------- |
| src/models/user.py | domain-modeling | ✅ PASS    | None                   | N/A                  |
| src/api/routes.py  | api-design      | ⚠️ PARTIAL | Missing error handling | Add try-catch blocks |

### Implementation Artifacts Generated

| Artifact Type          | File Path                                       | Status  | KB Compliance | Version                     |
| ---------------------- | ----------------------------------------------- | ------- | ------------- | --------------------------- |
| Code Quality Report    | `artifacts/implement/code_quality_report.json`  | ✅ PASS | 95%           | implement.v1.0\_[timestamp] |
| Test Coverage Report   | `artifacts/implement/test_coverage_report.html` | ✅ PASS | 92%           | implement.v1.0\_[timestamp] |
| Performance Benchmarks | `artifacts/implement/performance_benchmarks.md` | ✅ PASS | 88%           | implement.v1.0\_[timestamp] |
| API Documentation      | `artifacts/implement/api_documentation.md`      | ✅ PASS | 90%           | implement.v1.0\_[timestamp] |

### Final Recommendations

- **Immediate Actions**: [critical issues to resolve]
- **Future Improvements**: [enhancement opportunities]
- **KB References**: [links to relevant KB sections]
- **Artifact Access**: All implementation artifacts available in `artifacts/implement/` directory
- **Traceability**: Complete artifact history available in `.specify-cache/traceability/artifacts.json`

---

**Note**: This command assumes a complete task breakdown exists in tasks.md. If tasks are incomplete or missing, suggest running `/tasks` first to regenerate the task list.

**KB Integration**: This enhanced implementation command integrates Knowledge Base v1.0 patterns and validation throughout the implementation process, ensuring code quality and consistency with established best practices.

**Artifact Generation**: This command now includes automatic generation of rich implementation artifacts (code quality reports, test coverage, performance benchmarks, and API documentation) with full KB integration and traceability. All artifacts are automatically generated during the implementation process and stored in the `artifacts/implement/` directory with complete version control and compliance tracking.

**System Integration**: The implementation process now seamlessly integrates with the SDD v2.0 Artifact Generation System, providing comprehensive documentation, metrics, and traceability for all implementation activities while maintaining full compatibility with existing workflows.
