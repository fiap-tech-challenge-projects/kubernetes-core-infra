#!/bin/bash
# =============================================================================
# Script para Configurar kubectl
# =============================================================================
# Configura o kubectl para acessar o cluster EKS
# =============================================================================

set -e

# Cores para output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

echo -e "${GREEN}========================================${NC}"
echo -e "${GREEN}  FIAP Tech Challenge - Configure kubectl${NC}"
echo -e "${GREEN}========================================${NC}"

# -----------------------------------------------------------------------------
# Configuracao
# -----------------------------------------------------------------------------

AWS_REGION="${AWS_REGION:-us-east-1}"
ENVIRONMENT="${ENVIRONMENT:-staging}"
CLUSTER_NAME="${CLUSTER_NAME:-fiap-tech-challenge-eks-${ENVIRONMENT}}"
APP_NAMESPACE="ftc-app-${ENVIRONMENT}"

echo -e "\n${YELLOW}Configuracao:${NC}"
echo "  AWS Region: $AWS_REGION"
echo "  Environment: $ENVIRONMENT"
echo "  Cluster Name: $CLUSTER_NAME"
echo "  App Namespace: $APP_NAMESPACE"

# -----------------------------------------------------------------------------
# Verificar pre-requisitos
# -----------------------------------------------------------------------------

echo -e "\n${YELLOW}Verificando pre-requisitos...${NC}"

# Verificar AWS CLI
if ! command -v aws &> /dev/null; then
    echo -e "${RED}Erro: AWS CLI nao encontrado.${NC}"
    echo "Instale com: brew install awscli"
    exit 1
fi

# Verificar kubectl
if ! command -v kubectl &> /dev/null; then
    echo -e "${RED}Erro: kubectl nao encontrado.${NC}"
    echo "Instale com: brew install kubectl"
    exit 1
fi

# Verificar credenciais AWS
if ! aws sts get-caller-identity &> /dev/null; then
    echo -e "${RED}Erro: Credenciais AWS nao configuradas.${NC}"
    echo "Configure com: aws configure"
    exit 1
fi

echo -e "${GREEN}Pre-requisitos OK!${NC}"

# -----------------------------------------------------------------------------
# Verificar se cluster existe
# -----------------------------------------------------------------------------

echo -e "\n${YELLOW}Verificando cluster EKS...${NC}"

if ! aws eks describe-cluster --name "$CLUSTER_NAME" --region "$AWS_REGION" &> /dev/null; then
    echo -e "${RED}Erro: Cluster '$CLUSTER_NAME' nao encontrado na regiao '$AWS_REGION'.${NC}"
    echo ""
    echo "Clusters disponiveis:"
    aws eks list-clusters --region "$AWS_REGION" --query 'clusters[]' --output table
    exit 1
fi

echo -e "${GREEN}Cluster encontrado!${NC}"

# -----------------------------------------------------------------------------
# Configurar kubectl
# -----------------------------------------------------------------------------

echo -e "\n${YELLOW}Configurando kubectl...${NC}"

aws eks update-kubeconfig \
    --region "$AWS_REGION" \
    --name "$CLUSTER_NAME"

echo -e "${GREEN}kubectl configurado com sucesso!${NC}"

# -----------------------------------------------------------------------------
# Verificar conexao
# -----------------------------------------------------------------------------

echo -e "\n${YELLOW}Verificando conexao com o cluster...${NC}"

if kubectl cluster-info &> /dev/null; then
    echo -e "${GREEN}Conexao OK!${NC}"
    echo ""
    kubectl cluster-info
else
    echo -e "${RED}Erro ao conectar ao cluster.${NC}"
    exit 1
fi

# -----------------------------------------------------------------------------
# Mostrar informacoes
# -----------------------------------------------------------------------------

echo -e "\n${GREEN}========================================${NC}"
echo -e "${GREEN}  Configuracao Completa!${NC}"
echo -e "${GREEN}========================================${NC}"

echo -e "\n${YELLOW}Nodes do cluster:${NC}"
kubectl get nodes

echo -e "\n${YELLOW}Namespaces:${NC}"
kubectl get namespaces

echo -e "\n${YELLOW}Comandos uteis:${NC}"
echo "  kubectl get pods -n $APP_NAMESPACE        # Ver pods da aplicacao"
echo "  kubectl get pods -n signoz                # Ver pods do SigNoz"
echo "  kubectl logs -f <pod> -n $APP_NAMESPACE   # Ver logs de um pod"
echo "  kubectl port-forward -n signoz svc/signoz-frontend 3301:3301  # Acessar SigNoz"
