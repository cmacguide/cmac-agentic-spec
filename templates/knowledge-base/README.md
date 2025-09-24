# Knowledge Base v2 - Contextually Organized

## 🎯 Overview

This knowledge base provides **contextually-aware guidance** on software engineering best practices. Unlike traditional organization by methodology, we organize knowledge by **application context** to ensure appropriate guidance for each area of development.

---

## 🗂️ Knowledge Organization

### **🌐 Shared Principles** - Universal Best Practices

Principles that apply across all development contexts:

- **[Clean Code](./shared-principles/clean-code/)** - Naming, functions, comments, refactoring
- **[Clean Architecture](./shared-principles/clean-architecture/)** - SOLID principles, dependency rule, testing
- **[Templates](./shared-principles/templates/)** - Universal code review and refactoring templates

### **🎨 Frontend** - User Interface Development

Frontend-specific patterns and practices:

- **[React Patterns](./frontend/react-patterns/)** - Component design, hooks, performance
- **[State Management](./frontend/state-management/)** - Redux, Zustand, Context patterns
- **[UI Architecture](./frontend/ui-architecture/)** - Component hierarchies, design systems
- **[Performance](./frontend/performance/)** - Optimization, lazy loading, bundle splitting

### **⚙️ Backend** - Server-Side Development

Backend-specific domain modeling and API design:

- **[Domain Modeling](./backend/domain-modeling/)** - DDD strategic design, tactical patterns
- **[API Design](./backend/api-design/)** - REST, GraphQL, versioning, documentation
- **[Data Persistence](./backend/data-persistence/)** - Repository patterns, ORM best practices
- **[Security](./backend/security/)** - Authentication, authorization, data protection

### **🚀 DevOps/SRE** - Infrastructure & Operations

Infrastructure and operational excellence:

- **[Infrastructure as Code](./devops-sre/infrastructure-as-code/)** - Terraform, CloudFormation, Bicep
- **[Deployment Patterns](./devops-sre/deployment-patterns/)** - CI/CD, blue-green, canary
- **[Monitoring](./devops-sre/monitoring/)** - Observability, alerting, dashboards
- **[Reliability](./devops-sre/reliability/)** - SLA/SLO, incident response, resilience

---

## 🎯 Quick Navigation by Use Case

### **🔍 Code Review Scenarios**

```
Question: "How do I review React component code?"
→ Reference: frontend/react-patterns/component-design.md
→ Template: frontend/react-patterns/review-checklist.md

Question: "How do I review domain logic code?"
→ Reference: backend/domain-modeling/tactical-patterns.md
→ Template: shared-principles/templates/code-review.md
```

### **🏗️ Architecture Design**

```
Question: "How do I structure a new microservice?"
→ Reference: backend/domain-modeling/strategic-design.md
→ Template: backend/api-design/service-design-template.md

Question: "How do I design a React application architecture?"
→ Reference: frontend/ui-architecture/component-hierarchies.md
→ Template: frontend/ui-architecture/app-structure-template.md
```

### **🔧 Performance Optimization**

```
Question: "How do I optimize React app performance?"
→ Reference: frontend/performance/optimization-strategies.md

Question: "How do I optimize API performance?"
→ Reference: backend/api-design/performance-patterns.md
```

### **🚀 Deployment & Operations**

```
Question: "How do I set up CI/CD for this project?"
→ Reference: devops-sre/deployment-patterns/ci-cd-best-practices.md

Question: "How do I monitor application health?"
→ Reference: devops-sre/monitoring/application-monitoring.md
```

---

## 🧭 Contextual Guidance Philosophy

### **Why Context-Based Organization?**

**Traditional Problem:**

- DDD principles applied to React components ❌
- Clean Architecture patterns forced into DevOps scripts ❌
- Backend security patterns applied to frontend state ❌

**Our Solution:**

- **Frontend guidance** for UI/UX concerns ✅
- **Backend guidance** for domain modeling and APIs ✅
- **DevOps guidance** for infrastructure and operations ✅
- **Shared principles** for universal best practices ✅

### **Smart Knowledge Application**

```typescript
// Example: Context-appropriate guidance

// Frontend Context - UI State Management
const UserProfile = () => {
  // ✅ Frontend guidance: React hooks, component patterns
  const [user, setUser] = useState<User | null>(null);

  // ✅ Shared principles: Clean Code naming
  const updateUserProfile = useCallback((newData: Partial<User>) => {
    setUser(current => current ? { ...current, ...newData } : null);
  }, []);
};

// Backend Context - Domain Logic
class User {
  // ✅ Backend guidance: DDD entity patterns
  // ✅ Shared principles: Clean Code functions
  changeEmail(newEmail: Email, requestingUserId: UserId): void {
    if (!this.canBeModifiedBy(requestingUserId)) {
      throw new Error("Users can only change their own email");
    }
    this.email = newEmail;
  }
}

// DevOps Context - Infrastructure
resource "aws_lambda_function" "user_service" {
  // ✅ DevOps guidance: Infrastructure as Code patterns
  // ✅ Shared principles: Clear naming
  function_name = "user-profile-service"
  handler      = "index.handler"
  runtime      = "nodejs18.x"
}
```

---

## 📋 Context-Specific Quick Reference

### **Frontend Development**

| Concern          | Context-Specific Guide       | Shared Principle                                           |
| ---------------- | ---------------------------- | ---------------------------------------------------------- |
| Component Design | `frontend/react-patterns/`   | `shared-principles/clean-code/functions.md`                |
| State Management | `frontend/state-management/` | `shared-principles/clean-architecture/solid-principles.md` |
| Performance      | `frontend/performance/`      | `shared-principles/clean-code/refactoring.md`              |

### **Backend Development**

| Concern         | Context-Specific Guide      | Shared Principle                                           |
| --------------- | --------------------------- | ---------------------------------------------------------- |
| Domain Modeling | `backend/domain-modeling/`  | `shared-principles/clean-architecture/dependency-rule.md`  |
| API Design      | `backend/api-design/`       | `shared-principles/clean-code/naming.md`                   |
| Data Access     | `backend/data-persistence/` | `shared-principles/clean-architecture/solid-principles.md` |

### **DevOps/SRE**

| Concern        | Context-Specific Guide               | Shared Principle                                          |
| -------------- | ------------------------------------ | --------------------------------------------------------- |
| Infrastructure | `devops-sre/infrastructure-as-code/` | `shared-principles/clean-code/naming.md`                  |
| Deployment     | `devops-sre/deployment-patterns/`    | `shared-principles/clean-code/functions.md`               |
| Monitoring     | `devops-sre/monitoring/`             | `shared-principles/clean-architecture/dependency-rule.md` |

---

## 🔄 Migration from Knowledge Base v1

### **What Changed**

**Old Structure (Methodology-Based):**

```
knowledge-base/
├── clean-code/          # Applied everywhere (good and bad)
├── clean-architecture/  # Applied everywhere (good and bad)
└── domain-driven-design/ # Applied everywhere (BAD)
```

**New Structure (Context-Based):**

```
knowledge-base-v2/
├── shared-principles/   # Universal principles only
├── frontend/           # UI-specific guidance
├── backend/            # Domain-specific guidance
└── devops-sre/         # Infrastructure-specific guidance
```

### **Content Mapping**

| Old Location                     | New Location                             | Reason                         |
| -------------------------------- | ---------------------------------------- | ------------------------------ |
| `clean-code/principles.md`       | `shared-principles/clean-code/*`         | Split into focused files       |
| `domain-driven-design/*`         | `backend/domain-modeling/*`              | DDD is backend-specific        |
| `clean-architecture/patterns.md` | `shared-principles/clean-architecture/*` | Split by universal vs specific |

---

## 🎨 How to Use This Knowledge Base

### **For Developers**

1. **Identify your context** (Frontend, Backend, DevOps)
2. **Start with context-specific guidance** for your area
3. **Apply shared principles** for universal best practices
4. **Use templates** for consistent implementation

### **For Code Reviews**

1. **Context-aware reviews**: Use appropriate guidance for each file
2. **Frontend files**: Apply frontend patterns + shared principles
3. **Backend files**: Apply domain patterns + shared principles
4. **Infrastructure files**: Apply DevOps patterns + shared principles

### **For Architecture Decisions**

1. **Domain boundaries**: Use backend domain modeling guidance
2. **UI architecture**: Use frontend architecture guidance
3. **System architecture**: Use DevOps infrastructure guidance
4. **Cross-cutting concerns**: Use shared principles

---

## 📈 Benefits of Contextual Organization

### **✅ Improvements**

- **Appropriate guidance** for each development context
- **Reduced cognitive load** - only relevant patterns shown
- **Better guidance quality** - context-specific examples
- **Easier maintenance** - clear boundaries between concerns

### **🎯 Expected Outcomes**

- **Frontend developers** get React/UI-specific guidance
- **Backend developers** get domain modeling and API guidance
- **DevOps engineers** get infrastructure and operational guidance
- **Everyone** gets appropriate shared principles

---

## 🔧 Maintenance Guidelines

### **Adding New Content**

1. **Identify the appropriate context** (shared vs specific)
2. **Use context-appropriate examples** and terminology
3. **Link to related shared principles** when relevant
4. **Avoid context pollution** (no DDD in frontend guides)

### **Updating Existing Content**

1. **Maintain context focus** when updating guides
2. **Update cross-references** when content moves
3. **Validate examples** are appropriate for the context
4. **Keep shared principles universal**

---

_This knowledge base serves as the contextually-aware reference for software engineering best practices within the CMAC-AI agent system._
