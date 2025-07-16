#!/bin/bash

# Script para conectar à instância EC2
# Uso: ./connect-ec2.sh

set -e

REGION="us-east-1"
INSTANCE_ID="i-0467269d1d972bafb"
PUBLIC_IP="3.216.188.183"
KEY_NAME="ec2-amazon-q-key"

# Cores
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
NC='\033[0m'

echo_info() {
    echo -e "${GREEN}[INFO]${NC} $1"
}

echo_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

echo_warn() {
    echo -e "${YELLOW}[WARN]${NC} $1"
}

# Verificar se a chave existe
if [ ! -f "${KEY_NAME}.pem" ]; then
    echo_error "Chave privada ${KEY_NAME}.pem não encontrada!"
    echo "A chave deve estar no mesmo diretório que este script."
    exit 1
fi

echo_info "Conectando à instância EC2..."
echo_info "Instance ID: $INSTANCE_ID"
echo_info "IP Público: $PUBLIC_IP"
echo ""

# Verificar se a instância está acessível
echo_info "Testando conectividade SSH..."
if nc -z -w5 $PUBLIC_IP 22 2>/dev/null; then
    echo_info "✅ Porta SSH (22) está acessível"
else
    echo_warn "⏳ Porta SSH (22) não está acessível ainda"
    echo "A instância pode ainda estar inicializando. Aguarde alguns minutos."
    echo ""
fi

# Conectar via SSH
echo_info "Executando conexão SSH..."
echo "Comando: ssh -i ${KEY_NAME}.pem ec2-user@${PUBLIC_IP}"
echo ""

ssh -i ${KEY_NAME}.pem -o StrictHostKeyChecking=no ec2-user@${PUBLIC_IP}
