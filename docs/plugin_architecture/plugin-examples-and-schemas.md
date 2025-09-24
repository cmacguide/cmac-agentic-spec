# Plugin Examples and Validation Schemas

## 📋 Metadados do Documento

| Campo               | Valor                                  |
| ------------------- | -------------------------------------- |
| **Data de Criação** | 24 de Setembro de 2025                 |
| **Versão**          | 1.0                                    |
| **Complementa**     | docs/plugin-architecture-foundation.md |
| **Tipo**            | Exemplos Práticos e Esquemas           |

---

## 🔌 Exemplos Práticos de Plugins

### Exemplo 1: Plugin Claude (CLI-based, Markdown)

#### Estrutura de Diretórios

```
plugins/core/claude/
├── plugin.yaml                 # Configuração principal
├── commands/                   # Templates de comandos
│   ├── specify.md
│   ├── plan.md
│   ├── implement.md
│   ├── clarify.md
│   └── analyze.md
├── templates/                  # Templates de projeto
│   └── project-template/
│       ├── .claude/
│       └── scripts/
├── hooks/                      # Hooks de ciclo de vida
│   ├── init.py
│   ├── validate.py
│   └── post_install.py
└── validators/                 # Validadores específicos
    └── cli_validator.py
```

#### plugin.yaml Completo

```yaml
# Plugin Metadata
name: "claude"
display_name: "Claude Code"
version: "1.0.0"
description: "Anthropic's Claude Code CLI integration for Spec-Driven Development"
author: "GitHub Spec Kit Team"
license: "MIT"
homepage: "https://docs.anthropic.com/en/docs/claude-code/setup"
repository: "https://github.com/github/spec-kit"

# Compatibility
specify_version: ">=2.0.0"
python_version: ">=3.11"
platforms: ["linux", "macos", "windows"]

# Agent Configuration
agent:
  type: "cli"
  category: "code_generation"
  cli_tool: "claude"
  cli_check_args: ["--version"]
  cli_min_version: "1.0.0"

# Directory Structure
directories:
  base: ".claude"
  commands: ".claude/commands"
  rules: ".claude/rules"
  templates: ".claude/templates"

# Command Configuration
commands:
  format: "markdown"
  extension: ".md"
  argument_pattern: "$ARGUMENTS"
  script_pattern: "{SCRIPT}"
  agent_pattern: "__AGENT__"

# Dependencies
dependencies:
  system:
    - name: "claude"
      type: "cli"
      required: true
      install_url: "https://docs.anthropic.com/en/docs/claude-code/setup"
      check_command: ["claude", "--version"]
  python:
    - name: "pyyaml"
      version: ">=6.0"
    - name: "pathlib"
      version: ">=1.0"

# Hooks
hooks:
  init: "hooks/init.py"
  validate: "hooks/validate.py"
  post_install: "hooks/post_install.py"
  cleanup: "hooks/cleanup.py"

# Security
security:
  sandbox: true
  network_access: false
  file_system_access: "restricted"
  allowed_paths:
    - ".claude/"
    - ".specify/"
    - "memory/"
    - "specs/"
  max_execution_time: 30
  max_memory_mb: 256

# Templates
templates:
  - name: "specify"
    path: "commands/specify.md"
    description: "Create specifications"
    required: true
  - name: "plan"
    path: "commands/plan.md"
    description: "Generate implementation plans"
    required: true
  - name: "implement"
    path: "commands/implement.md"
    description: "Execute implementation"
    required: true
  - name: "clarify"
    path: "commands/clarify.md"
    description: "Clarify requirements"
    required: false
  - name: "analyze"
    path: "commands/analyze.md"
    description: "Analyze consistency"
    required: false

# Validation Rules
validation:
  required_files:
    - "commands/specify.md"
    - "commands/plan.md"
    - "commands/implement.md"
  optional_files:
    - "commands/clarify.md"
    - "commands/analyze.md"
    - "commands/constitution.md"
  file_patterns:
    - "*.md"
    - "*.py"
  max_file_size_mb: 10
  allowed_extensions: [".md", ".py", ".yaml", ".yml", ".txt"]

# Metadata for marketplace
marketplace:
  tags: ["cli", "anthropic", "code-generation", "ai-assistant"]
  category: "AI Assistants"
  maturity: "stable"
  support_level: "official"
```

#### Exemplo de Comando: specify.md

````markdown
---
description: "Create comprehensive specifications for your project features"
version: "1.0.0"
author: "GitHub Spec Kit Team"
---

# /specify - Create Specifications

You are an expert product manager and technical architect. Your role is to help create comprehensive, actionable specifications for software features.

## Context

You are working in a Spec-Driven Development environment where:

- Specifications drive implementation
- Clear requirements prevent scope creep
- Technical decisions are documented and justified

## Your Task

Create a detailed specification document that includes:

1. **Feature Overview**

   - Clear description of what we're building
   - Business value and user impact
   - Success criteria

2. **Functional Requirements**

   - User stories with acceptance criteria
   - Edge cases and error handling
   - Integration requirements

3. **Technical Requirements**

   - Performance requirements
   - Security considerations
   - Scalability needs

4. **Implementation Considerations**
   - Technology recommendations
   - Architecture patterns
   - Dependencies and constraints

## Instructions

1. Ask clarifying questions if the requirements are unclear
2. Use the project constitution (if available) to guide decisions
3. Create specifications that are:
   - Testable and measurable
   - Implementation-agnostic where possible
   - Clear and unambiguous

## Input

User request: $ARGUMENTS

## Output Format

Create a specification document in the `specs/` directory following the template structure.

## Available Scripts

You can run the following script to update agent context:

```bash
{SCRIPT}
```
````

## Agent Context

Current agent: **AGENT**
Project type: Spec-Driven Development

````

#### Exemplo de Hook: init.py
```python
#!/usr/bin/env python3
"""
Claude Plugin Initialization Hook
Executes when the plugin is first loaded for a project.
"""

import os
import sys
from pathlib import Path
import logging

# Setup logging
logging.basicConfig(level=logging.INFO)
logger = logging.getLogger(__name__)

def main():
    """Initialize Claude plugin for project."""
    try:
        project_path = Path(os.environ.get('SPECIFY_PROJECT_PATH', '.'))
        plugin_name = os.environ.get('SPECIFY_PLUGIN_NAME', 'claude')

        logger.info(f"Initializing {plugin_name} plugin for project: {project_path}")

        # Create necessary directories
        claude_dir = project_path / '.claude'
        claude_dir.mkdir(exist_ok=True)

        (claude_dir / 'commands').mkdir(exist_ok=True)
        (claude_dir / 'rules').mkdir(exist_ok=True)

        # Create rules file
        rules_file = claude_dir / 'rules' / 'specify-rules.md'
        if not rules_file.exists():
            create_rules_file(rules_file)

        logger.info("Claude plugin initialized successfully")
        return True

    except Exception as e:
        logger.error(f"Failed to initialize Claude plugin: {e}")
        return False

def create_rules_file(rules_file: Path):
    """Create the specify rules file for Claude."""
    content = """# Specify Rules for Claude Code

## Project Context
This project uses Spec-Driven Development (SDD) methodology.

## Available Commands
- `/specify` - Create specifications
- `/plan` - Generate implementation plans
- `/implement` - Execute implementation
- `/clarify` - Clarify requirements
- `/analyze` - Analyze consistency

## Guidelines
1. Always start with specifications before implementation
2. Use the project constitution to guide decisions
3. Create testable and measurable requirements
4. Document technical decisions and rationale

## File Structure
- `specs/` - Specification documents
- `plans/` - Implementation plans
- `tasks/` - Task breakdowns
- `memory/` - Project memory and context
"""

    rules_file.write_text(content, encoding='utf-8')

if __name__ == '__main__':
    success = main()
    sys.exit(0 if success else 1)
````

### Exemplo 2: Plugin Gemini (CLI-based, TOML)

#### plugin.yaml

```yaml
name: "gemini"
display_name: "Gemini CLI"
version: "1.0.0"
description: "Google's Gemini CLI integration"
author: "GitHub Spec Kit Team"

agent:
  type: "cli"
  cli_tool: "gemini"

directories:
  base: ".gemini"
  commands: ".gemini/commands"

commands:
  format: "toml"
  extension: ".toml"
  argument_pattern: "{{args}}"
  script_pattern: "{script}"

dependencies:
  system:
    - name: "gemini"
      type: "cli"
      required: true
      install_url: "https://github.com/google-gemini/gemini-cli"

security:
  sandbox: true
  network_access: false
  file_system_access: "restricted"
  allowed_paths:
    - ".gemini/"
    - ".specify/"
```

#### Exemplo de Comando: specify.toml

```toml
description = "Create comprehensive specifications using Gemini CLI"
version = "1.0.0"

prompt = """
You are an expert product manager and technical architect working with Gemini CLI.

Create a detailed specification for: {{args}}

Follow these guidelines:
1. Start with clear feature overview
2. Define functional requirements with user stories
3. Specify technical requirements
4. Include implementation considerations

Use the project constitution and run: {script}

Output the specification to the specs/ directory.
"""

[metadata]
author = "GitHub Spec Kit Team"
category = "specification"
```

### Exemplo 3: Plugin Copilot (IDE-based, Markdown)

#### plugin.yaml

```yaml
name: "copilot"
display_name: "GitHub Copilot"
version: "1.0.0"
description: "GitHub Copilot integration for VS Code"
author: "GitHub Spec Kit Team"

agent:
  type: "ide"
  category: "code_generation"

directories:
  base: ".github"
  commands: ".github/prompts"

commands:
  format: "markdown"
  extension: ".md"
  argument_pattern: "$ARGUMENTS"

dependencies:
  system: [] # IDE-based, no CLI tool required

security:
  sandbox: false # IDE-based plugins have different security model
  network_access: true
  file_system_access: "full"
```

---

## 📋 Esquemas de Validação

### Schema para plugin.yaml

```yaml
# JSON Schema for plugin.yaml validation
$schema: "http://json-schema.org/draft-07/schema#"
title: "Specify Plugin Configuration"
type: "object"
required: ["name", "display_name", "version", "description", "author", "agent"]

properties:
  # Basic Metadata
  name:
    type: "string"
    pattern: "^[a-z][a-z0-9_-]*$"
    description: "Plugin identifier (snake_case)"

  display_name:
    type: "string"
    minLength: 1
    maxLength: 50
    description: "Human-readable plugin name"

  version:
    type: "string"
    pattern: "^\\d+\\.\\d+\\.\\d+(-[a-zA-Z0-9.-]+)?$"
    description: "Semantic version"

  description:
    type: "string"
    minLength: 10
    maxLength: 200
    description: "Plugin description"

  author:
    type: "string"
    minLength: 1
    description: "Plugin author"

  license:
    type: "string"
    enum: ["MIT", "Apache-2.0", "GPL-3.0", "BSD-3-Clause", "ISC"]
    default: "MIT"

  homepage:
    type: "string"
    format: "uri"

  repository:
    type: "string"
    format: "uri"

  # Compatibility
  specify_version:
    type: "string"
    pattern: "^[><=!~^]*\\d+\\.\\d+\\.\\d+"
    description: "Compatible Specify CLI version"

  python_version:
    type: "string"
    pattern: "^[><=!~^]*\\d+\\.\\d+"
    description: "Required Python version"

  platforms:
    type: "array"
    items:
      type: "string"
      enum: ["linux", "macos", "windows"]
    minItems: 1

  # Agent Configuration
  agent:
    type: "object"
    required: ["type"]
    properties:
      type:
        type: "string"
        enum: ["cli", "ide", "hybrid"]

      category:
        type: "string"
        enum: ["code_generation", "planning", "analysis", "documentation"]

      cli_tool:
        type: "string"
        description: "CLI tool name (required for cli type)"

      cli_check_args:
        type: "array"
        items:
          type: "string"
        description: "Arguments to check CLI tool installation"

      cli_min_version:
        type: "string"
        pattern: "^\\d+\\.\\d+\\.\\d+"

  # Directory Structure
  directories:
    type: "object"
    required: ["base"]
    properties:
      base:
        type: "string"
        pattern: "^\\.[a-z][a-z0-9_-]*$"

      commands:
        type: "string"

      rules:
        type: "string"

      templates:
        type: "string"

  # Command Configuration
  commands:
    type: "object"
    required: ["format", "extension"]
    properties:
      format:
        type: "string"
        enum: ["markdown", "toml", "json", "yaml"]

      extension:
        type: "string"
        pattern: "^\\.[a-z0-9]+$"

      argument_pattern:
        type: "string"
        description: "Pattern for argument substitution"

      script_pattern:
        type: "string"
        description: "Pattern for script path substitution"

      agent_pattern:
        type: "string"
        description: "Pattern for agent name substitution"

  # Dependencies
  dependencies:
    type: "object"
    properties:
      system:
        type: "array"
        items:
          type: "object"
          required: ["name", "type", "required"]
          properties:
            name:
              type: "string"
            type:
              type: "string"
              enum: ["cli", "library", "service"]
            required:
              type: "boolean"
            install_url:
              type: "string"
              format: "uri"
            check_command:
              type: "array"
              items:
                type: "string"

      python:
        type: "array"
        items:
          type: "object"
          required: ["name"]
          properties:
            name:
              type: "string"
            version:
              type: "string"

  # Security
  security:
    type: "object"
    properties:
      sandbox:
        type: "boolean"
        default: true

      network_access:
        type: "boolean"
        default: false

      file_system_access:
        type: "string"
        enum: ["none", "restricted", "full"]
        default: "restricted"

      allowed_paths:
        type: "array"
        items:
          type: "string"

      max_execution_time:
        type: "integer"
        minimum: 1
        maximum: 300
        default: 30

      max_memory_mb:
        type: "integer"
        minimum: 64
        maximum: 1024
        default: 256

  # Templates
  templates:
    type: "array"
    items:
      type: "object"
      required: ["name", "path", "description"]
      properties:
        name:
          type: "string"
          pattern: "^[a-z][a-z0-9_]*$"

        path:
          type: "string"

        description:
          type: "string"

        required:
          type: "boolean"
          default: false

  # Validation Rules
  validation:
    type: "object"
    properties:
      required_files:
        type: "array"
        items:
          type: "string"

      optional_files:
        type: "array"
        items:
          type: "string"

      file_patterns:
        type: "array"
        items:
          type: "string"

      max_file_size_mb:
        type: "integer"
        minimum: 1
        maximum: 100
        default: 10

      allowed_extensions:
        type: "array"
        items:
          type: "string"
          pattern: "^\\.[a-z0-9]+$"

  # Marketplace Metadata
  marketplace:
    type: "object"
    properties:
      tags:
        type: "array"
        items:
          type: "string"
        maxItems: 10

      category:
        type: "string"
        enum:
          [
            "AI Assistants",
            "Code Generators",
            "Planning Tools",
            "Analysis Tools",
          ]

      maturity:
        type: "string"
        enum: ["experimental", "beta", "stable", "mature"]
        default: "beta"

      support_level:
        type: "string"
        enum: ["community", "supported", "official"]
        default: "community"

# Conditional requirements
allOf:
  - if:
      properties:
        agent:
          properties:
            type:
              const: "cli"
    then:
      properties:
        agent:
          required: ["cli_tool"]

  - if:
      properties:
        security:
          properties:
            sandbox:
              const: true
    then:
      properties:
        security:
          required: ["file_system_access", "allowed_paths"]
```

### Schema para Command Templates

```yaml
# Schema for command template validation
$schema: "http://json-schema.org/draft-07/schema#"
title: "Plugin Command Template"
type: "object"

properties:
  # For Markdown templates
  frontmatter:
    type: "object"
    properties:
      description:
        type: "string"
        minLength: 10
        maxLength: 200

      version:
        type: "string"
        pattern: "^\\d+\\.\\d+\\.\\d+$"

      author:
        type: "string"

      category:
        type: "string"
        enum: ["specification", "planning", "implementation", "analysis"]

      required_args:
        type: "boolean"
        default: false

      min_args:
        type: "integer"
        minimum: 0

      max_args:
        type: "integer"
        minimum: 1

  content:
    type: "string"
    minLength: 100
    description: "Template content with placeholders"

required: ["frontmatter", "content"]

# Validation for placeholder patterns
patternProperties:
  ".*\\$ARGUMENTS.*":
    description: "Must contain argument placeholder"
  ".*\\{SCRIPT\\}.*":
    description: "Must contain script placeholder"
  ".*__AGENT__.*":
    description: "Must contain agent placeholder"
```

---

## 🛠️ Processo de Desenvolvimento de Plugins

### 1. Planejamento do Plugin

#### Checklist de Planejamento

- [ ] Definir tipo de agente (CLI/IDE/Hybrid)
- [ ] Identificar dependências do sistema
- [ ] Definir estrutura de comandos
- [ ] Planejar requisitos de segurança
- [ ] Documentar casos de uso

#### Template de Proposta

```markdown
# Proposta de Plugin: [Nome do Plugin]

## Visão Geral

- **Nome**: [nome-do-plugin]
- **Tipo**: [cli/ide/hybrid]
- **Categoria**: [code_generation/planning/analysis]
- **Autor**: [seu-nome]

## Justificativa

Por que este plugin é necessário?

## Funcionalidades

- Funcionalidade 1
- Funcionalidade 2
- Funcionalidade 3

## Dependências

- Sistema: [ferramentas necessárias]
- Python: [bibliotecas necessárias]

## Segurança

- Sandbox: [sim/não]
- Acesso à rede: [sim/não]
- Acesso ao sistema de arquivos: [none/restricted/full]

## Cronograma

- Semana 1: [tarefas]
- Semana 2: [tarefas]
- Semana 3: [tarefas]
```

### 2. Implementação do Plugin

#### Estrutura Mínima

```
meu-plugin/
├── plugin.yaml              # Configuração obrigatória
├── commands/                 # Templates de comandos
│   ├── specify.md           # Comando obrigatório
│   ├── plan.md              # Comando obrigatório
│   └── implement.md         # Comando obrigatório
├── hooks/                    # Hooks opcionais
│   ├── init.py
│   └── validate.py
└── README.md                 # Documentação
```

#### Passos de Implementação

1. **Criar plugin.yaml**

   ```bash
   # Usar template base
   cp templates/plugin-template.yaml meu-plugin/plugin.yaml
   # Editar configurações específicas
   ```

2. **Implementar comandos obrigatórios**

   - `specify.md` - Criação de especificações
   - `plan.md` - Geração de planos
   - `implement.md` - Execução de implementação

3. **Adicionar hooks (opcional)**

   - `init.py` - Inicialização do plugin
   - `validate.py` - Validação de ambiente
   - `post_install.py` - Pós-instalação
   - `cleanup.py` - Limpeza

4. **Implementar validadores (opcional)**
   - Validação de CLI tools
   - Verificação de dependências
   - Testes de compatibilidade

### 3. Validação e Testes

#### Validação Automática

```bash
# Validar estrutura do plugin
specify plugin validate meu-plugin/

# Validar segurança
specify plugin security-check meu-plugin/

# Testar compatibilidade
specify plugin test-compatibility meu-plugin/
```

#### Testes Manuais

```bash
# Testar instalação
specify plugin install meu-plugin/

# Testar em projeto novo
specify init test-project --plugin meu-plugin

# Testar comandos
cd test-project
/specify "criar uma API REST"
/plan
/implement
```

#### Checklist de Qualidade

- [ ] Plugin.yaml válido segundo schema
- [ ] Comandos obrigatórios implementados
- [ ] Hooks funcionam corretamente
- [ ] Validação de segurança passa
- [ ] Testes de compatibilidade passam
- [ ] Documentação completa
- [ ] Exemplos de uso funcionais

### 4. Publicação e Distribuição

#### Para Plugins Core

1. Criar PR no repositório principal
2. Review de código e arquitetura
3. Testes de integração
4. Merge e release

#### Para Plugins da Comunidade

1. Publicar em repositório próprio
2. Registrar no marketplace
3. Submeter para review da comunidade
4. Manter e atualizar

#### Versionamento

- Seguir Semantic Versioning (SemVer)
- Documentar breaking changes
- Manter compatibilidade quando possível
- Testar migrações entre versões

---

## 📚 Recursos para Desenvolvedores

### Templates Disponíveis

#### Template Base de Plugin

```yaml
name: "meu-plugin"
display_name: "Meu Plugin"
version: "0.1.0"
description: "Descrição do meu plugin"
author: "Meu Nome"
license: "MIT"

specify_version: ">=2.0.0"
python_version: ">=3.11"
platforms: ["linux", "macos", "windows"]

agent:
  type: "cli" # ou "ide" ou "hybrid"
  category: "code_generation"
  cli_tool: "minha-ferramenta"

directories:
  base: ".meu-plugin"
  commands: ".meu-plugin/commands"

commands:
  format: "markdown"
  extension: ".md"
  argument_pattern: "$ARGUMENTS"

dependencies:
  system:
    - name: "minha-ferramenta"
      type: "cli"
      required: true
      install_url: "https://exemplo.com/install"

security:
  sandbox: true
  network_access: false
  file_system_access: "restricted"
  allowed_paths:
    - ".meu-plugin/"
    - ".specify/"

templates:
  - name: "specify"
    path: "commands/specify.md"
    description: "Create specifications"
    required: true
```

#### Template de Comando

````markdown
---
description: "Descrição do comando"
version: "1.0.0"
author: "Meu Nome"
category: "specification"
---

# /comando - Descrição do Comando

Você é um especialista em [área]. Sua função é [objetivo].

## Contexto

Você está trabalhando em um ambiente Spec-Driven Development onde:

- [contexto 1]
- [contexto 2]
- [contexto 3]

## Sua Tarefa

[Descrição detalhada da tarefa]

## Instruções

1. [Instrução 1]
2. [Instrução 2]
3. [Instrução 3]

## Input

Solicitação do usuário: $ARGUMENTS

## Output

[Formato esperado do output]

## Scripts Disponíveis

```bash
{SCRIPT}
```
````

## Contexto do Agente

Agente atual: **AGENT**
Tipo de projeto: Spec-Driven Development

````

### Ferramentas de Desenvolvimento

#### CLI para Desenvolvimento de Plugins
```bash
# Criar novo plugin
specify plugin create meu-plugin --type cli

# Validar plugin
specify plugin validate meu-plugin/

# Testar plugin
specify plugin test meu-plugin/

# Empacotar plugin
specify plugin package meu-plugin/

# Publicar plugin
specify plugin publish meu-plugin/
````

#### Debugging e Logs

```python
# Em hooks Python
import logging
logger = logging.getLogger('specify.plugin.meu-plugin')

logger.info("Plugin inicializado")
logger.warning("Aviso sobre configuração")
logger.error("Erro durante execução")
```

### Melhores Práticas

#### Segurança

- Sempre usar sandbox quando possível
- Minimizar acesso ao sistema de arquivos
- Validar todas as entradas do usuário
- Não armazenar credenciais em código

#### Performance

- Manter hooks rápidos (< 5 segundos)
- Usar cache quando apropriado
- Minimizar dependências externas
- Otimizar templates para velocidade

#### Manutenibilidade

- Documentar todas as funcionalidades
- Usar nomes descritivos
- Seguir convenções de nomenclatura
- Manter compatibilidade com versões anteriores

#### Usabilidade

- Fornecer mensagens de erro claras
- Incluir exemplos de uso
- Documentar casos de uso comuns
- Testar com usuários reais

---

## 🔮 Roadmap de Funcionalidades Futuras

### Fase 2: Marketplace e API (Meses 5-8)

#### Plugin Marketplace

- Interface web para descoberta de plugins
- Sistema de ratings e reviews
- Instalação automática via CLI
- Verificação de segurança automatizada

#### API Externa

- REST API para gerenciamento de plugins
- Webhooks para atualizações
- SDK para desenvolvimento
- Integração com IDEs

### Fase 3: Funcionalidades Avançadas (Meses 9-12)

#### Plugin Composition

- Combinação de múltiplos plugins
- Pipelines de processamento
- Dependências entre plugins
- Orquestração automática

#### AI-Powered Plugin Development

- Geração automática de plugins
- Otimização baseada em uso
- Sugestões de melhorias
- Detecção de padrões

---

_Documento criado em: 24 de Setembro de 2025_  
_Versão: 1.0_  
_Complementa: docs/plugin-architecture-foundation.md_
