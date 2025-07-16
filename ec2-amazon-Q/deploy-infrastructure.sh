#!/bin/bash

# Deploy da infraestrutura EC2 + RDS PostgreSQL
# Autor: Amazon Q
# Data: $(date)

set -e

echo "🚀 Iniciando deploy da infraestrutura EC2 + RDS PostgreSQL..."

# Configurações
REGION="us-east-1"
KEY_NAME="ec2-amazon-q-key"
INSTANCE_NAME="ec2-amazon-Q"
DB_NAME="ec2-amazon-q-db"
VPC_NAME="ec2-amazon-q-vpc"

# Cores para output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

echo_info() {
    echo -e "${GREEN}[INFO]${NC} $1"
}

echo_warn() {
    echo -e "${YELLOW}[WARN]${NC} $1"
}

echo_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Verificar se AWS CLI está configurado
if ! aws sts get-caller-identity &>/dev/null; then
    echo_error "AWS CLI não está configurado. Execute 'aws configure' primeiro."
    exit 1
fi

echo_info "Usando região: $REGION"

# 1. Criar Key Pair se não existir
echo_info "Criando Key Pair..."
if ! aws ec2 describe-key-pairs --key-names $KEY_NAME --region $REGION &>/dev/null; then
    aws ec2 create-key-pair \
        --key-name $KEY_NAME \
        --region $REGION \
        --query 'KeyMaterial' \
        --output text > ${KEY_NAME}.pem
    chmod 400 ${KEY_NAME}.pem
    echo_info "Key Pair criado: ${KEY_NAME}.pem"
else
    echo_warn "Key Pair $KEY_NAME já existe"
fi

# 2. Obter VPC padrão
echo_info "Obtendo VPC padrão..."
VPC_ID=$(aws ec2 describe-vpcs \
    --filters "Name=is-default,Values=true" \
    --region $REGION \
    --query 'Vpcs[0].VpcId' \
    --output text)

if [ "$VPC_ID" = "None" ] || [ -z "$VPC_ID" ]; then
    echo_error "VPC padrão não encontrada. Criando nova VPC..."
    # Criar VPC se não existir
    VPC_ID=$(aws ec2 create-vpc \
        --cidr-block 10.0.0.0/16 \
        --region $REGION \
        --query 'Vpc.VpcId' \
        --output text)
    
    aws ec2 create-tags \
        --resources $VPC_ID \
        --tags Key=Name,Value=$VPC_NAME \
        --region $REGION
    
    echo_info "VPC criada: $VPC_ID"
else
    echo_info "Usando VPC padrão: $VPC_ID"
fi

# 3. Obter subnets
echo_info "Obtendo subnets..."
SUBNET_IDS=$(aws ec2 describe-subnets \
    --filters "Name=vpc-id,Values=$VPC_ID" \
    --region $REGION \
    --query 'Subnets[*].SubnetId' \
    --output text)

if [ -z "$SUBNET_IDS" ]; then
    echo_error "Nenhuma subnet encontrada na VPC $VPC_ID"
    exit 1
fi

SUBNET_ID=$(echo $SUBNET_IDS | cut -d' ' -f1)
echo_info "Usando subnet: $SUBNET_ID"

# 4. Criar Security Group para EC2
echo_info "Criando Security Group para EC2..."
EC2_SG_ID=$(aws ec2 create-security-group \
    --group-name ec2-amazon-q-sg \
    --description "Security Group para EC2 Amazon Q" \
    --vpc-id $VPC_ID \
    --region $REGION \
    --query 'GroupId' \
    --output text 2>/dev/null || \
    aws ec2 describe-security-groups \
        --filters "Name=group-name,Values=ec2-amazon-q-sg" "Name=vpc-id,Values=$VPC_ID" \
        --region $REGION \
        --query 'SecurityGroups[0].GroupId' \
        --output text)

# Adicionar regras ao Security Group da EC2
aws ec2 authorize-security-group-ingress \
    --group-id $EC2_SG_ID \
    --protocol tcp \
    --port 22 \
    --cidr 0.0.0.0/0 \
    --region $REGION 2>/dev/null || true

aws ec2 authorize-security-group-ingress \
    --group-id $EC2_SG_ID \
    --protocol tcp \
    --port 80 \
    --cidr 0.0.0.0/0 \
    --region $REGION 2>/dev/null || true

aws ec2 authorize-security-group-ingress \
    --group-id $EC2_SG_ID \
    --protocol tcp \
    --port 443 \
    --cidr 0.0.0.0/0 \
    --region $REGION 2>/dev/null || true

echo_info "Security Group EC2 criado: $EC2_SG_ID"

# 5. Criar Security Group para RDS
echo_info "Criando Security Group para RDS..."
RDS_SG_ID=$(aws ec2 create-security-group \
    --group-name rds-amazon-q-sg \
    --description "Security Group para RDS Amazon Q" \
    --vpc-id $VPC_ID \
    --region $REGION \
    --query 'GroupId' \
    --output text 2>/dev/null || \
    aws ec2 describe-security-groups \
        --filters "Name=group-name,Values=rds-amazon-q-sg" "Name=vpc-id,Values=$VPC_ID" \
        --region $REGION \
        --query 'SecurityGroups[0].GroupId' \
        --output text)

# Permitir acesso PostgreSQL apenas da EC2
aws ec2 authorize-security-group-ingress \
    --group-id $RDS_SG_ID \
    --protocol tcp \
    --port 5432 \
    --source-group $EC2_SG_ID \
    --region $REGION 2>/dev/null || true

echo_info "Security Group RDS criado: $RDS_SG_ID"

# 6. Criar subnet group para RDS
echo_info "Criando DB Subnet Group..."
ALL_SUBNETS=$(aws ec2 describe-subnets \
    --filters "Name=vpc-id,Values=$VPC_ID" \
    --region $REGION \
    --query 'Subnets[*].SubnetId' \
    --output text)

aws rds create-db-subnet-group \
    --db-subnet-group-name ec2-amazon-q-subnet-group \
    --db-subnet-group-description "Subnet group para RDS Amazon Q" \
    --subnet-ids $ALL_SUBNETS \
    --region $REGION 2>/dev/null || echo_warn "DB Subnet Group já existe"

# 7. Obter AMI mais recente do Amazon Linux 2023 (ARM64)
echo_info "Obtendo AMI mais recente..."
AMI_ID=$(aws ec2 describe-images \
    --owners amazon \
    --filters \
        "Name=name,Values=al2023-ami-*" \
        "Name=architecture,Values=arm64" \
        "Name=state,Values=available" \
    --region $REGION \
    --query 'Images | sort_by(@, &CreationDate) | [-1].ImageId' \
    --output text)

echo_info "AMI selecionada: $AMI_ID"

# 8. Criar instância EC2
echo_info "Criando instância EC2..."
USER_DATA=$(cat << 'EOF'
#!/bin/bash
yum update -y
yum install -y postgresql15 htop curl wget

# Instalar AWS CLI v2
curl "https://awscli.amazonaws.com/awscli-exe-linux-aarch64.zip" -o "awscliv2.zip"
unzip awscliv2.zip
./aws/install

# Configurar timezone
timedatectl set-timezone America/Sao_Paulo

# Criar script de conexão ao banco
cat > /home/ec2-user/connect-db.sh << 'DBEOF'
#!/bin/bash
echo "Conectando ao PostgreSQL..."
echo "Use a senha: postgres123"
psql -h $1 -U postgres -d postgres
DBEOF

chmod +x /home/ec2-user/connect-db.sh
chown ec2-user:ec2-user /home/ec2-user/connect-db.sh

echo "Setup da EC2 concluído!" > /var/log/user-data.log
EOF
)

INSTANCE_ID=$(aws ec2 run-instances \
    --image-id $AMI_ID \
    --count 1 \
    --instance-type t4g.medium \
    --key-name $KEY_NAME \
    --security-group-ids $EC2_SG_ID \
    --subnet-id $SUBNET_ID \
    --user-data "$USER_DATA" \
    --tag-specifications "ResourceType=instance,Tags=[{Key=Name,Value=$INSTANCE_NAME}]" \
    --region $REGION \
    --query 'Instances[0].InstanceId' \
    --output text)

echo_info "Instância EC2 criada: $INSTANCE_ID"

# 9. Criar RDS PostgreSQL
echo_info "Criando RDS PostgreSQL (isso pode levar alguns minutos)..."
aws rds create-db-instance \
    --db-instance-identifier $DB_NAME \
    --db-instance-class db.t4g.micro \
    --engine postgres \
    --engine-version 15.4 \
    --master-username postgres \
    --master-user-password postgres123 \
    --allocated-storage 20 \
    --vpc-security-group-ids $RDS_SG_ID \
    --db-subnet-group-name ec2-amazon-q-subnet-group \
    --backup-retention-period 7 \
    --storage-encrypted \
    --region $REGION \
    --no-multi-az \
    --no-publicly-accessible 2>/dev/null || echo_warn "RDS já existe ou erro na criação"

# 10. Aguardar instâncias ficarem prontas
echo_info "Aguardando instância EC2 ficar pronta..."
aws ec2 wait instance-running --instance-ids $INSTANCE_ID --region $REGION

echo_info "Aguardando RDS ficar disponível (pode levar 5-10 minutos)..."
aws rds wait db-instance-available --db-instance-identifier $DB_NAME --region $REGION

# 11. Obter informações finais
echo_info "Obtendo informações finais..."

PUBLIC_IP=$(aws ec2 describe-instances \
    --instance-ids $INSTANCE_ID \
    --region $REGION \
    --query 'Reservations[0].Instances[0].PublicIpAddress' \
    --output text)

RDS_ENDPOINT=$(aws rds describe-db-instances \
    --db-instance-identifier $DB_NAME \
    --region $REGION \
    --query 'DBInstances[0].Endpoint.Address' \
    --output text)

# 12. Criar scripts de conexão
cat > connect-ec2.sh << EOF
#!/bin/bash
echo "Conectando à instância EC2..."
ssh -i ${KEY_NAME}.pem ec2-user@${PUBLIC_IP}
EOF
chmod +x connect-ec2.sh

cat > test-database.sh << EOF
#!/bin/bash
echo "Testando conexão com o banco PostgreSQL..."
echo "Conecte-se primeiro à EC2 e depois execute:"
echo "./connect-db.sh ${RDS_ENDPOINT}"
EOF
chmod +x test-database.sh

# 13. Criar arquivo de informações
cat > infrastructure-info.txt << EOF
=== INFORMAÇÕES DA INFRAESTRUTURA ===

EC2 Instance:
- Instance ID: $INSTANCE_ID
- Public IP: $PUBLIC_IP
- Instance Type: t4g.medium
- Key Pair: ${KEY_NAME}.pem

RDS PostgreSQL:
- DB Identifier: $DB_NAME
- Endpoint: $RDS_ENDPOINT
- Port: 5432
- Username: postgres
- Password: postgres123

Security Groups:
- EC2 SG: $EC2_SG_ID
- RDS SG: $RDS_SG_ID

VPC: $VPC_ID
Subnet: $SUBNET_ID

=== COMANDOS DE CONEXÃO ===

SSH para EC2:
ssh -i ${KEY_NAME}.pem ec2-user@${PUBLIC_IP}

Conectar ao PostgreSQL (de dentro da EC2):
psql -h ${RDS_ENDPOINT} -U postgres -d postgres

=== SCRIPTS CRIADOS ===
- connect-ec2.sh: Conecta à instância EC2
- test-database.sh: Instruções para testar o banco
- cleanup.sh: Remove toda a infraestrutura

EOF

# 14. Criar script de limpeza
cat > cleanup.sh << EOF
#!/bin/bash
echo "🧹 Removendo toda a infraestrutura..."

# Terminar instância EC2
aws ec2 terminate-instances --instance-ids $INSTANCE_ID --region $REGION

# Aguardar terminação
aws ec2 wait instance-terminated --instance-ids $INSTANCE_ID --region $REGION

# Deletar RDS
aws rds delete-db-instance \
    --db-instance-identifier $DB_NAME \
    --skip-final-snapshot \
    --region $REGION

# Aguardar RDS ser deletado
aws rds wait db-instance-deleted --db-instance-identifier $DB_NAME --region $REGION

# Deletar Security Groups
aws ec2 delete-security-group --group-id $EC2_SG_ID --region $REGION
aws ec2 delete-security-group --group-id $RDS_SG_ID --region $REGION

# Deletar DB Subnet Group
aws rds delete-db-subnet-group --db-subnet-group-name ec2-amazon-q-subnet-group --region $REGION

# Deletar Key Pair
aws ec2 delete-key-pair --key-name $KEY_NAME --region $REGION

echo "✅ Limpeza concluída!"
EOF
chmod +x cleanup.sh

echo ""
echo "🎉 Deploy concluído com sucesso!"
echo ""
echo_info "Informações salvas em: infrastructure-info.txt"
echo_info "Para conectar à EC2: ./connect-ec2.sh"
echo_info "Para testar o banco: ./test-database.sh"
echo_info "Para limpar tudo: ./cleanup.sh"
echo ""
echo_warn "IMPORTANTE: t4g.medium NÃO está no Free Tier (~$13/mês)"
echo_warn "Para Free Tier, altere para t2.micro ou t3.micro"
echo ""
echo "📋 Resumo:"
echo "- EC2 Public IP: $PUBLIC_IP"
echo "- RDS Endpoint: $RDS_ENDPOINT"
echo "- SSH Key: ${KEY_NAME}.pem"
