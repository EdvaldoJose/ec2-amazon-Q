#!/bin/bash

# Script para instalar PostgreSQL na instância EC2
# Execute este script DENTRO da instância EC2 após conectar via SSH

set -e

echo "🐘 Instalando PostgreSQL na instância EC2..."

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

# 2. Instalar PostgreSQL
echo_info "Instalando PostgreSQL 15..."
sudo yum install -y postgresql15-server postgresql15

# 3. Inicializar banco de dados
echo_info "Inicializando banco de dados..."
sudo postgresql-setup --initdb

# 4. Habilitar e iniciar serviço
echo_info "Habilitando e iniciando PostgreSQL..."
sudo systemctl enable postgresql
sudo systemctl start postgresql

# 5. Verificar status
echo_info "Verificando status do PostgreSQL..."
sudo systemctl status postgresql --no-pager

# 6. Configurar usuário postgres
echo_info "Configurando usuário postgres..."
sudo -u postgres psql -c "ALTER USER postgres PASSWORD 'postgres123';"

# 7. Configurar acesso local
echo_info "Configurando acesso local..."
sudo sed -i "s/#listen_addresses = 'localhost'/listen_addresses = 'localhost'/" /var/lib/pgsql/data/postgresql.conf

# Configurar autenticação
sudo sed -i "s/local   all             all                                     peer/local   all             all                                     md5/" /var/lib/pgsql/data/pg_hba.conf
sudo sed -i "s/host    all             all             127.0.0.1\/32            ident/host    all             all             127.0.0.1\/32            md5/" /var/lib/pgsql/data/pg_hba.conf

# 8. Reiniciar PostgreSQL para aplicar configurações
echo_info "Reiniciando PostgreSQL..."
sudo systemctl restart postgresql

# 9. Criar script de conexão
echo_info "Criando script de conexão..."
cat > ~/connect-db.sh << 'EOF'
#!/bin/bash
echo "Conectando ao PostgreSQL local..."
echo "Usuário: postgres"
echo "Senha: postgres123"
psql -h localhost -U postgres -d postgres
EOF

chmod +x ~/connect-db.sh

# 10. Criar banco de teste
echo_info "Criando banco de teste..."
sudo -u postgres createdb testdb

# 11. Instalar ferramentas adicionais
echo_info "Instalando ferramentas adicionais..."
sudo yum install -y htop curl wget git

echo ""
echo "🎉 PostgreSQL instalado com sucesso!"
echo ""
echo "📋 INFORMAÇÕES DO BANCO:"
echo "========================"
echo "Host: localhost"
echo "Porta: 5432"
echo "Usuário: postgres"
echo "Senha: postgres123"
echo "Bancos: postgres, testdb"
echo ""
echo "🔧 COMANDOS ÚTEIS:"
echo "=================="
echo_cmd "~/connect-db.sh                    # Conectar ao PostgreSQL"
echo_cmd "sudo systemctl status postgresql   # Ver status do serviço"
echo_cmd "sudo systemctl restart postgresql # Reiniciar serviço"
echo_cmd "sudo -u postgres psql             # Conectar como usuário postgres"
echo ""
echo "🧪 TESTE RÁPIDO:"
echo "================"
echo_cmd "psql -h localhost -U postgres -d postgres -c \"SELECT version();\""
echo ""

# Teste de conexão
echo_info "Testando conexão..."
if sudo -u postgres psql -c "SELECT version();" > /dev/null 2>&1; then
    echo_info "✅ PostgreSQL está funcionando corretamente!"
else
    echo_error "❌ Erro na conexão com PostgreSQL"
fi

echo ""
echo_info "Para conectar ao banco, execute: ~/connect-db.sh"
