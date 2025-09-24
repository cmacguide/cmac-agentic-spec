---
description: Perform a non-destructive cross-artifact consistency and quality analysis across spec.md, plan.md, and tasks.md after task generation.
scripts:
  sh: scripts/bash/check-prerequisites.sh --json --require-tasks --include-tasks
  ps: scripts/powershell/check-prerequisites.ps1 -Json -RequireTasks -IncludeTasks
---

The user input to you can be provided directly by the agent or as a command argument - you **MUST** consider it before proceeding with the prompt (if not empty).

User input:

$ARGUMENTS

Goal: Identify inconsistencies, duplications, ambiguities, and underspecified items across the three core artifacts (`spec.md`, `plan.md`, `tasks.md`) before implementation. This command MUST run only after `/tasks` has successfully produced a complete `tasks.md`.

STRICTLY READ-ONLY: Do **not** modify any files. Output a structured analysis report. Offer an optional remediation plan (user must explicitly approve before any follow-up editing commands would be invoked manually).

Constitution Authority: The project constitution (`/memory/constitution.md`) is **non-negotiable** within this analysis scope. Constitution conflicts are automatically CRITICAL and require adjustment of the spec, plan, or tasks—not dilution, reinterpretation, or silent ignoring of the principle. If a principle itself needs to change, that must occur in a separate, explicit constitution update outside `/analyze`.

## Artifact Generation Setup (MANDATORY)

**CRITICAL**: Before proceeding with analysis, MUST initialize artifact generation system:

1. **Source Artifact Generation Module**:

   ```bash
   source scripts/bash/artifact-generation.sh
   ```

2. **Initialize Analysis Artifacts**:

   ```bash
   ARTIFACT_CONTEXT="${ARGUMENTS:-analyze}"
   ARTIFACT_PHASE="analyze"
   ```

3. **Prepare Analysis Artifacts**:

   ```bash
   # Generate analysis artifacts automatically
   echo "Generating analysis artifacts..."
   generate_phase_artifacts "$ARTIFACT_PHASE" "$ARTIFACT_CONTEXT"
   ```

## Knowledge Base Integration (MANDATORY)

**CRITICAL**: Before proceeding with analysis, MUST execute KB integration for contextual validation:

1. **Source KB Integration Module**:

   ```bash
   source scripts/bash/knowledge-base-integration.sh
   ```

2. **Query KB for Analysis Context**:

   ```bash
   KB_CONTEXT=$(get_applicable_principles "analyze")
   KB_REFERENCE=$(query_knowledge_base "shared-principles" "architecture patterns consistency validation")
   ```

3. **Generate KB Validation Results**:

   ```bash
   VALIDATION_RESULT=$(validate_against_patterns "$SPEC" "shared-principles")
   ```

4. **Fallback Handling**: If KB unavailable, continue with built-in validation but note limitation in report.

## Execution Steps

1. **KB Integration Setup** (MANDATORY):
   Execute KB integration steps above. Store results in variables:

   - `{KB_REFERENCE}` - Contextual guidance from KB
   - `{VALIDATION_RESULT}` - Pattern validation results
   - `{KB_CONTEXT}` - Applicable principles for analyze phase

2. Run `{SCRIPT}` once from repo root and parse JSON for FEATURE_DIR and AVAILABLE_DOCS. Derive absolute paths:

   - SPEC = FEATURE_DIR/spec.md
   - PLAN = FEATURE_DIR/plan.md
   - TASKS = FEATURE_DIR/tasks.md
     Abort with an error message if any required file is missing (instruct the user to run missing prerequisite command).

3. **Load artifacts with KB context**:

   - Parse spec.md sections: Overview/Context, Functional Requirements, Non-Functional Requirements, User Stories, Edge Cases (if present).
   - Parse plan.md: Architecture/stack choices, Data Model references, Phases, Technical constraints.
   - Parse tasks.md: Task IDs, descriptions, phase grouping, parallel markers [P], referenced file paths.
   - Load constitution `/memory/constitution.md` for principle validation.
   - **Apply KB context**: Cross-reference artifacts against `{KB_REFERENCE}` patterns.

4. **Build internal semantic models with KB validation**:

   - Requirements inventory: Each functional + non-functional requirement with a stable key (derive slug based on imperative phrase; e.g., "User can upload file" -> `user-can-upload-file`).
   - User story/action inventory.
   - Task coverage mapping: Map each task to one or more requirements or stories (inference by keyword / explicit reference patterns like IDs or key phrases).
   - Constitution rule set: Extract principle names and any MUST/SHOULD normative statements.
   - **KB Pattern Mapping**: Map requirements to applicable KB patterns from `{KB_CONTEXT}`.

5. **Enhanced Detection Passes with KB Integration**:
   A. **KB Pattern Compliance** (NEW):

   - Validate artifacts against `{VALIDATION_RESULT}` patterns
   - Check adherence to KB architectural principles
   - Flag deviations from established best practices

   B. Duplication detection:

   - Identify near-duplicate requirements. Mark lower-quality phrasing for consolidation.

   C. Ambiguity detection:

   - Flag vague adjectives (fast, scalable, secure, intuitive, robust) lacking measurable criteria.
   - Flag unresolved placeholders (TODO, TKTK, ???, <placeholder>, etc.).
   - **KB Enhancement**: Cross-reference against KB guidance for clarity standards.

   D. Underspecification:

   - Requirements with verbs but missing object or measurable outcome.
   - User stories missing acceptance criteria alignment.
   - Tasks referencing files or components not defined in spec/plan.
   - **KB Enhancement**: Validate against KB completeness patterns.

   E. Constitution alignment:

   - Any requirement or plan element conflicting with a MUST principle.
   - Missing mandated sections or quality gates from constitution.
   - **KB Enhancement**: Cross-validate with KB constitutional patterns.

   F. Coverage gaps:

   - Requirements with zero associated tasks.
   - Tasks with no mapped requirement/story.
   - Non-functional requirements not reflected in tasks (e.g., performance, security).
   - **KB Enhancement**: Check against KB coverage standards.

   G. Inconsistency:

   - Terminology drift (same concept named differently across files).
   - Data entities referenced in plan but absent in spec (or vice versa).
   - Task ordering contradictions (e.g., integration tasks before foundational setup tasks without dependency note).
   - Conflicting requirements (e.g., one requires to use Next.js while other says to use Vue as the framework).
   - **KB Enhancement**: Validate consistency against KB naming and pattern conventions.

6. **Enhanced Severity Assignment with KB Context**:

   - **CRITICAL**: Violates constitution MUST, missing core spec artifact, requirement with zero coverage that blocks baseline functionality, **OR fails KB mandatory patterns**.
   - **HIGH**: Duplicate or conflicting requirement, ambiguous security/performance attribute, untestable acceptance criterion, **OR violates KB architectural principles**.
   - **MEDIUM**: Terminology drift, missing non-functional task coverage, underspecified edge case, **OR deviates from KB recommended patterns**.
   - **LOW**: Style/wording improvements, minor redundancy not affecting execution order, **OR minor KB style guideline deviations**.

7. **Produce Enhanced Markdown Report with KB Integration**:

   ### Specification Analysis Report with Knowledge Base Integration

   #### KB Integration Status

   - **KB Available**: ✅/❌ Knowledge Base accessible
   - **KB Context**: `{KB_CONTEXT}`
   - **Validation Executed**: `{VALIDATION_RESULT}` summary
   - **KB Reference Applied**: `{KB_REFERENCE}` key points

   #### Analysis Results

   | ID  | Category    | Severity | Location(s)      | Summary                               | KB Pattern        | Recommendation                       |
   | --- | ----------- | -------- | ---------------- | ------------------------------------- | ----------------- | ------------------------------------ |
   | A1  | Duplication | HIGH     | spec.md:L120-134 | Two similar requirements ...          | clean-code-naming | Merge phrasing; keep clearer version |
   | K1  | KB Pattern  | MEDIUM   | plan.md:L45-50   | Architecture deviates from KB pattern | domain-modeling   | Apply KB domain modeling principles  |

   (Add one row per finding; generate stable IDs prefixed by category initial. Use 'K' prefix for KB-specific findings.)

   #### Additional Subsections:

   - **KB Compliance Summary**:
     | Pattern | Status | Issues Found | Recommendations |
   - **Coverage Summary Table**:
     | Requirement Key | Has Task? | Task IDs | KB Pattern Match | Notes |
   - **Constitution Alignment Issues** (if any)
   - **KB Pattern Violations** (if any)
   - **Unmapped Tasks** (if any)
   - **Enhanced Metrics**:
     - Total Requirements
     - Total Tasks
     - Coverage % (requirements with >=1 task)
     - KB Pattern Compliance %
     - Ambiguity Count
     - Duplication Count
     - Critical Issues Count
     - KB Violations Count
   - **Artifact Generation Summary**:
     - Total Artifacts Generated: 4
     - Artifact Status: ✅ ALL GENERATED / ⚠️ PARTIAL / ❌ FAILED
     - Traceability: [generation IDs and versions]
     - KB Compliance: [compliance percentages per artifact]

8. **Enhanced Next Actions with KB Guidance and Artifact References**:

   - If CRITICAL issues exist (including KB violations): Recommend resolving before `/implement`.
   - If only LOW/MEDIUM: User may proceed, but provide improvement suggestions with KB references.
   - **KB-Enhanced Command Suggestions**:
     - "Run /specify with refinement based on KB pattern X"
     - "Run /plan to adjust architecture following KB guidance Y"
     - "Apply KB pattern Z to resolve consistency issues"
     - "Manually edit tasks.md to add coverage for 'performance-metrics' per KB standards"
   - **Artifact References**:
     - "Review detailed analysis in `artifacts/analyze/architecture_assessment.md`"
     - "Check compliance details in `artifacts/analyze/compliance_check.json`"
     - "See KB references in `artifacts/analyze/knowledge_base_references.md`"
     - "Review technical debt in `artifacts/analyze/technical_debt_report.md`"

9. **KB-Aware Remediation Offer with Artifact Context**: Ask the user: "Would you like me to suggest concrete remediation edits for the top N issues, including KB pattern applications? All analysis details are available in the generated artifacts in `artifacts/analyze/` directory." (Do NOT apply them automatically.)

Behavior rules:

- NEVER modify files.
- NEVER hallucinate missing sections—if absent, report them.
- KEEP findings deterministic: if rerun without changes, produce consistent IDs and counts.
- LIMIT total findings in the main table to 50; aggregate remainder in a summarized overflow note.
- If zero issues found, emit a success report with coverage statistics and proceed recommendation.

Context: {ARGS}
