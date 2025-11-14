# 🐳 WMS Enterprise - Setup Docker para Desenvolvimento

Documentação completa para configurar e usar o ambiente Docker de desenvolvimento do WMS Enterprise.

## 📋 Índice

1. [Visão Geral](#-visão-geral)
2. [Pré-requisitos](#-pré-requisitos)
3. [Instalação Rápida](#-instalação-rápida)
4. [Serviços Inclusos](#-serviços-inclusos)
5. [Usando o Makefile](#-usando-o-makefile)
6. [Acessando as Interfaces](#-acessando-as-interfaces)
7. [Troubleshooting](#-troubleshooting)
8. [Arquitetura](#-arquitetura)

---

## 🎯 Visão Geral

O arquivo `docker-compose.yml` configura **11 serviços integrados** para o desenvolvimento completo do WMS Enterprise:

| Serviço | Propósito | Porta |
|---------|----------|-------|
| **PostgreSQL** | Banco de dados relacional | 5432 |
| **Redis** | Cache e sessões | 6379 |
| **Elasticsearch** | Search e analytics | 9200 |
| **Kafka** | Event streaming | 9092 |
| **Prometheus** | Coleta de métricas | 9090 |
| **Grafana** | Visualização de métricas | 3000 |
| **Jaeger** | Distributed tracing | 16686 |
| **Loki** | Log aggregation | 3100 |
| **pgAdmin** | Interface PostgreSQL | 5050 |
| **Redis Commander** | Interface Redis | 8081 |
| **Kafka UI** | Interface Kafka | 8080 |

---

## ⚙️ Pré-requisitos

### Hardware Mínimo
```
CPU:    4 cores
RAM:    8GB (16GB recomendado)
Disco:  50GB SSD disponível
```

### Software Obrigatório

#### Windows
```bash
# 1. Instalar WSL2
wsl --install

# 2. Instalar Docker Desktop
# Download: https://www.docker.com/products/docker-desktop
# Habilitar WSL2 integration nas configurações

# 3. Instalar Git
choco install git

# 4. Verificar instalação
docker --version          # Docker 24+
docker-compose --version  # Docker Compose 2.0+
```

#### macOS
```bash
# 1. Instalar Homebrew
/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"

# 2. Instalar Docker
brew install docker docker-compose
# Ou download Docker Desktop: https://www.docker.com/products/docker-desktop

# 3. Instalar Git
brew install git

# 4. Verificar
docker --version
docker-compose --version
```

#### Linux (Ubuntu/Debian)
```bash
# 1. Atualizar repositórios
sudo apt update && sudo apt upgrade -y

# 2. Instalar Docker
sudo apt install docker.io docker-compose -y
sudo usermod -aG docker $USER
newgrp docker

# 3. Instalar Git
sudo apt install git -y

# 4. Verificar
docker --version
docker-compose --version
```

---

## 🚀 Instalação Rápida

### Opção 1: Usando Make (Recomendado)

```bash
# Clone ou navegue até o repositório
cd /caminho/para/Workspace_WMS

# Setup completo (instala dependências + inicia Docker + migrações)
make setup

# Aguarde 2-3 minutos e você terá:
# ✅ Docker rodando
# ✅ Banco de dados pronto
# ✅ Cache configurado
# ✅ Elasticsearch indexado
# ✅ Kafka com tópicos criados
# ✅ Prometheus coletando métricas
# ✅ Grafana com dashboards
```

### Opção 2: Manual

```bash
# 1. Copiar arquivo de configuração
cp .env.example .env.local

# 2. Iniciar Docker Compose
docker-compose up -d

# 3. Aguardar inicialização (cerca de 30 segundos)
docker-compose ps

# 4. Verificar saúde dos serviços
docker-compose exec postgres pg_isready -U wms_user
docker-compose exec redis redis-cli ping
# Esperado: PONG
```

---

## 📦 Serviços Inclusos

### 1. PostgreSQL 15
**Banco de dados relacional (OLTP)**

```bash
# Conectar via psql
psql -h localhost -U wms_user -d wms_dev -W

# Ou via Docker
docker-compose exec postgres psql -U wms_user -d wms_dev

# Credenciais
User:     wms_user
Password: wms_password_dev
Database: wms_dev
```

### 2. Redis 7
**Cache distribuído e sessões**

```bash
# Conectar via redis-cli
redis-cli -h localhost -p 6379

# Ou via Docker
docker-compose exec redis redis-cli

# Comandos úteis
PING                    # Testar conexão
KEYS *                  # Listar todas as chaves
FLUSHDB                 # Limpar banco
INFO                    # Informações do servidor
```

### 3. Elasticsearch 8
**Search engine e análise de logs**

```bash
# Testar conexão
curl http://localhost:9200

# Listar índices
curl http://localhost:9200/_cat/indices

# Ver cluster health
curl http://localhost:9200/_cluster/health?pretty
```

### 4. Apache Kafka
**Event streaming e event sourcing**

```bash
# Acessar Kafka UI
# URL: http://localhost:8080

# Criar tópico via Docker
docker-compose exec kafka kafka-topics.sh --create \
  --topic my-topic \
  --bootstrap-server localhost:9092 \
  --partitions 3 \
  --replication-factor 1

# Listar tópicos
docker-compose exec kafka kafka-topics.sh --list \
  --bootstrap-server localhost:9092

# Consumir mensagens
docker-compose exec kafka kafka-console-consumer.sh \
  --bootstrap-server localhost:9092 \
  --topic my-topic \
  --from-beginning
```

### 5. Prometheus
**Coleta e armazenamento de métricas**

```bash
# Interface Web
# URL: http://localhost:9090

# Exemplo de query
# Métrica: up{job="postgres"}
# Métrica: node_memory_MemFree_bytes
# Métrica: wms_orders_total
```

### 6. Grafana
**Visualização de métricas e dashboards**

```
URL: http://localhost:3000
User: admin
Password: admin
```

**Incluído:**
- Dashboard de saúde do sistema
- Métricas de banco de dados
- Performance de aplicação
- Logs integrados (via Loki)

### 7. Jaeger
**Distributed tracing para troubleshooting**

```
URL: http://localhost:16686

Funcionalidades:
- Rastreamento de requisições através de microserviços
- Análise de latência
- Debugging de fluxos complexos
```

### 8. Loki + Promtail
**Agregação e consulta de logs**

```bash
# Query em Grafana
{container="wms-postgres"}
{job="docker"} | json
```

### 9. pgAdmin
**Interface gráfica para PostgreSQL**

```
URL: http://localhost:5050
Email: admin@wms.local
Password: admin
```

### 10. Redis Commander
**Interface para gerenciar Redis**

```
URL: http://localhost:8081
```

### 11. Kafka UI
**Interface para gerenciar Kafka**

```
URL: http://localhost:8080
```

---

## 🛠️ Usando o Makefile

O `Makefile` fornece commands convenientes:

### Setup Inicial
```bash
make help              # Ver todos os commands
make setup             # Setup completo (dependências + Docker + DB)
make install           # Instalar apenas dependências
```

### Docker
```bash
make docker-up         # Iniciar todos os serviços
make docker-down       # Parar todos os serviços
make docker-restart    # Reiniciar serviços
make docker-ps         # Ver status dos containers
make docker-logs       # Ver logs em tempo real
```

### Banco de Dados
```bash
make db-create         # Criar banco de dados
make db-migrate        # Executar migrações
make db-seed           # Popular com dados de teste
make db-reset          # Resetar banco (drop + create + migrate)
make db-shell          # Abrir shell PostgreSQL
```

### Execução
```bash
make run-backend       # Iniciar backend (porta 8080)
make run-frontend      # Iniciar frontend (porta 5173)
make run-all           # Ver instruções para executar ambos
```

### Validação
```bash
make health-check      # Verificar saúde dos serviços
make test              # Executar testes
make lint              # Rodar linters
make fmt               # Formatar código
```

### Monitoramento
```bash
make dashboard         # Abrir Grafana
make prometheus        # Abrir Prometheus
make jaeger            # Abrir Jaeger UI
make kafka-ui          # Abrir Kafka UI
make pgadmin           # Abrir pgAdmin
```

### Limpeza
```bash
make clean             # Limpar diretórios de build
make clean-all         # Limpar tudo (docker + builds)
make docker-prune      # Limpar volumes não usados
```

---

## 🌐 Acessando as Interfaces

### Aplicação
```
Frontend:  http://localhost:5173
Backend:   http://localhost:8080
API Docs:  http://localhost:8080/docs
```

### Databases & Cache
```
PostgreSQL:      localhost:5432 (wms_user/wms_password_dev)
pgAdmin:         http://localhost:5050 (admin@wms.local/admin)
Redis:           localhost:6379
Redis Commander: http://localhost:8081
```

### Search & Events
```
Elasticsearch: http://localhost:9200
Kafka UI:      http://localhost:8080
Zookeeper:     localhost:2181
```

### Monitoring & Logging
```
Prometheus:    http://localhost:9090
Grafana:       http://localhost:3000 (admin/admin)
Loki:          http://localhost:3100
Jaeger:        http://localhost:16686
```

---

## 🔧 Configuração

### Variáveis de Ambiente

Crie arquivo `.env.local` a partir de `.env.example`:

```bash
cp .env.example .env.local
```

Principais variáveis:

```env
# Database
DB_HOST=localhost
DB_PORT=5432
DB_NAME=wms_dev
DB_USER=wms_user
DB_PASSWORD=wms_password_dev

# Redis
REDIS_HOST=localhost
REDIS_PORT=6379

# Elasticsearch
ELASTICSEARCH_URL=http://localhost:9200

# Kafka
KAFKA_BROKERS=localhost:9092

# API
API_PORT=8080

# Logging
LOG_LEVEL=debug
```

### Persistent Volumes

Os dados são armazenados em volumes Docker nomeados:

```bash
# Ver volumes
docker volume ls | grep wms_

# Remover volume específico
docker volume rm wms_postgres_data

# Limpar todos os volumes
docker volume prune
```

---

## 🐛 Troubleshooting

### Docker não inicia

**Windows/Mac:**
1. Abrir Docker Desktop
2. Aguardar inicialização completa

**Linux:**
```bash
sudo systemctl start docker
sudo systemctl enable docker
```

### PostgreSQL não conecta

```bash
# Ver logs
docker-compose logs postgres

# Reiniciar
docker-compose restart postgres

# Esperar health check
sleep 15

# Testar conexão
docker-compose exec postgres pg_isready -U wms_user
```

### Porta já em uso

```bash
# Windows
netstat -ano | findstr :5432

# Mac/Linux
lsof -i :5432

# Matar processo
kill -9 <PID>
```

### Redis não inicia

```bash
# Ver logs
docker-compose logs redis

# Limpar dados
docker volume rm wms_redis_data

# Reiniciar
docker-compose restart redis
```

### Elasticsearch usa muita memória

Reduzir limite em `docker-compose.yml`:

```yaml
elasticsearch:
  environment:
    - "ES_JAVA_OPTS=-Xms256m -Xmx256m"  # Reduzir de 512m
```

### Fazer reset completo

```bash
# Parar tudo e remover volumes
docker-compose down -v

# Remover imagens (opcional)
docker-compose rm -f

# Iniciar novamente
docker-compose up -d
```

---

## 🏗️ Arquitetura

```
┌─────────────────────────────────────┐
│    Development Environment          │
└─────────────────────────────────────┘

┌──────────────────────────────────────────────────┐
│        Application Layer                         │
│  ┌──────────────┐    ┌──────────────┐           │
│  │   Backend    │    │   Frontend   │           │
│  │  (Go/Rust)   │    │   (React)    │           │
│  └──────────────┘    └──────────────┘           │
└──────────────────────────────────────────────────┘
           │                    │
┌──────────▼────────────────────▼──────────────────┐
│         API Gateway / Load Balancer              │
└──────────────────────────────────────────────────┘
           │                    │
┌──────────┴────────────────────┴──────────────────┐
│        Service Layer (Docker Containers)        │
├──────────────────────────────────────────────────┤
│                                                  │
│  ┌─────────────────┐   ┌──────────────────┐    │
│  │   PostgreSQL    │   │      Redis       │    │
│  │   (OLTP DB)     │   │   (Cache)        │    │
│  └─────────────────┘   └──────────────────┘    │
│                                                  │
│  ┌─────────────────┐   ┌──────────────────┐    │
│  │  Elasticsearch  │   │      Kafka       │    │
│  │   (Search)      │   │  (Events)        │    │
│  └─────────────────┘   └──────────────────┘    │
│                                                  │
│  ┌─────────────────┐   ┌──────────────────┐    │
│  │   Prometheus    │   │     Grafana      │    │
│  │   (Metrics)     │   │  (Dashboards)    │    │
│  └─────────────────┘   └──────────────────┘    │
│                                                  │
│  ┌─────────────────┐   ┌──────────────────┐    │
│  │     Jaeger      │   │   Loki+Promtail  │    │
│  │   (Tracing)     │   │    (Logging)     │    │
│  └─────────────────┘   └──────────────────┘    │
│                                                  │
└──────────────────────────────────────────────────┘
           │           │          │
           ▼           ▼          ▼
    Management UIs (Web Interfaces)
```

---

## 📊 Exemplos de Uso

### Exemplo 1: Rodar Backend + Frontend

**Terminal 1 (Backend):**
```bash
make run-backend
# Server listening on :8080
```

**Terminal 2 (Frontend):**
```bash
make run-frontend
# Local: http://localhost:5173
```

**Terminal 3 (Docker logs):**
```bash
make docker-logs
```

### Exemplo 2: Verificar Saúde

```bash
make health-check

# Output:
# 🏥 Verificando saúde dos serviços...
#   → PostgreSQL... ✅ OK
#   → Redis... ✅ OK
#   → Elasticsearch... ✅ OK
#   → Kafka... ✅ OK
#   → Prometheus... ✅ OK
#   → Grafana... ✅ OK
```

### Exemplo 3: Executar Testes

```bash
make test
# go test -v -race -coverprofile=coverage.out ./...
```

### Exemplo 4: Reset Completo

```bash
# Quando algo der errado
make clean-all
make setup
# Volta ao estado limpo
```

---

## 🚨 Importante

### Para Desenvolvimento
- ✅ Use `docker-compose.yml` como está
- ✅ Dados são persistidos em volumes
- ✅ Modificar código não requer restart de Docker

### Para Produção
- ❌ Não use este `docker-compose.yml`
- ❌ Use Kubernetes (k8s) conforme documentação
- ❌ Configure secrets adequadamente
- ❌ Aumente limites de recursos

### Segurança
- ⚠️ Senhas padrão são apenas para desenvolvimento
- ⚠️ Nunca commitar `.env.local` com senhas reais
- ⚠️ Usar HashiCorp Vault em produção

---

## 📞 Suporte

Consulte os documentos da arquitetura:
- `03_Arquitetura/03_ARQUITETURA_SISTEMA.md`
- `05_Especificacoes_Tecnicas/05_ESPECIFICACOES_TECNICAS.md`
- `13_Setup_Ambiente_Desenvolvimento/13_SETUP_AMBIENTE_DESENVOLVIMENTO.md`

---

**Última Atualização:** Janeiro 2025
**Status:** Pronto para Desenvolvimento
**Versão:** 1.0

🚀 **Bem-vindo ao WMS Enterprise!**
