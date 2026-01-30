#!/bin/bash
# =============================================================================
# Script para Acessar SigNoz
# =============================================================================
# Configura port-forward para acessar o dashboard do SigNoz
# =============================================================================

set -e

# Cores para output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

echo -e "${GREEN}========================================${NC}"
echo -e "${GREEN}  FIAP Tech Challenge - Access SigNoz${NC}"
echo -e "${GREEN}========================================${NC}"

SIGNOZ_NAMESPACE="${SIGNOZ_NAMESPACE:-signoz}"
LOCAL_PORT="${LOCAL_PORT:-3301}"

# -----------------------------------------------------------------------------
# Verificar se SigNoz esta rodando
# -----------------------------------------------------------------------------

echo -e "\n${YELLOW}Verificando pods do SigNoz...${NC}"

if ! kubectl get namespace "$SIGNOZ_NAMESPACE" &> /dev/null; then
    echo -e "${RED}Erro: Namespace '$SIGNOZ_NAMESPACE' nao encontrado.${NC}"
    echo "O SigNoz pode nao estar instalado."
    exit 1
fi

# Verificar se frontend esta rodando
FRONTEND_POD=$(kubectl get pods -n "$SIGNOZ_NAMESPACE" -l app.kubernetes.io/component=frontend -o jsonpath='{.items[0].metadata.name}' 2>/dev/null || true)

if [ -z "$FRONTEND_POD" ]; then
    echo -e "${RED}Erro: Pod do SigNoz frontend nao encontrado.${NC}"
    echo ""
    echo "Status dos pods:"
    kubectl get pods -n "$SIGNOZ_NAMESPACE"
    exit 1
fi

echo -e "${GREEN}SigNoz frontend encontrado: $FRONTEND_POD${NC}"

# -----------------------------------------------------------------------------
# Verificar se porta esta em uso
# -----------------------------------------------------------------------------

if lsof -Pi :$LOCAL_PORT -sTCP:LISTEN -t >/dev/null 2>&1; then
    echo -e "${YELLOW}Porta $LOCAL_PORT ja esta em uso. Tentando porta alternativa...${NC}"
    LOCAL_PORT=$((LOCAL_PORT + 1))
fi

# -----------------------------------------------------------------------------
# Iniciar port-forward
# -----------------------------------------------------------------------------

echo -e "\n${YELLOW}Iniciando port-forward...${NC}"
echo -e "${GREEN}SigNoz estara disponivel em: http://localhost:$LOCAL_PORT${NC}"
echo ""
echo "Pressione Ctrl+C para encerrar."
echo ""

kubectl port-forward -n "$SIGNOZ_NAMESPACE" svc/signoz-frontend $LOCAL_PORT:3301
