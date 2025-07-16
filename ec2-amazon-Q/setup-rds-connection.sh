#!/bin/bash

# Script para configurar conexão com RDS na EC2
# Execute este script DENTRO da instância EC2 após conectar via SSH

set -e

RDS_ENDPOINT="database-1.cd2owuoacfg0.us-east-1.rds.amazonaws.com"

echo "🔗 Configurando conexão com RDS PostgreSQL..."

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

# 1. Atualizar sistema
echo_info "Atualizando sistema..."
sudo yum update -y

# 2. Instalar cliente PostgreSQL
echo_info "Instalando cliente PostgreSQL..."
sudo yum install -y postgresql15

# 3. Instalar ferramentas de rede
echo_info "Instalando ferramentas de rede..."
sudo yum install -y nc telnet

# 4. Testar conectividade
echo_info "Testando conectividade com RDS..."
if nc -zv $RDS_ENDPOINT 5432 2>/dev/null; then
    echo_info "✅ Conectividade com RDS OK!"
else
    echo_error "❌ Não foi possível conectar ao RDS"
    echo "Verifique se o Security Group está configurado corretamente"
fi

# 5. Criar script de conexão
echo_info "Criando script de conexão ao RDS..."
cat > ~/connect-rds.sh << EOF
#!/bin/bash
echo "🐘 Conectando ao PostgreSQL RDS..."
echo "Host: $RDS_ENDPOINT"
echo "Usuário: postgres"
echo "Digite a senha quando solicitado"
echo ""
psql -h $RDS_ENDPOINT -U postgres -d postgres
EOF

chmod +x ~/connect-rds.sh

# 6. Criar script de teste
echo_info "Criando script de teste do banco..."
cat > ~/test-rds.sh << 'EOF'
#!/bin/bash
RDS_ENDPOINT="database-1.cd2owuoacfg0.us-east-1.rds.amazonaws.com"

echo "🧪 Testando RDS PostgreSQL..."
echo "=============================="

# Teste de conectividade
echo "1. Testando conectividade..."
if nc -zv $RDS_ENDPOINT 5432; then
    echo "✅ Porta 5432 acessível"
else
    echo "❌ Porta 5432 não acessível"
    exit 1
fi

# Teste de versão (requer senha)
echo ""
echo "2. Para testar a conexão completa, execute:"
echo "   psql -h $RDS_ENDPOINT -U postgres -d postgres -c \"SELECT version();\""
echo ""
echo "3. Para conectar interativamente:"
echo "   ./connect-rds.sh"
echo ""
EOF

chmod +x ~/test-rds.sh

# 7. Criar arquivo de configuração
echo_info "Criando arquivo de configuração..."
cat > ~/rds-config.txt << EOF
=== CONFIGURAÇÃO RDS ===

Host: $RDS_ENDPOINT
Porta: 5432
Engine: PostgreSQL 17.4
Usuário: postgres
Database padrão: postgres

=== COMANDOS ÚTEIS ===

Conectar ao RDS:
./connect-rds.sh

Testar conectividade:
./test-rds.sh

Conectar diretamente:
psql -h $RDS_ENDPOINT -U postgres -d postgres

Testar versão:
psql -h $RDS_ENDPOINT -U postgres -d postgres -c "SELECT version();"

=== COMANDOS SQL INICIAIS ===

-- Criar database para o projeto
CREATE DATABASE ec2_amazon_q_db;

-- Listar databases
\l

-- Conectar ao novo database
\c ec2_amazon_q_db

-- Criar usuário específico (opcional)
CREATE USER app_user WITH PASSWORD 'sua_senha_aqui';
GRANT ALL PRIVILEGES ON DATABASE ec2_amazon_q_db TO app_user;

=== ESTRUTURA DE EXEMPLO ===

-- Tabela de usuários
CREATE TABLE usuarios (
    id SERIAL PRIMARY KEY,
    nome VARCHAR(100) NOT NULL,
    email VARCHAR(100) UNIQUE NOT NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Inserir dados de teste
INSERT INTO usuarios (nome, email) VALUES 
('João Silva', 'joao@email.com'),
('Maria Santos', 'maria@email.com'),
('Pedro Costa', 'pedro@email.com');

-- Consultar dados
SELECT * FROM usuarios;

EOF

# 8. Instalar ferramentas adicionais
echo_info "Instalando ferramentas adicionais..."
sudo yum install -y htop curl wget git vim

echo ""
echo "🎉 Configuração concluída!"
echo "========================="
echo ""
echo_info "Scripts criados:"
echo "• ~/connect-rds.sh - Conectar ao RDS"
echo "• ~/test-rds.sh - Testar conectividade"
echo "• ~/rds-config.txt - Configurações e comandos"
echo ""
echo_info "Para começar:"
echo "1. Execute: ./test-rds.sh"
echo "2. Se OK, execute: ./connect-rds.sh"
echo "3. Digite a senha do RDS quando solicitado"
echo ""
echo_warn "⚠️  Você precisa da senha do RDS 'database-1'"
echo_warn "Se não souber, pode resetá-la no console AWS"
echo ""
echo_info "RDS Endpoint: $RDS_ENDPOINT"
