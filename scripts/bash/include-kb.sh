#!/usr/bin/env bash
# Helper para carregar o módulo de Integração da Knowledge Base
# Funciona tanto no repo de desenvolvimento (scripts/...) quanto no pacote (.specify/scripts/...)

set -euo pipefail

KB_CANDIDATES=(
  ".specify/scripts/bash/knowledge-base-integration.sh"
  "scripts/bash/knowledge-base-integration.sh"
)

FOUND=""
for kb_path in "${KB_CANDIDATES[@]}"; do
  if [[ -f "$kb_path" ]]; then
    # shellcheck source=/dev/null
    source "$kb_path"
    FOUND="$kb_path"
    export SPECIFY_KB_MODULE="$kb_path"
    break
  fi
done

if [[ -z "$FOUND" ]]; then
  echo "[specify] ERROR: Não encontrei knowledge-base-integration.sh nos caminhos esperados: ${KB_CANDIDATES[*]}" >&2
  # Permite funcionar mesmo se script for 'source' ou executado diretamente
  return 1 2>/dev/null || exit 1
fi

# Verificação básica das funções esperadas
for fn in query_knowledge_base get_applicable_principles generate_compliance_report; do
  if ! declare -f "$fn" >/dev/null 2>&1; then
    echo "[specify] ERROR: Função obrigatória ausente após source: $fn" >&2
    return 1 2>/dev/null || exit 1
  fi
done

export SPECIFY_KB_LOADED=1
