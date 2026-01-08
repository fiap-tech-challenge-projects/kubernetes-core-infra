# Kubernetes Core Infrastructure

Infraestrutura de Kubernetes (EKS) para o FIAP Tech Challenge - Fase 3.

## Visao Geral

Este repositorio contem a infraestrutura como codigo (IaC) para provisionar e gerenciar o cluster EKS na AWS, incluindo VPC, subnets, node groups, e addons como SigNoz para observabilidade.

### Arquitetura

```
                         +---------------------------+
                         |      AWS Cloud            |
                         |                           |
    +--------------------+---------------------------+--------------------+
    |                    |                           |                    |
    |   +-----------+    |    +---------------+      |    +-----------+   |
    |   |  Public   |    |    |    EKS        |      |    |  Private  |   |
    |   |  Subnet   |    |    |   Cluster     |      |    |  Subnet   |   |
    |   |           |    |    |               |      |    |           |   |
    |   | - ALB     |    |    | - API Server  |      |    | - Nodes   |   |
    |   | - NAT GW  |    |    | - etcd        |      |    | - Pods    |   |
    |   +-----------+    |    +---------------+      |    +-----------+   |
    |        |           |           |               |         |          |
    +--------+-----------+-----------+---------------+---------+----------+
             |                       |                         |
             v                       v                         v
    +------------------+   +------------------+     +------------------+
    | Internet Gateway |   |   CloudWatch     |     |      RDS         |
    |                  |   |   Logs           |     |   PostgreSQL     |
    +------------------+   +------------------+     +------------------+
```

## Recursos Provisionados

### VPC e Networking
- **VPC**: CIDR 10.0.0.0/16
- **Subnets Publicas**: 2x (para ALB)
- **Subnets Privadas**: 2x (para EKS nodes)
- **NAT Gateway**: 1x (economia para AWS Academy)
- **Internet Gateway**: 1x
- **VPC Endpoints**: S3, ECR (economia de NAT)

### EKS Cluster
- **Kubernetes Version**: 1.28
- **Node Group**: t3.medium (2-4 nodes)
- **Addons**: VPC CNI, CoreDNS, kube-proxy, EBS CSI Driver

### Observabilidade (SigNoz)
- **ClickHouse**: Backend de dados
- **Query Service**: Consultas
- **Frontend**: Dashboard web
- **OTel Collector**: Coleta de telemetria

### Seguranca
- **KMS**: Criptografia de secrets
- **OIDC Provider**: IRSA (IAM Roles for Service Accounts)
- **Security Groups**: Cluster e Nodes
- **Network Policies**: Controle de trafego

## Tecnologias

| Tecnologia | Versao | Descricao |
|------------|--------|-----------|
| Terraform | >= 1.5 | Infrastructure as Code |
| AWS EKS | 1.28 | Kubernetes gerenciado |
| Helm | 3.x | Package manager K8s |
| SigNoz | 0.32.0 | Observabilidade OpenTelemetry |
| AWS LB Controller | 1.6.2 | Ingress com ALB |

## Pre-requisitos

1. **AWS CLI** configurada com credenciais validas
2. **Terraform** >= 1.5.0 instalado
3. **kubectl** instalado
4. **Helm** >= 3.0 instalado
5. **Bucket S3** para Terraform state

## Configuracao do Backend

Antes do primeiro `terraform init`:

```bash
# Criar bucket S3 (se nao existir)
aws s3 mb s3://fiap-tech-challenge-tf-state-118735037876 --region us-east-1

# Habilitar versionamento
aws s3api put-bucket-versioning \
  --bucket fiap-tech-challenge-tf-state-118735037876 \
  --versioning-configuration Status=Enabled

# Criar tabela DynamoDB para locking
aws dynamodb create-table \
  --table-name fiap-terraform-locks \
  --attribute-definitions AttributeName=LockID,AttributeType=S \
  --key-schema AttributeName=LockID,KeyType=HASH \
  --billing-mode PAY_PER_REQUEST \
  --region us-east-1
```

## Deploy

### 1. Inicializar Terraform

```bash
cd terraform
terraform init
```

### 2. Revisar o plano

```bash
terraform plan
```

### 3. Aplicar a infraestrutura

```bash
terraform apply
```

### 4. Configurar kubectl

```bash
# Usar script
chmod +x scripts/configure-kubectl.sh
./scripts/configure-kubectl.sh

# Ou manualmente
aws eks update-kubeconfig --region us-east-1 --name fiap-tech-challenge-eks-development
```

### 5. Verificar cluster

```bash
kubectl get nodes
kubectl get pods -A
```

## Acessar SigNoz

```bash
# Usar script
./scripts/access-signoz.sh

# Ou manualmente
kubectl port-forward -n signoz svc/signoz-frontend 3301:3301

# Abrir no browser
open http://localhost:3301
```

## Variaveis de Configuracao

| Variavel | Descricao | Default |
|----------|-----------|---------|
| `aws_region` | Regiao AWS | `us-east-1` |
| `environment` | Ambiente | `development` |
| `kubernetes_version` | Versao K8s | `1.28` |
| `node_instance_types` | Tipos de instancia | `["t3.medium"]` |
| `node_desired_size` | Nodes desejados | `2` |
| `node_min_size` | Minimo de nodes | `1` |
| `node_max_size` | Maximo de nodes | `4` |
| `enable_signoz` | Instalar SigNoz | `true` |
| `enable_aws_lb_controller` | Instalar ALB Controller | `true` |

Ver `terraform/variables.tf` para lista completa.

## Outputs

```bash
# Nome do cluster
terraform output cluster_name

# Endpoint do cluster
terraform output cluster_endpoint

# Comando para configurar kubectl
terraform output kubeconfig_command

# Endpoint do SigNoz OTel Collector
terraform output signoz_otel_endpoint

# Resumo completo
terraform output summary
```

## Estrutura de Diretorios

```
kubernetes-core-infra/
├── terraform/
│   ├── main.tf                 # Provider e backend
│   ├── variables.tf            # Variaveis de entrada
│   ├── vpc.tf                  # VPC e networking
│   ├── iam.tf                  # IAM roles e policies
│   ├── eks.tf                  # Cluster EKS
│   ├── node-groups.tf          # Node groups
│   ├── addons.tf               # SigNoz, ALB Controller
│   ├── outputs.tf              # Outputs
│   ├── terraform.tfvars        # Valores das variaveis
│   └── policies/
│       └── aws-lb-controller-policy.json
├── k8s/
│   ├── base/
│   │   ├── namespace.yaml      # Namespace da app
│   │   ├── network-policies.yaml
│   │   └── resource-quotas.yaml
│   └── signoz/
│       └── otel-collector-config.yaml
├── scripts/
│   ├── configure-kubectl.sh    # Configurar kubectl
│   └── access-signoz.sh        # Acessar dashboard SigNoz
├── .github/
│   └── workflows/
│       └── terraform.yml       # CI/CD
└── README.md
```

## CI/CD

O pipeline do GitHub Actions executa:

1. **fmt**: Verifica formatacao do Terraform
2. **validate**: Valida a sintaxe
3. **plan**: Gera plano de execucao (comentario no PR)
4. **apply**: Aplica mudancas (apenas na branch main)

### Secrets necessarios no GitHub

- `AWS_ACCESS_KEY_ID`: Access Key da AWS
- `AWS_SECRET_ACCESS_KEY`: Secret Key da AWS

## Integracao com Outros Repositorios

### database-managed-infra
- Usa a VPC criada por este modulo
- Security Groups permitem acesso do EKS ao RDS

### k8s-main-service
- Deploya pods no cluster EKS
- Usa o namespace `ftc-app` criado aqui
- Envia telemetria para SigNoz

### lambda-api-handler
- Acessa o RDS na mesma VPC
- Integra com API Gateway

## Troubleshooting

### Erro ao criar cluster

```bash
# Verificar limites da conta AWS
aws service-quotas get-service-quota \
  --service-code eks \
  --quota-code L-1194D53C

# Verificar IAM roles
aws iam get-role --role-name fiap-tech-challenge-eks-cluster-role-development
```

### Nodes nao ficam Ready

```bash
# Verificar logs do node
kubectl describe node <node-name>

# Verificar security groups
aws ec2 describe-security-groups --group-ids <sg-id>
```

### SigNoz nao inicia

```bash
# Verificar PVCs
kubectl get pvc -n signoz

# Verificar logs
kubectl logs -n signoz -l app.kubernetes.io/component=clickhouse
```

## Cleanup

Para destruir toda a infraestrutura:

```bash
cd terraform
terraform destroy
```

**ATENCAO**: Isso ira deletar o cluster EKS e todos os recursos!

## Links Relacionados

- [FIAP Tech Challenge - Plano Fase 3](../PHASE-3-PLAN.md)
- [Database Infrastructure](../database-managed-infra)
- [K8s Main Service](../k8s-main-service)
- [Lambda API Handler](../lambda-api-handler)

## Equipe

- Ana Shurman
- Franklin Campos
- Rafael Lima (Finha)
- Bruna Euzane

---

**FIAP Pos-Graduacao em Arquitetura de Software - Tech Challenge Fase 3**
