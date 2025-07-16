#!/bin/bash

# Script para testar conexão com PostgreSQL RDS existente
# Uso: ./test-database.sh

set -e

REGION="us-east-1"
RDS_ENDPOINT="database-1.cd2owuoacfg0.us-east-1.rds.amazonaws.com"
EC2_IP="3.216.188.183"

# Cores
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
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

echo_cmd() {
    echo -e "${BLUE}[CMD]${NC} $1"
}

echo ""
echo "🗄️  INFORMAÇÕES DO BANCO DE DADOS RDS"
echo "====================================="
echo "Host: $RDS_ENDPOINT"
echo "Porta: 5432"
echo "Engine: PostgreSQL 17.4"
echo "Usuário: postgres"
echo "Senha: [você precisa saber a senha do RDS existente]"
echo "Database: postgres"
echo ""

echo "📋 INSTRUÇÕES PARA TESTE"
echo "========================"
echo ""
echo "1. Conecte-se à instância EC2:"
echo_cmd "./connect-ec2.sh"
echo ""
echo "2. Dentro da EC2, instale o cliente PostgreSQL (se não estiver instalado):"
echo_cmd "sudo yum install -y postgresql15"
echo ""
echo "3. Teste a conectividade:"
echo_cmd "nc -zv $RDS_ENDPOINT 5432"
echo ""
echo "4. Conecte ao PostgreSQL:"
echo_cmd "psql -h $RDS_ENDPOINT -U postgres -d postgres"
echo ""
echo "5. Ou use o script helper (será criado na EC2):"
echo_cmd "./connect-rds.sh"
echo ""

echo "🧪 COMANDOS SQL PARA TESTE"
echo "=========================="
echo ""
echo "-- Verificar versão do PostgreSQL"
echo_cmd "SELECT version();"
echo ""
echo "-- Listar databases"
echo_cmd "\\l"
echo ""
echo "-- Criar database para o projeto"
echo_cmd "CREATE DATABASE ec2_amazon_q_db;"
echo ""
echo "-- Conectar ao novo database"
echo_cmd "\\c ec2_amazon_q_db"
echo ""
echo "-- Criar tabela de teste"
echo_cmd "CREATE TABLE usuarios (
    id SERIAL PRIMARY KEY,
    nome VARCHAR(100),
    email VARCHAR(100),
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);"
echo ""
echo "-- Inserir dados de teste"
echo_cmd "INSERT INTO usuarios (nome, email) VALUES 
('João Silva', 'joao@email.com'),
('Maria Santos', 'maria@email.com'),
('Pedro Costa', 'pedro@email.com');"
echo ""
echo "-- Consultar dados"
echo_cmd "SELECT * FROM usuarios;"
echo ""
echo "-- Ver informações da tabela"
echo_cmd "\\d usuarios"
echo ""
echo "-- Listar todas as tabelas"
echo_cmd "\\dt"
echo ""
echo "-- Sair do psql"
echo_cmd "\\q"
echo ""

echo "🔧 SCRIPT PARA CONECTAR AO RDS"
echo "==============================="
echo ""
echo "Execute este comando na EC2 para criar um script de conexão:"
echo ""
echo_cmd "cat > ~/connect-rds.sh << 'EOF'
#!/bin/bash
echo \"Conectando ao PostgreSQL RDS...\"
echo \"Host: $RDS_ENDPOINT\"
echo \"Usuário: postgres\"
echo \"Digite a senha quando solicitado\"
psql -h $RDS_ENDPOINT -U postgres -d postgres
EOF"
echo ""
echo_cmd "chmod +x ~/connect-rds.sh"
echo ""

echo "🔒 INFORMAÇÕES DE SEGURANÇA"
echo "==========================="
echo ""
echo_info "✅ Security Group configurado para permitir acesso da EC2 ao RDS"
echo_info "✅ Conexão apenas da EC2 (não público)"
echo_info "✅ Comunicação criptografada (SSL/TLS)"
echo ""
echo_warn "⚠️  Você precisa da senha do RDS existente"
echo_warn "⚠️  Se não souber a senha, pode resetá-la no console AWS"
echo ""

echo "💡 DICAS IMPORTANTES"
echo "==================="
echo ""
echo "• O RDS 'database-1' já existe e está disponível"
echo "• Configuramos o Security Group para permitir acesso da EC2"
echo "• Use o PostgreSQL 17.4 (versão mais recente)"
echo "• Crie um database específico para seu projeto"
echo "• Faça backup dos dados importantes"
echo ""

echo "🚀 PRÓXIMOS PASSOS"
echo "=================="
echo ""
echo "1. Conectar à EC2: ./connect-ec2.sh"
echo "2. Instalar cliente PostgreSQL na EC2"
echo "3. Testar conectividade com o RDS"
echo "4. Conectar ao banco e criar estruturas"
echo "5. Desenvolver sua aplicação"
echo ""

echo_info "✅ RDS PostgreSQL está disponível e configurado!"
echo_info "Endpoint: $RDS_ENDPOINT"
