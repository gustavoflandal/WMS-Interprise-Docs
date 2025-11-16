# SETUP AMBIENTE DE DESENVOLVIMENTO LOCAL - WMS ENTERPRISE

## Versão: 1.0
**Data:** Janeiro 2025  
**Status:** Pronto para Uso  
**Autor:** Equipe de Engenharia  
**Última Atualização:** Janeiro 2025

---

## 📋 ÍNDICE

1. [Visão Geral](#1-visão-geral)
2. [Requisitos de Sistema](#2-requisitos-de-sistema)
3. [Software Pré-requisitos](#3-software-pré-requisitos)
4. [Ferramentas Adicionais](#4-ferramentas-de-desenvolvimento-adicionais)
5. [Estrutura de Diretórios](#5-estrutura-de-diretórios)
6. [Configuração Docker](#6-arquivo-docker-composeyml)
7. [Configuração Variáveis](#7-arquivo-envexample)
8. [Makefile](#8-arquivo-makefile)
9. [Instalação Passo-a-Passo](#9-instalação-passo-a-passo)
10. [Validação](#10-validação-do-ambiente)
11. [Portas Utilizadas](#11-portas-utilizadas)
12. [Troubleshooting](#12-troubleshooting)
13. [Próximos Passos](#13-próximos-passos)
14. [Teste Inicial](#14-primeiro-teste-hello-world)

---

## 1. Visão Geral

Este documento descreve o setup completo do ambiente de desenvolvimento local para o WMS Enterprise. O ambiente utiliza Docker para facilitar a configuração e manter consistência entre diferentes máquinas.

### O que será instalado

- ✅ Git (Controle de versão)
- ✅ Docker & Docker Compose (Containers)
- ✅ Node.js & npm (Frontend)
- ✅ Go ou Rust (Backend)
- ✅ PostgreSQL (Database)
- ✅ Redis (Cache)
- ✅ Elasticsearch (Search)
- ✅ Kafka (Event Streaming)
- ✅ PgAdmin (Interface DB)
- ✅ Redis Commander (Interface Cache)

### Tempo estimado

- **Instalação de dependências:** 30-45 min
- **Download de containers:** 10-20 min
- **Setup inicial:** 15-30 min
- **Total:** 1-2 horas

---

## 2. Requisitos de Sistema

### Hardware Mínimo (Desenvolvimento básico)

```
CPU:        4 cores
RAM:        8GB (16GB recomendado)
Disco:      50GB SSD livre
Rede:       Conexão estável
```

### Hardware Recomendado (Confortável)

```
CPU:        8+ cores (Intel i7/Ryzen 7 ou superior)
RAM:        32GB
Disco:      100GB+ SSD rápido
Monitor:    Dual monitor recomendado
Rede:       Fibra ou banda larga
```

### Sistemas Operacionais Suportados

- ✅ **Windows 10/11** (com WSL2)
- ✅ **macOS 11+** (Intel ou Apple Silicon)
- ✅ **Linux Ubuntu 20.04+** ou Fedora 35+

---

## 3. Software Pré-requisitos

### Instalação por Sistema Operacional

#### Windows 10/11

**3.1 Git**
```bash
# Via Chocolatey
choco install git

# Ou download manual
# https://git-scm.com/download/win

# Validar
git --version
# Expected: git version 2.40+
```

**3.2 WSL2 (Windows Subsystem for Linux)**
```bash
# Abrir PowerShell como Admin e executar
wsl --install

# Depois instalar Ubuntu 22.04
# https://apps.microsoft.com/store/detail/ubuntu/9PDXGNCFSZ3C

# Validar
wsl --list --verbose
```

**3.3 Docker Desktop**
```
1. Download: https://www.docker.com/products/docker-desktop
2. Instalar e iniciar
3. Habilitar WSL2 integration nas configurações
4. Validar:
   docker --version      # Docker version 24+
   docker-compose --version  # Docker Compose version 2.0+
```

**3.4 Node.js (via nvm-windows)**
```bash
# Download nvm-windows
# https://github.com/coreybutler/nvm-windows/releases

# Ou via Chocolatey
choco install nvm

# Instalar Node 20 LTS
nvm install 20.0.0
nvm use 20.0.0

# Validar
node --version    # v20.0.0+
npm --version     # 9.0.0+
```

**3.5 .NET 10 SDK (Backend)**
```bash
# Via Chocolatey
choco install dotnet-sdk

# Ou download manual
# https://dotnet.microsoft.com/download/dotnet/10.0

# Validar
dotnet --version    # 10.0.x
dotnet --list-sdks  # Listar SDKs instalados

# Verificar runtimes instalados
dotnet --list-runtimes
```

**3.6 PostgreSQL**
```bash
# Via Chocolatey
choco install postgresql15

# Ou download manual
# https://www.postgresql.org/download/windows/

# Durante instalação, anotar:
# - Porta: 5432
# - Usuário: postgres
# - Senha: [escolher]

# Validar
psql --version    # psql (PostgreSQL) 15.0+
```

**3.7 Redis**
```bash
# Via Chocolatey
choco install redis-64

# Validar
redis-cli --version    # redis-cli 7.0+
```

**3.8 VS Code (Recomendado)**
```
Download: https://code.visualstudio.com/
Instalar extensões (dentro do VS Code):
  - Go (golang.go)
  - Thunder Client (rangav.vscode-thunder-client)
  - ES7+ React/Redux/React-Native snippets
  - Prettier - Code formatter
  - ESLint
  - Docker
  - PostgreSQL Explorer
```

---

#### macOS 11+

**3.1 Homebrew (Package Manager)**
```bash
/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"

# Validar
brew --version
```

**3.2 Git**
```bash
brew install git

# Validar
git --version    # git version 2.40+
```

**3.3 Docker**
```bash
brew install docker docker-compose

# Ou download Docker Desktop
# https://www.docker.com/products/docker-desktop/

# Validar
docker --version
docker-compose --version
```

**3.4 Node.js**
```bash
# Via nvm (recomendado)
curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.39.0/install.sh | bash

# Adicionar ao ~/.zshrc ou ~/.bash_profile
export NVM_DIR="$HOME/.nvm"
[ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"

# Depois
nvm install 20
nvm use 20

# Validar
node --version    # v20.0.0+
npm --version     # 9.0.0+
```

**3.5 .NET 10 SDK**
```bash
brew install --cask dotnet-sdk

# Ou via download direto
# https://dotnet.microsoft.com/download/dotnet/10.0

# Validar
dotnet --version    # 10.0.x
dotnet --list-sdks
dotnet --list-runtimes
```

**3.6 PostgreSQL**
```bash
brew install postgresql

# Iniciar serviço
brew services start postgresql

# Validar
psql --version    # psql (PostgreSQL) 15.0+
```

**3.7 Redis**
```bash
brew install redis

# Iniciar serviço
brew services start redis

# Validar
redis-cli --version    # redis-cli 7.0+
```

**3.8 VS Code**
```bash
brew install --cask visual-studio-code

# Instalar extensões (dentro do VS Code)
```

---

#### Linux (Ubuntu 22.04+)

**3.1 Atualizar repositórios**
```bash
sudo apt update
sudo apt upgrade -y
```

**3.2 Git**
```bash
sudo apt install git -y

# Validar
git --version
```

**3.3 Docker**
```bash
# Instalar dependências
sudo apt install curl gnupg lsb-release -y

# Adicionar repositório Docker
curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo gpg --dearmor -o /usr/share/keyrings/docker-archive-keyring.gpg

echo "deb [arch=amd64 signed-by=/usr/share/keyrings/docker-archive-keyring.gpg] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable" | sudo tee /etc/apt/sources.list.d/docker.list > /dev/null

# Instalar
sudo apt update
sudo apt install docker-ce docker-ce-cli containerd.io docker-compose-plugin -y

# Habilitar para usuário não-root
sudo usermod -aG docker $USER
newgrp docker

# Validar
docker --version
docker-compose --version
```

**3.4 Node.js**
```bash
# Via nvm
curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.39.0/install.sh | bash

# Recarregar shell
source ~/.bashrc

# Instalar
nvm install 20
nvm use 20

# Validar
node --version
npm --version
```

**3.5 .NET 10 SDK**
```bash
# Ubuntu 22.04 / 24.04
wget https://packages.microsoft.com/config/ubuntu/$(lsb_release -rs)/packages-microsoft-prod.deb -O packages-microsoft-prod.deb
sudo dpkg -i packages-microsoft-prod.deb
rm packages-microsoft-prod.deb

sudo apt-get update
sudo apt-get install -y dotnet-sdk-10.0

# Validar
dotnet --version    # 10.0.x
dotnet --list-sdks
dotnet --info       # Informações completas do ambiente
```

**3.6 PostgreSQL**
```bash
sudo apt install postgresql postgresql-contrib -y

# Iniciar serviço
sudo systemctl start postgresql

# Habilitar na inicialização
sudo systemctl enable postgresql

# Validar
psql --version
```

**3.7 Redis**
```bash
sudo apt install redis-server -y

# Iniciar serviço
sudo systemctl start redis-server

# Habilitar na inicialização
sudo systemctl enable redis-server

# Validar
redis-cli --version
```

**3.8 VS Code**
```bash
# Via snap
sudo snap install code --classic

# Ou download manual
# https://code.visualstudio.com/
```

---

## 4. Ferramentas de Desenvolvimento Adicionais

### IDEs Recomendadas

#### Backend (.NET)

**Opção 1: Visual Studio 2022 (v17.12+) Community (Recomendado para Windows)**
```
Download: https://visualstudio.microsoft.com/vs/community/
Recursos: IntelliSense avançado, debugging robusto, refactoring, AI assistance
Workloads necessários:
  - ASP.NET and web development
  - .NET desktop development
  - Azure development (opcional)
  - Container development tools

Importante: Versão 17.12+ necessária para suporte completo ao .NET 10
```

**Opção 2: JetBrains Rider 2024.3+**
```
Download: https://www.jetbrains.com/rider/
Licença: Paid (com desconto educacional/trial 30 dias)
Cross-platform: Windows, macOS, Linux
Recursos:
  - Suporte completo ao .NET 10 e C# 13
  - Debugging avançado
  - Refactoring inteligente
  - Profiling integrado
```

**Opção 3: Visual Studio Code**
```
Download: https://code.visualstudio.com/
Extensões essenciais:
  - C# Dev Kit (Microsoft)
  - C# (Microsoft)
  - NuGet Package Manager
  - .NET Core Test Explorer
```

#### Frontend (React/TypeScript)

**Recomendado: Visual Studio Code**

**Extensões Essenciais:**
```
1. ES7+ React/Redux/React-Native snippets
2. Prettier - Code formatter
3. ESLint
4. Thunder Client (para testar APIs)
5. Peacock (cores diferentes por workspace)
6. GitLens
```

### Ferramentas Utilitárias

**Make**
```bash
# Windows (via Chocolatey)
choco install make

# macOS
brew install make

# Linux
sudo apt install build-essential -y

# Validar
make --version
```

**.NET Tools**
```bash
# Entity Framework Core Tools (para migrations)
dotnet tool install --global dotnet-ef

# Code formatter
dotnet tool install --global dotnet-format

# Code analyzer
dotnet tool install --global dotnet-outdated-tool

# OpenAPI/Swagger Tools
dotnet tool install --global Swashbuckle.AspNetCore.Cli

# Database Migrations (Alternativa ao EF - FluentMigrator)
dotnet tool install --global FluentMigrator.DotNet.Cli

# Validar instalação
dotnet tool list --global
```

---

## 5. Estrutura de Diretórios

### Criar Estrutura

```bash
mkdir -p ~/Dev/WMS_Enterprise
cd ~/Dev/WMS_Enterprise

mkdir -p backend/cmd/{api,migrate,cli}
mkdir -p backend/internal/{adapters,domain,services,repositories,config}
mkdir -p backend/migrations
mkdir -p backend/tests/{fixtures,integration,unit}
mkdir -p frontend/src/{components,pages,hooks,store,services,styles,types}
mkdir -p frontend/public
mkdir -p docker
mkdir -p scripts
mkdir -p .github/workflows

touch docker-compose.yml
touch Makefile
touch .env.example
```

---

## 6. Arquivo docker-compose.yml

```yaml
version: '3.8'

services:
  postgres:
    image: postgres:15-alpine
    container_name: wms-postgres
    environment:
      POSTGRES_DB: ${DB_NAME:-wms_dev}
      POSTGRES_USER: ${DB_USER:-wms_user}
      POSTGRES_PASSWORD: ${DB_PASSWORD:-wms_password_dev}
    ports:
      - "5432:5432"
    volumes:
      - postgres_data:/var/lib/postgresql/data
    networks:
      - wms-network
    healthcheck:
      test: ["CMD-SHELL", "pg_isready -U ${DB_USER:-wms_user}"]
      interval: 10s
      timeout: 5s
      retries: 5

  redis:
    image: redis:7-alpine
    container_name: wms-redis
    ports:
      - "6379:6379"
    volumes:
      - redis_data:/data
    networks:
      - wms-network
    healthcheck:
      test: ["CMD", "redis-cli", "ping"]
      interval: 10s
      timeout: 5s
      retries: 5

  elasticsearch:
    image: docker.elastic.co/elasticsearch/elasticsearch:8.5.0
    container_name: wms-elasticsearch
    environment:
      - discovery.type=single-node
      - xpack.security.enabled=false
    ports:
      - "9200:9200"
    volumes:
      - elasticsearch_data:/usr/share/elasticsearch/data
    networks:
      - wms-network

  pgadmin:
    image: dpage/pgadmin4:latest
    container_name: wms-pgadmin
    environment:
      PGADMIN_DEFAULT_EMAIL: admin@wms.local
      PGADMIN_DEFAULT_PASSWORD: admin
    ports:
      - "5050:80"
    depends_on:
      - postgres
    networks:
      - wms-network

  redis-commander:
    image: rediscommander/redis-commander:latest
    container_name: wms-redis-commander
    environment:
      - REDIS_HOSTS=local:redis:6379
    ports:
      - "8081:8081"
    depends_on:
      - redis
    networks:
      - wms-network

volumes:
  postgres_data:
  redis_data:
  elasticsearch_data:

networks:
  wms-network:
    driver: bridge
```

---

## 7. Arquivo .env.example

```bash
DATABASE_URL=postgres://wms_user:wms_password_dev@localhost:5432/wms_dev
DB_HOST=localhost
DB_PORT=5432
DB_USER=wms_user
DB_PASSWORD=wms_password_dev
DB_NAME=wms_dev
DB_SSL_MODE=disable

REDIS_URL=redis://localhost:6379
REDIS_HOST=localhost
REDIS_PORT=6379

ELASTICSEARCH_URL=http://localhost:9200

API_PORT=8080
API_HOST=0.0.0.0
ENV=development
LOG_LEVEL=debug

VITE_API_URL=http://localhost:8080/api/v1
VITE_ENV=development

JWT_SECRET=your-super-secret-key-change-in-production
JWT_EXPIRATION=24h

PGADMIN_DEFAULT_EMAIL=admin@wms.local
PGADMIN_DEFAULT_PASSWORD=admin
```

---

## 8. Arquivo Makefile

```makefile
.PHONY: help setup install docker-up docker-down db-migrate db-seed \
        run-backend run-frontend test lint clean ps logs

help:
	@echo "WMS Enterprise Development Commands"
	@echo "===================================="
	@echo "make setup       - Initial setup"
	@echo "make install     - Install dependencies"
	@echo "make docker-up   - Start Docker services"
	@echo "make docker-down - Stop Docker services"
	@echo "make db-migrate  - Run database migrations"
	@echo "make db-seed     - Seed database"
	@echo "make run-backend - Start backend API"
	@echo "make run-frontend - Start frontend dev"
	@echo "make test        - Run tests"
	@echo "make lint        - Run linters"
	@echo "make clean       - Clean up"

setup: install docker-up db-migrate
	@echo "✅ Development environment ready!"

install:
	@echo "📦 Installing dependencies..."
	cd backend && go mod download
	cd frontend && npm install

docker-up:
	@echo "🐳 Starting Docker services..."
	docker-compose up -d

docker-down:
	@echo "🛑 Stopping Docker services..."
	docker-compose down

db-migrate:
	@echo "🔄 Running migrations..."
	migrate -path backend/migrations -database "$(DATABASE_URL)" up

db-seed:
	@echo "🌱 Seeding database..."
	cd backend && go run ./cmd/migrate/seed.go

run-backend:
	@echo "🚀 Starting backend..."
	cd backend && go run ./cmd/api/main.go

run-frontend:
	@echo "🚀 Starting frontend..."
	cd frontend && npm run dev

test:
	@echo "🧪 Running tests..."
	cd backend && go test -v ./...

lint:
	@echo "🔍 Running linters..."
	cd backend && golangci-lint run ./...

clean:
	@echo "🗑️  Cleaning up..."
	docker-compose down -v
	rm -rf backend/coverage.out
	rm -rf frontend/node_modules

ps:
	@echo "📊 Container status:"
	@docker-compose ps

logs:
	@echo "📋 Showing logs..."
	@docker-compose logs -f
```

---

## 9. Instalação Passo-a-Passo

### Passo 1: Preparar Ambiente
```bash
mkdir -p ~/Dev/WMS_Enterprise
cd ~/Dev/WMS_Enterprise
git init
```

### Passo 2: Copiar Arquivos de Configuração
```bash
cp .env.example .env.local
# Editar se necessário
```

### Passo 3: Instalar Dependências
```bash
cd backend && go mod download
cd ../frontend && npm install
```

### Passo 4: Iniciar Docker
```bash
docker-compose up -d
docker-compose ps  # Validar
```

### Passo 5: Setup Banco de Dados
```bash
make db-migrate
make db-seed  # (Opcional)
```

### Passo 6: Iniciar Backend
```bash
make run-backend
# Esperado: Server listening on :8080
```

### Passo 7: Iniciar Frontend (outro terminal)
```bash
make run-frontend
# Esperado: Local: http://localhost:5173/
```

---

## 10. Validação do Ambiente

```bash
# Testar Git
git --version

# Testar Docker
docker --version
docker-compose --version

# Testar Node
node --version
npm --version

# Testar Go
go version

# Testar PostgreSQL
psql -h localhost -U wms_user -d wms_dev -c "SELECT 1"

# Testar Redis
redis-cli ping
# Esperado: PONG

# Testar Backend
curl http://localhost:8080/api/v1/health

# Testar Frontend
curl http://localhost:5173
```

---

## 11. Portas Utilizadas

| Serviço | Porta | URL |
|---------|-------|-----|
| Backend API | 8080 | http://localhost:8080 |
| Frontend | 5173 | http://localhost:5173 |
| PostgreSQL | 5432 | localhost:5432 |
| Redis | 6379 | localhost:6379 |
| Elasticsearch | 9200 | http://localhost:9200 |
| PgAdmin | 5050 | http://localhost:5050 |
| Redis Commander | 8081 | http://localhost:8081 |

---

## 12. Troubleshooting

### Docker não inicia
```bash
# Windows/Mac: Abrir Docker Desktop
# Linux: sudo systemctl start docker

# Limpar e recomeçar
docker system prune -a --volumes
docker-compose up -d
```

### PostgreSQL não conecta
```bash
docker-compose logs postgres
docker-compose restart postgres
sleep 15
psql -h localhost -U wms_user -d wms_dev -c "SELECT 1"
```

### Porta já em uso
```bash
# Windows
netstat -ano | findstr :8080

# Mac/Linux
lsof -i :8080

# Matar processo
kill -9 <PID>
```

### Node modules corrompido
```bash
rm -rf frontend/node_modules
rm frontend/package-lock.json
npm install
```

---

## 13. Próximos Passos

1. **Explorar Interfaces**
   - PgAdmin: http://localhost:5050
   - Redis Commander: http://localhost:8081
   - Frontend: http://localhost:5173

2. **Criar Feature Branch**
   ```bash
   git checkout -b feature/WMS-001-setup
   ```

3. **Executar Testes**
   ```bash
   make test
   ```

4. **Estudar Documentação**
   - Ler CONTRIBUTING.md
   - Estudar Arquitetura
   - Entender Requisitos

---

## 14. Primeiro Teste: Hello World

### Backend

**Arquivo `backend/Program.cs`:**

```csharp
using Microsoft.AspNetCore.Builder;
using Microsoft.AspNetCore.Http;
using Microsoft.Extensions.DependencyInjection;
using Microsoft.Extensions.Hosting;

var builder = WebApplication.CreateBuilder(args);

// Add services to the container
builder.Services.AddEndpointsApiExplorer();
builder.Services.AddSwaggerGen();

var app = builder.Build();

// Configure the HTTP request pipeline
if (app.Environment.IsDevelopment())
{
    app.UseSwagger();
    app.UseSwaggerUI();
}

app.MapGet("/api/v1/health", () => Results.Ok(new
{
    status = "ok",
    service = "wms-api",
    timestamp = DateTime.UtcNow
}))
.WithName("Health")
.WithOpenApi();

app.Run("http://localhost:8080");
```

**Executar:**
```bash
cd backend
dotnet run

# Testar
curl http://localhost:8080/api/v1/health
# {"status":"ok","service":"wms-api","timestamp":"2025-01-16T10:30:00Z"}
```

### Frontend

**Arquivo `frontend/src/App.tsx`:**

```typescript
import { useEffect, useState } from 'react'

function App() {
  const [health, setHealth] = useState(null)

  useEffect(() => {
    fetch('http://localhost:8080/api/v1/health')
      .then(res => res.json())
      .then(setHealth)
  }, [])

  return (
    <div>
      <h1>WMS Enterprise</h1>
      {health ? <p>✅ Conectado!</p> : <p>Conectando...</p>}
    </div>
  )
}

export default App
```

**Executar:**
```bash
cd frontend
npm run dev

# Abrir http://localhost:5173
```

---

**Documento Versão:** 1.0  
**Status:** Completo e Pronto para Uso  
**Data:** Janeiro 2025  

🚀 **Bem-vindo ao desenvolvimento do WMS Enterprise!**
