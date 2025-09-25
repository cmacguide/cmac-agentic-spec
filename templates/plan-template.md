---
description: "Implementation plan template for feature development"
scripts:
  sh: scripts/bash/update-agent-context.sh __AGENT__
  ps: scripts/powershell/update-agent-context.ps1 -AgentType __AGENT__
---

# Implementation Plan: [FEATURE]

**Branch**: `[###-feature-name]` | **Date**: [DATE] | **Spec**: [link]
**Input**: Feature specification from `/specs/[###-feature-name]/spec.md`

## Knowledge Base Integration Status

**KB Integration**: {KB_REFERENCE}
**Validation Results**: {VALIDATION_RESULT}
**Applicable Principles**: {KB_CONTEXT}
**Compliance Status**: ✅ PASS / ❌ FAIL / ⚠️ PARTIAL

## Execution Flow (/plan command scope)

```
1. **KB Integration Setup** (MANDATORY):
   → Source scripts/bash/knowledge-base-integration.sh
   → KB_CONTEXT=$(get_applicable_principles "plan")
   → KB_REFERENCE=$(query_knowledge_base "shared-principles" "architecture design patterns best practices")
   → VALIDATION_RESULT=$(validate_against_patterns "$INPUT_SPEC" "shared-principles")
   → If KB unavailable: Continue with fallback guidance, note limitation

2. Load feature spec from Input path
   → If not found: ERROR "No feature spec at {path}"
   → Cross-reference with KB architectural patterns

3. **Fill Technical Context with KB-Enhanced Structure Generation** (scan for NEEDS CLARIFICATION):
   → Detect Project Type from context (web=frontend+backend, mobile=app+api)
   → **KB Enhancement**: Extract tech stack from Technical Context
   → **KB Enhancement**: TECH_STACK=$(extract_tech_stack_from_context "$TECHNICAL_CONTEXT")
   → **KB Enhancement**: ARCHITECTURE_PATTERN=$(detect_architecture_pattern "$TECH_STACK")
   → **KB Enhancement**: DYNAMIC_STRUCTURE=$(get_directory_structure "$TECH_STACK" "$ARCHITECTURE_PATTERN")
   → **KB Enhancement**: STRUCTURE_DECISION=$(generate_structure_decision "$TECHNICAL_CONTEXT")
   → **Apply KB Context**: Validate tech choices against KB recommendations
   → **Update Project Structure section**: Replace {DYNAMIC_STRUCTURE} and {STRUCTURE_DECISION} placeholders

4. Fill the Constitution Check section based on the content of the constitution document.
   → **Enhanced with KB**: Cross-validate constitution against KB principles

5. **KB Compliance Check** (NEW):
   → Validate planned architecture against KB patterns
   → Document any deviations with justification
   → Update KB Integration Status section

6. Evaluate Constitution Check section below
   → If violations exist: Document in Complexity Tracking
   → If no justification possible: ERROR "Simplify approach first"
   → **KB Enhancement**: Include KB pattern violations in evaluation
   → Update Progress Tracking: Initial Constitution Check

7. Execute Phase 0 → research.md
   → If NEEDS CLARIFICATION remain: ERROR "Resolve unknowns"
   → **KB Enhancement**: Include KB research guidance

8. Execute Phase 1 → contracts, data-model.md, quickstart.md, agent-specific template file
   → **KB Enhancement**: Apply KB patterns to all artifacts
   → Validate contracts against KB API design patterns
   → Ensure data model follows KB domain modeling principles

9. Re-evaluate Constitution Check section
   → If new violations: Refactor design, return to Phase 1
   → **KB Enhancement**: Re-validate KB compliance
   → Update Progress Tracking: Post-Design Constitution Check

10. **Final KB Compliance Validation** (NEW):
    → Generate comprehensive KB compliance report
    → Document all applied patterns and deviations
    → Update KB Integration Status

11. Plan Phase 2 → Describe task generation approach (DO NOT create tasks.md)
12. STOP - Ready for /tasks command
```

**IMPORTANT**: The /plan command STOPS at step 7. Phases 2-4 are executed by other commands:

- Phase 2: /tasks command creates tasks.md
- Phase 3-4: Implementation execution (manual or via tools)

## Summary

[Extract from feature spec: primary requirement + technical approach from research]

## Technical Context

**Language/Version**: [e.g., Python 3.11, Swift 5.9, Rust 1.75 or NEEDS CLARIFICATION]  
**Primary Dependencies**: [e.g., FastAPI, UIKit, LLVM or NEEDS CLARIFICATION]  
**Storage**: [if applicable, e.g., PostgreSQL, CoreData, files or N/A]  
**Testing**: [e.g., pytest, XCTest, cargo test or NEEDS CLARIFICATION]  
**Target Platform**: [e.g., Linux server, iOS 15+, WASM or NEEDS CLARIFICATION]
**Project Type**: [single/web/mobile - determines source structure]  
**Performance Goals**: [domain-specific, e.g., 1000 req/s, 10k lines/sec, 60 fps or NEEDS CLARIFICATION]  
**Constraints**: [domain-specific, e.g., <200ms p95, <100MB memory, offline-capable or NEEDS CLARIFICATION]  
**Scale/Scope**: [domain-specific, e.g., 10k users, 1M LOC, 50 screens or NEEDS CLARIFICATION]

## Constitution Check with KB Integration

_GATE: Must pass before Phase 0 research. Re-check after Phase 1 design._

### Constitutional Compliance

[Gates determined based on constitution file]

### KB Pattern Compliance

**Applicable KB Patterns**: {KB_CONTEXT}
**Pattern Validation Results**:

- ✅ **Shared Principles**: {VALIDATION_RESULT}
- ✅ **Architecture Patterns**: Compliant with KB architectural guidelines
- ⚠️ **Domain Patterns**: Partial compliance - see deviations below
- ❌ **Implementation Patterns**: Violations found - requires remediation

### Compliance Deviations

| Pattern            | Status     | Deviation                       | Justification            | Remediation Plan                   |
| ------------------ | ---------- | ------------------------------- | ------------------------ | ---------------------------------- |
| clean-architecture | ❌ FAIL    | Direct DB access in controllers | Performance requirements | Refactor to use repository pattern |
| domain-modeling    | ⚠️ PARTIAL | Anemic domain model             | Legacy constraints       | Gradually enrich domain objects    |

### KB References Applied

- **Architecture**: {KB_REFERENCE}
- **Design Patterns**: Applied from memory/knowledge-base/shared-principles/
- **Best Practices**: Integrated from context-specific KB modules

## Project Structure

### Documentation (this feature)

```
specs/[###-feature]/
├── plan.md              # This file (/plan command output)
├── research.md          # Phase 0 output (/plan command)
├── data-model.md        # Phase 1 output (/plan command)
├── quickstart.md        # Phase 1 output (/plan command)
├── contracts/           # Phase 1 output (/plan command)
└── tasks.md             # Phase 2 output (/tasks command - NOT created by /plan)
```

### Source Code (repository root) - KB Enhanced Dynamic Structure

**IMPORTANT**: This structure is dynamically generated based on Technical Context using Knowledge Base patterns.

```bash
# Generate dynamic structure based on tech stack and architecture pattern
TECH_STACK="$(extract_tech_stack_from_context)"
ARCHITECTURE_PATTERN="$(detect_architecture_pattern "$TECH_STACK")"
DYNAMIC_STRUCTURE="$(get_directory_structure "$TECH_STACK" "$ARCHITECTURE_PATTERN")"
```

**Generated Structure**:

```
{DYNAMIC_STRUCTURE}
```

**KB Structure Generation Process**:

1. **Technology Detection**: Analyze Technical Context for framework/language indicators
2. **Architecture Pattern Detection**: Identify DDD, Clean Architecture, or other patterns
3. **Structure Selection**: Choose appropriate template from KB patterns:
   - Next.js + Clean Architecture (+ optional DDD)
   - Remix + Clean Architecture (+ optional DDD)
   - React + Clean Architecture (+ optional DDD)
   - Backend + Clean Architecture (+ optional DDD)
   - Fullstack + Clean Architecture (+ optional DDD)
   - Mobile + API structure
   - Default + Clean Architecture (+ optional DDD)

**Fallback Structure** (if KB unavailable):

```
# Default Clean Architecture Structure
src/
├── models/              # Data models
├── services/            # Business logic
├── controllers/         # Controllers/Handlers
├── utils/               # Utility functions
├── types/               # TypeScript types
└── config/              # Configuration

tests/
├── unit/                # Unit tests
├── integration/         # Integration tests
└── contract/            # Contract tests
```

{STRUCTURE_DECISION}

## Phase 0: Outline & Research

1. **Extract unknowns from Technical Context** above:

   - For each NEEDS CLARIFICATION → research task
   - For each dependency → best practices task
   - For each integration → patterns task

2. **Generate and dispatch research agents**:

   ```
   For each unknown in Technical Context:
     Task: "Research {unknown} for {feature context}"
   For each technology choice:
     Task: "Find best practices for {tech} in {domain}"
   ```

3. **Consolidate findings** in `research.md` using format:
   - Decision: [what was chosen]
   - Rationale: [why chosen]
   - Alternatives considered: [what else evaluated]

**Output**: research.md with all NEEDS CLARIFICATION resolved

## Phase 1: Design & Contracts

_Prerequisites: research.md complete_

1. **Extract entities from feature spec** → `data-model.md`:

   - Entity name, fields, relationships
   - Validation rules from requirements
   - State transitions if applicable

2. **Generate API contracts** from functional requirements:

   - For each user action → endpoint
   - Use standard REST/GraphQL patterns
   - Output OpenAPI/GraphQL schema to `/contracts/`

3. **Generate contract tests** from contracts:

   - One test file per endpoint
   - Assert request/response schemas
   - Tests must fail (no implementation yet)

4. **Extract test scenarios** from user stories:

   - Each story → integration test scenario
   - Quickstart test = story validation steps

5. **Update agent file incrementally** (O(1) operation):
   - Run `{SCRIPT}`
     **IMPORTANT**: Execute it exactly as specified above. Do not add or remove any arguments.
   - If exists: Add only NEW tech from current plan
   - Preserve manual additions between markers
   - Update recent changes (keep last 3)
   - Keep under 150 lines for token efficiency
   - Output to repository root

**Output**: data-model.md, /contracts/\*, failing tests, quickstart.md, agent-specific file

## Phase 2: Task Planning Approach

_This section describes what the /tasks command will do - DO NOT execute during /plan_

**Task Generation Strategy**:

- Load `.specify/templates/tasks-template.md` as base
- Generate tasks from Phase 1 design docs (contracts, data model, quickstart)
- Each contract → contract test task [P]
- Each entity → model creation task [P]
- Each user story → integration test task
- Implementation tasks to make tests pass

**Ordering Strategy**:

- TDD order: Tests before implementation
- Dependency order: Models before services before UI
- Mark [P] for parallel execution (independent files)

**Estimated Output**: 25-30 numbered, ordered tasks in tasks.md

**IMPORTANT**: This phase is executed by the /tasks command, NOT by /plan

## Phase 3+: Future Implementation

_These phases are beyond the scope of the /plan command_

**Phase 3**: Task execution (/tasks command creates tasks.md)  
**Phase 4**: Implementation (execute tasks.md following constitutional principles)  
**Phase 5**: Validation (run tests, execute quickstart.md, performance validation)

## Complexity Tracking with KB Integration

_Fill ONLY if Constitution Check or KB Pattern violations exist that must be justified_

### Constitutional Violations

| Violation                  | Why Needed         | Simpler Alternative Rejected Because |
| -------------------------- | ------------------ | ------------------------------------ |
| [e.g., 4th project]        | [current need]     | [why 3 projects insufficient]        |
| [e.g., Repository pattern] | [specific problem] | [why direct DB access insufficient]  |

### KB Pattern Deviations

| KB Pattern         | Deviation           | Business Justification    | Technical Justification  | Mitigation Strategy        |
| ------------------ | ------------------- | ------------------------- | ------------------------ | -------------------------- |
| clean-architecture | Direct DB access    | Performance critical path | 50ms latency requirement | Implement caching layer    |
| solid-principles   | Large service class | Legacy integration needs  | Monolithic external API  | Plan gradual decomposition |

### Compliance Remediation Plan

1. **Immediate Actions**: Address CRITICAL KB violations before Phase 1
2. **Phase 1 Integration**: Apply KB patterns during design phase
3. **Long-term Strategy**: Gradual alignment with KB best practices
4. **Monitoring**: Track compliance improvements in future iterations

## Progress Tracking with KB Integration

_This checklist is updated during execution flow_

**Phase Status**:

- [ ] KB Integration Setup: Complete
- [ ] Phase 0: Research complete (/plan command)
- [ ] Phase 1: Design complete (/plan command)
- [ ] Phase 2: Task planning complete (/plan command - describe approach only)
- [ ] Phase 3: Tasks generated (/tasks command)
- [ ] Phase 4: Implementation complete
- [ ] Phase 5: Validation passed

**Gate Status**:

- [ ] KB Integration: PASS
- [ ] Initial Constitution Check: PASS
- [ ] Initial KB Compliance Check: PASS
- [ ] Post-Design Constitution Check: PASS
- [ ] Final KB Compliance Validation: PASS
- [ ] All NEEDS CLARIFICATION resolved
- [ ] Complexity deviations documented
- [ ] KB pattern deviations justified

**KB Compliance Tracking**:

- [ ] Shared principles applied
- [ ] Context-specific patterns validated
- [ ] Architecture patterns compliant
- [ ] Implementation patterns ready
- [ ] Compliance report generated

---

_Based on Constitution v2.1.1 - See `/memory/constitution.md`_
_Enhanced with Knowledge Base Integration v1.0 - See `/memory/knowledge-base/`_
_KB Compliance Report: {COMPLIANCE_REPORT_PATH}_
