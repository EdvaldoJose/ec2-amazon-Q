# EC2 Amazon Q com PostgreSQL RDS

Este projeto cria uma infraestrutura completa na AWS com:
- Instância EC2 t4g.medium (ARM-based)
- Banco de dados PostgreSQL RDS existente (configurado)
- Configuração de segurança e conectividade

## 🏗️ Arquitetura

```
┌─────────────────┐    ┌──────────────────────────────────┐
│   EC2 Instance  │────│  RDS PostgreSQL (existente)     │
│   t4g.medium    │    │  database-1.cd2owuoacfg0...     │
│   Amazon Linux  │    │  PostgreSQL 17.4                │
└─────────────────┘    └──────────────────────────────────┘
         │
    ┌────────────┐
    │ Security   │
    │ Groups     │
    └────────────┘
```

## ✅ Status da Infraestrutura

### Recursos Criados:
- **EC2 Instance**: `i-0467269d1d972bafb` (rodando)
- **IP Público**: `3.216.188.183` (Elastic IP)
- **RDS PostgreSQL**: `database-1.cd2owuoacfg0.us-east-1.rds.amazonaws.com` (configurado)
- **Security Groups**: Configurados para conectividade EC2 ↔ RDS

## 🚀 Como Usar

### 1. Conectar à EC2
```bash
cd ec2-amazon-Q
./connect-ec2.sh
```

### 2. Configurar conexão com RDS (dentro da EC2)
```bash
# Copie o script para a EC2 e execute:
./setup-rds-connection.sh
```

### 3. Testar o banco de dados
```bash
# Dentro da EC2:
./test-rds.sh
./connect-rds.sh
```

## 🗄️ Informações do Banco PostgreSQL

### Configurações:
- **Host**: `database-1.cd2owuoacfg0.us-east-1.rds.amazonaws.com`
- **Porta**: `5432`
- **Engine**: `PostgreSQL 17.4`
- **Usuário**: `postgres`
- **Database**: `postgres`
- **Senha**: ⚠️ Você precisa da senha do RDS existente

### Como obter/resetar a senha:
1. Acesse o console AWS RDS
2. Selecione a instância `database-1`
3. Clique em "Modify"
4. Defina uma nova senha em "New master password"

## 🔐 Conectar ao Banco

### Via EC2 (recomendado):
```bash
# Dentro da EC2:
psql -h database-1.cd2owuoacfg0.us-east-1.rds.amazonaws.com -U postgres -d postgres
```

### Comandos SQL de exemplo:
```sql
-- Verificar versão
SELECT version();

-- Criar database para o projeto
CREATE DATABASE ec2_amazon_q_db;

-- Conectar ao novo database
\c ec2_amazon_q_db

-- Criar tabela de teste
CREATE TABLE usuarios (
    id SERIAL PRIMARY KEY,
    nome VARCHAR(100),
    email VARCHAR(100),
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Inserir dados
INSERT INTO usuarios (nome, email) VALUES 
('João Silva', 'joao@email.com'),
('Maria Santos', 'maria@email.com');

-- Consultar dados
SELECT * FROM usuarios;
```

## 💰 Custos

### Recursos NÃO Free Tier:
- **EC2 t4g.medium**: ~$13/mês
- **Elastic IP**: $0 (enquanto associado)

### Para usar Free Tier:
- Altere a EC2 para `t2.micro` ou `t3.micro`
- RDS existente não gera custo adicional

## 🔒 Segurança

### Configurações implementadas:
- ✅ Security Groups configurados
- ✅ RDS acessível apenas da EC2
- ✅ Comunicação criptografada (SSL/TLS)
- ✅ Elastic IP para acesso SSH estável

### Recomendações:
- Altere a senha padrão do PostgreSQL
- Use IAM roles em vez de credenciais hardcoded
- Configure backup automático
- Monitore logs de acesso

## 🛠️ Scripts Incluídos

### Scripts principais:
- `connect-ec2.sh`: Conecta à EC2 via SSH
- `setup-rds-connection.sh`: Configura conexão RDS na EC2
- `test-database.sh`: Instruções para testar PostgreSQL
- `cleanup.sh`: Remove toda a infraestrutura

### Scripts criados na EC2:
- `~/connect-rds.sh`: Conecta ao RDS
- `~/test-rds.sh`: Testa conectividade
- `~/rds-config.txt`: Configurações e comandos

## 📊 Monitoramento

### CloudWatch Metrics disponíveis:
```bash
# CPU da EC2
aws cloudwatch get-metric-statistics \
  --namespace AWS/EC2 \
  --metric-name CPUUtilization \
  --dimensions Name=InstanceId,Value=i-0467269d1d972bafb

# Conexões do RDS
aws cloudwatch get-metric-statistics \
  --namespace AWS/RDS \
  --metric-name DatabaseConnections \
  --dimensions Name=DBInstanceIdentifier,Value=database-1
```

## 🧹 Limpeza

Para remover recursos criados:
```bash
./cleanup.sh
```

**Nota**: O RDS `database-1` não será removido pois já existia.

## 🔍 Troubleshooting

### Problemas comuns:

1. **Não consegue conectar via SSH**:
   ```bash
   # Verificar se a instância está rodando
   aws ec2 describe-instances --instance-ids i-0467269d1d972bafb
   
   # Testar conectividade
   nc -zv 3.216.188.183 22
   ```

2. **Não consegue conectar ao RDS**:
   ```bash
   # Dentro da EC2, testar conectividade
   nc -zv database-1.cd2owuoacfg0.us-east-1.rds.amazonaws.com 5432
   
   # Verificar se tem a senha correta
   psql -h database-1.cd2owuoacfg0.us-east-1.rds.amazonaws.com -U postgres -d postgres -c "SELECT 1;"
   ```

3. **Senha do RDS**:
   - Acesse o console AWS RDS
   - Modifique a instância para definir nova senha
   - Ou solicite a senha ao administrador da conta

## 📝 Próximos Passos

1. ✅ Conectar à EC2
2. ✅ Configurar cliente PostgreSQL
3. ⏳ Obter senha do RDS
4. ⏳ Testar conexão com banco
5. ⏳ Criar estruturas do projeto
6. ⏳ Desenvolver aplicação

## 🤝 Suporte

Para dúvidas:
1. Verifique os logs: `infrastructure-info.txt`
2. Execute: `./test-database.sh`
3. Consulte troubleshooting acima

---
**Status**: ✅ Infraestrutura pronta e banco configurado!
**Próximo passo**: Obter senha do RDS e testar conexão.
