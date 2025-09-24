# Knowledge Base Integration - Guia do Usuário

**Data**: 2025-09-24  
**Versão**: 1.0  
**Módulo**: Sistema de Knowledge-Base - Fase 1.1

## 🎯 Visão Geral

O **Knowledge Base Integration Module** é a infraestrutura base do Sistema de Knowledge-Base do SDD v2.0, fornecendo consultas automáticas, validação de padrões e geração de relatórios de conformidade.

## 📋 Funcionalidades Implementadas

### ✅ Funções Principais

1. **`query_knowledge_base(context, query)`** - Consulta contextual ao KB
2. **`validate_against_patterns(artifact, context)`** - Validação de artefatos
3. **`get_applicable_principles(domain)`** - Princípios aplicáveis por domínio
4. **`generate_compliance_report(phase)`** - Relatórios de conformidade

### ✅ Recursos Avançados

- **Cache Inteligente**: TTL de 24h com invalidação automática
- **Fallback Gracioso**: Orientação básica quando KB indisponível
- **Detecção de Contexto**: Identificação automática de tecnologias
- **Validação Multi-Padrão**: Suporte a múltiplos padrões por contexto

## 🚀 Instalação e Configuração

### Pré-requisitos

- **Bash 4+** ou **PowerShell 5+**
- **Knowledge Base v2** em `memory/knowledge-base/`
- Estrutura de projeto compatível com SDD

### Verificação do Sistema

```bash
# Bash
./scripts/bash/knowledge-base-integration.sh status

# PowerShell
.\scripts\powershell\knowledge-base-integration.ps1 status
```

## 📖 Guia de Uso

### 1. Consulta ao Knowledge Base

#### Bash

```bash
# Consulta básica
./scripts/bash/knowledge-base-integration.sh query "shared-principles" "clean code naming"

# Via função (em scripts)
source scripts/bash/knowledge-base-integration.sh
result=$(query_knowledge_base "frontend" "component design")
echo "$result"
```

#### PowerShell

```powershell
# Consulta básica
.\scripts\powershell\knowledge-base-integration.ps1 query "shared-principles" "clean code naming"

# Via função (em scripts)
. .\scripts\powershell\knowledge-base-integration.ps1
$result = Query-KnowledgeBase -Context "frontend" -Query "component design"
Write-Output $result
```

### 2. Validação de Artefatos

#### Bash

```bash
# Validar arquivo específico
./scripts/bash/knowledge-base-integration.sh validate "./src/component.tsx" "frontend"

# Via função
validation_result=$(validate_against_patterns "./src/api.js" "backend")
echo "$validation_result"
```

#### PowerShell

```powershell
# Validar arquivo específico
.\scripts\powershell\knowledge-base-integration.ps1 validate ".\src\component.tsx" "frontend"

# Via função
$validationResult = Test-AgainstPatterns -ArtifactPath ".\src\api.js" -Context "backend"
Write-Output $validationResult
```

### 3. Obter Princípios Aplicáveis

#### Bash

```bash
# Por fase do SDD
./scripts/bash/knowledge-base-integration.sh principles "analyze"

# Via função
principles=$(get_applicable_principles "architect")
echo "Princípios aplicáveis: $principles"
```

#### PowerShell

```powershell
# Por fase do SDD
.\scripts\powershell\knowledge-base-integration.ps1 principles "analyze"

# Via função
$principles = Get-ApplicablePrinciples -Domain "architect"
Write-Output "Princípios aplicáveis: $principles"
```

### 4. Gerar Relatório de Conformidade

#### Bash

```bash
# Gerar relatório para fase específica
report_file=$(./scripts/bash/knowledge-base-integration.sh report "implement")
echo "Relatório gerado: $report_file"

# Via função
report_path=$(generate_compliance_report "analyze")
cat "$report_path"
```

#### PowerShell

```powershell
# Gerar relatório para fase específica
$reportFile = .\scripts\powershell\knowledge-base-integration.ps1 report "implement"
Write-Output "Relatório gerado: $reportFile"

# Via função
$reportPath = New-ComplianceReport -Phase "analyze"
Get-Content $reportPath
```

## 🔧 Configuração Avançada

### Contextos Suportados

| Contexto            | Descrição                | Padrões Incluídos                               |
| ------------------- | ------------------------ | ----------------------------------------------- |
| `shared-principles` | Princípios universais    | Clean Code, SOLID, Dependency Rule              |
| `frontend`          | Desenvolvimento UI       | Component Design, State Management, Performance |
| `backend`           | Desenvolvimento servidor | Domain Modeling, API Design, Data Persistence   |
| `devops-sre`        | Infraestrutura/Ops       | IaC, Deployment Patterns, Monitoring            |

### Fases SDD Suportadas

| Fase        | Foco Principal         | Princípios Adicionais                          |
| ----------- | ---------------------- | ---------------------------------------------- |
| `analyze`   | Avaliação arquitetural | Architecture Assessment, Pattern Applicability |
| `architect` | Design de sistema      | Design Consistency, Dependency Validation      |
| `implement` | Implementação          | Code Standards, Testing Coverage               |

### Cache e Performance

```bash
# Limpar cache (Bash)
./scripts/bash/knowledge-base-integration.sh clear-cache

# Limpar cache (PowerShell)
.\scripts\powershell\knowledge-base-integration.ps1 clear-cache
```

**Configurações de Cache:**

- **TTL**: 24 horas
- **Localização**: `.specify-cache/kb-queries/`
- **Formato**: JSON com hash SHA256

## 🧪 Testes e Validação

### Executar Testes Unitários

#### Bash

```bash
# Executar todos os testes
./scripts/tests/kb-integration-tests.sh run

# Ver ajuda
./scripts/tests/kb-integration-tests.sh help
```

#### PowerShell

```powershell
# Executar todos os testes
.\scripts\tests\kb-integration-tests.ps1 run

# Ver ajuda
.\scripts\tests\kb-integration-tests.ps1 help
```

### Cobertura de Testes

- ✅ **Validação de contexto**: 100%
- ✅ **Geração de cache**: 100%
- ✅ **Detecção de projeto**: 100%
- ✅ **Execução de queries**: 100%
- ✅ **Fallback gracioso**: 100%
- ✅ **Validação de padrões**: 100%
- ✅ **Operações de cache**: 100%
- ✅ **Workflow end-to-end**: 100%

## 🔍 Troubleshooting

### Problemas Comuns

#### 1. KB não encontrado

```
WARNING: Knowledge base not found at /path/to/memory/knowledge-base. Using fallback guidance.
```

**Solução**: Verificar se `memory/knowledge-base/` existe no repositório.

#### 2. Contexto inválido

```
ERROR: Invalid context 'invalid-context'. Valid: shared-principles, frontend, backend, devops-sre
```

**Solução**: Usar um dos contextos suportados listados.

#### 3. Timeout de query

```
WARNING: KB query timed out or failed. Using fallback guidance.
```

**Solução**: Verificar se arquivos KB não estão corrompidos. Timeout padrão: 10s.

#### 4. Cache corrompido

```bash
# Limpar cache e tentar novamente
./scripts/bash/knowledge-base-integration.sh clear-cache
```

### Logs e Debug

Para debug detalhado, definir variáveis de ambiente:

```bash
# Bash
export KB_DEBUG=1
export KB_VERBOSE=1

# PowerShell
$env:KB_DEBUG = "1"
$env:KB_VERBOSE = "1"
```

## 📊 Métricas de Performance

### Benchmarks Esperados

| Operação              | Tempo Esperado | Observações   |
| --------------------- | -------------- | ------------- |
| Query KB (cache miss) | < 2s           | 95% dos casos |
| Query KB (cache hit)  | < 100ms        | Após warm-up  |
| Validação de padrões  | < 1s           | Por arquivo   |
| Geração de relatório  | < 5s           | Fase completa |
| Criação de checkpoint | < 5s           | Com snapshots |

### Monitoramento

```bash
# Status detalhado do sistema
./scripts/bash/knowledge-base-integration.sh status

# Estatísticas de cache
ls -la .specify-cache/kb-queries/ | wc -l  # Número de entradas em cache
```

## 🔄 Integração com Workflow SDD

### Uso em Commands

O módulo KB pode ser integrado aos commands existentes:

```bash
# Em analyze.md
source scripts/bash/knowledge-base-integration.sh
principles=$(get_applicable_principles "analyze")
query_result=$(query_knowledge_base "shared-principles" "architecture patterns")
```

### Uso em Templates

```markdown
<!-- Em plan-template.md -->

## Conformidade Arquitetural

{KB_COMPLIANCE_CHECK}

## Princípios Aplicáveis

{KB_APPLICABLE_PRINCIPLES}
```

## 🚀 Próximos Passos

### Fase 1.2: Integração Commands (Próximas 2 semanas)

- Integração com `analyze.md`, `plan.md`, `implement.md`
- Validação KB obrigatória em commands
- Extensão do sistema de placeholders

### Fase 1.3: Validação e Testes (1 semana)

- Testes de integração completos
- Documentação de uso avançado
- Exemplos de consultas por contexto

## 📞 Suporte

Para problemas ou dúvidas:

1. **Verificar logs**: Executar com debug habilitado
2. **Executar testes**: Validar integridade do sistema
3. **Limpar cache**: Reset completo se necessário
4. **Consultar documentação**: Este guia e especificação técnica

---

_Guia do usuário para Knowledge Base Integration Module v1.0_  
_Parte do SDD v2.0 Critical Systems Implementation_
