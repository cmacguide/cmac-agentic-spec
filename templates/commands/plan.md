---
description: Execute the implementation planning workflow using the plan template to generate design artifacts.
scripts:
  sh: scripts/bash/setup-plan.sh --json
  ps: scripts/powershell/setup-plan.ps1 -Json
---

The user input to you can be provided directly by the agent or as a command argument - you **MUST** consider it before proceeding with the prompt (if not empty).

User input:

$ARGUMENTS

Given the implementation details provided as an argument, do this:

## Knowledge Base Integration for Planning (MANDATORY)

**CRITICAL**: Before proceeding with planning, MUST execute KB integration for architectural validation:

1. **Source KB Integration Module (robusto)**:

   ```bash
   # Tenta .specify/scripts/ (pacote) ou scripts/ (dev)
   source scripts/bash/include-kb.sh
   ```

2. **Query KB for Planning Context**:

   ```bash
   KB_CONTEXT=$(get_applicable_principles "plan")
   KB_REFERENCE=$(query_knowledge_base "shared-principles" "architecture design patterns best practices")
   ```

3. **Prepare Planning Validation**:

   ```bash
   # Will be used during planning to validate decisions
   VALIDATION_RESULT="KB patterns ready for planning validation"
   ```

4. **Fallback Handling**: If KB unavailable, continue with built-in planning patterns but note limitation in final report.

## Planning Execution Steps

1. **KB Integration Setup** (MANDATORY):
   Execute KB integration steps above. Store results in variables:

   - `{KB_REFERENCE}` - Planning patterns and design guidance from KB
   - `{VALIDATION_RESULT}` - Pattern validation status
   - `{KB_CONTEXT}` - Applicable principles for planning phase

2. Run `{SCRIPT}` from the repo root and parse JSON for FEATURE_SPEC, IMPL_PLAN, SPECS_DIR, BRANCH. All future file paths must be absolute.

   - BEFORE proceeding, inspect FEATURE_SPEC for a `## Clarifications` section with at least one `Session` subheading. If missing or clearly ambiguous areas remain (vague adjectives, unresolved critical choices), PAUSE and instruct the user to run `/clarify` first to reduce rework. Only continue if: (a) Clarifications exist OR (b) an explicit user override is provided (e.g., "proceed without clarification"). Do not attempt to fabricate clarifications yourself.

3. **Read and analyze the feature specification with KB integration**:

   - The feature requirements and user stories
   - Functional and non-functional requirements
   - Success criteria and acceptance criteria
   - Any technical constraints or dependencies mentioned
   - **KB ENHANCEMENT**: Cross-reference requirements against `{KB_REFERENCE}` planning patterns

4. Read the constitution at `/memory/constitution.md` to understand constitutional requirements.

   - **KB ENHANCEMENT**: Cross-validate constitution against KB principles

5. **Execute the implementation plan template with KB integration**:

   - Load `/templates/plan-template.md` (already copied to IMPL_PLAN path)
   - Set Input path to FEATURE_SPEC
   - **KB ENHANCEMENT**: Apply KB context to Technical Context analysis
   - **KB ENHANCEMENT**: Use KB patterns for directory structure generation
   - Run the Execution Flow (main) function steps 1-9 with KB validation
   - The template is self-contained and executable
   - Follow error handling and gate checks as specified
   - Let the template guide artifact generation in $SPECS_DIR:
     - Phase 0 generates research.md (with KB research guidance)
     - Phase 1 generates data-model.md, contracts/, quickstart.md (with KB pattern validation)
     - Phase 2 generates tasks.md (with KB implementation patterns)
   - Incorporate user-provided details from arguments into Technical Context: {ARGS}
   - **KB ENHANCEMENT**: Apply KB compliance validation throughout
   - Update Progress Tracking as you complete each phase

6. **Enhanced validation and quality assurance**:

   - **Pattern Consistency**: Validate planning decisions against KB standards
   - **Architecture Alignment**: Ensure planned architecture follows KB patterns
   - **KB Compliance Validation**: Generate compliance report using `generate_compliance_report "plan"`

7. Verify execution completed:

   - Check Progress Tracking shows all phases complete
   - Ensure all required artifacts were generated
   - Confirm no ERROR states in execution
   - **KB ENHANCEMENT**: Validate KB compliance status

8. **KB Integration Compliance Report**:
   Generate and display planning compliance summary with KB pattern application results.

9. Report results with branch name, file paths, and generated artifacts.
   - Include KB compliance status and applied patterns
   - Reference KB-generated directory structures and decisions

Use absolute paths with the repository root for all file operations to avoid path issues.

**KB Integration**: This enhanced planning command integrates Knowledge Base v1.0 patterns and validation throughout the planning process, ensuring design quality and consistency with established best practices, including dynamic directory structure generation based on technology stack and architecture patterns.
