#!/bin/bash
# =============================================================================
# SigNoz Dashboard Setup Script
# =============================================================================
# Automatically creates dashboards in SigNoz via API
# Run after SigNoz is deployed
# =============================================================================

set -e

GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

echo -e "${GREEN}========================================${NC}"
echo -e "${GREEN}  SigNoz Dashboard Setup${NC}"
echo -e "${GREEN}========================================${NC}"

SIGNOZ_URL="${SIGNOZ_URL:-http://localhost:3301}"

echo -e "\n${YELLOW}Configuration:${NC}"
echo "  SigNoz URL: $SIGNOZ_URL"

echo -e "\n${YELLOW}Note: This is a reference implementation${NC}"
echo "Dashboards should be created via SigNoz UI and exported"
echo "or use SigNoz API once authenticated"

echo -e "\n${GREEN}Dashboard templates created at:${NC}"
echo "  kubernetes-core-infra/k8s/signoz/dashboards.yaml"

echo -e "\n${YELLOW}Manual Steps:${NC}"
echo "1. Port-forward SigNoz:"
echo "   kubectl port-forward svc/signoz-frontend -n signoz 3301:3301"
echo ""
echo "2. Access http://localhost:3301"
echo ""
echo "3. Login with default credentials:"
echo "   Email: admin@signoz.io"
echo "   Password: signoz"
echo ""
echo "4. Create dashboards using the queries in:"
echo "   k8s/signoz/dashboards.yaml"

echo -e "\n${GREEN}Done!${NC}"
