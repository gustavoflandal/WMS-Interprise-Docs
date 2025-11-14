.PHONY: help setup install docker-up docker-down docker-logs docker-ps \
        db-create db-migrate db-seed db-reset \
        run-backend run-frontend test lint clean \
        docker-build docker-clean docker-prune \
        health-check

# ============================================================================
# VARIÁVEIS
# ============================================================================
DOCKER_COMPOSE := docker-compose
GO := go
NPM := npm
NODE := node

# ============================================================================
# TARGETS
# ============================================================================

help:
	@echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
	@echo "  WMS ENTERPRISE - Development Commands"
	@echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
	@echo ""
	@echo "  🚀 SETUP INICIAL"
	@echo "    make setup              Configurar ambiente de desenvolvimento (all-in-one)"
	@echo "    make install            Instalar dependências (Go + Node)"
	@echo ""
	@echo "  🐳 DOCKER"
	@echo "    make docker-up          Iniciar todos os serviços Docker"
	@echo "    make docker-down        Parar todos os serviços Docker"
	@echo "    make docker-restart     Reiniciar os serviços Docker"
	@echo "    make docker-ps          Status dos containers"
	@echo "    make docker-logs        Ver logs em tempo real"
	@echo "    make docker-build       Compilar imagens Docker"
	@echo "    make docker-clean       Remover containers parados"
	@echo "    make docker-prune       Limpar volumes e imagens não usadas"
	@echo ""
	@echo "  💾 BANCO DE DADOS"
	@echo "    make db-create          Criar banco de dados (schema vazio)"
	@echo "    make db-migrate         Executar migrações de banco de dados"
	@echo "    make db-seed            Popular banco com dados de teste"
	@echo "    make db-reset           Resetar banco de dados (drop + create + migrate)"
	@echo ""
	@echo "  🏃 EXECUÇÃO"
	@echo "    make run-backend        Iniciar servidor backend (porta 8080)"
	@echo "    make run-frontend       Iniciar servidor frontend (porta 5173)"
	@echo "    make run-all            Iniciar backend e frontend simultaneamente"
	@echo ""
	@echo "  ✅ VALIDAÇÃO"
	@echo "    make health-check       Verificar saúde de todos os serviços"
	@echo "    make test               Executar testes automatizados"
	@echo "    make lint               Executar linters de código"
	@echo "    make fmt                Formatar código"
	@echo ""
	@echo "  🧹 LIMPEZA"
	@echo "    make clean              Limpar diretórios de build"
	@echo "    make clean-all          Limpar tudo (docker + builds + deps)"
	@echo ""
	@echo "  📊 MONITORAMENTO"
	@echo "    make dashboard          Abrir Grafana (http://localhost:3000)"
	@echo "    make prometheus         Abrir Prometheus (http://localhost:9090)"
	@echo "    make jaeger             Abrir Jaeger UI (http://localhost:16686)"
	@echo "    make kafka-ui           Abrir Kafka UI (http://localhost:8080)"
	@echo "    make pgadmin            Abrir pgAdmin (http://localhost:5050)"
	@echo ""
	@echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

# ============================================================================
# SETUP INICIAL
# ============================================================================

setup: install docker-up db-migrate
	@echo ""
	@echo "✅ Ambiente de desenvolvimento configurado com sucesso!"
	@echo ""
	@echo "📝 Próximas ações:"
	@echo "   1. Abrir um novo terminal e executar: make run-backend"
	@echo "   2. Abrir outro terminal e executar: make run-frontend"
	@echo "   3. Acessar a aplicação em: http://localhost:5173"
	@echo ""

install:
	@echo "📦 Instalando dependências..."
	@echo ""
	@echo "  → Backend (Go)..."
	@cd backend && $(GO) mod download && $(GO) mod tidy
	@echo ""
	@echo "  → Frontend (Node)..."
	@cd frontend && $(NPM) install --legacy-peer-deps
	@echo ""
	@echo "✅ Dependências instaladas com sucesso!"

# ============================================================================
# DOCKER
# ============================================================================

docker-up:
	@echo "🐳 Iniciando serviços Docker..."
	@$(DOCKER_COMPOSE) up -d
	@echo ""
	@echo "⏳ Aguardando inicialização dos serviços..."
	@sleep 10
	@$(DOCKER_COMPOSE) ps
	@echo ""
	@echo "✅ Serviços Docker iniciados!"
	@echo ""
	@echo "📊 Interfaces disponíveis:"
	@echo "   - PostgreSQL: localhost:5432"
	@echo "   - Redis: localhost:6379"
	@echo "   - Elasticsearch: http://localhost:9200"
	@echo "   - Kafka: localhost:9092"
	@echo "   - Prometheus: http://localhost:9090"
	@echo "   - Grafana: http://localhost:3000"
	@echo "   - Jaeger: http://localhost:16686"
	@echo "   - Kafka UI: http://localhost:8080"
	@echo "   - pgAdmin: http://localhost:5050"
	@echo "   - Redis Commander: http://localhost:8081"

docker-down:
	@echo "🛑 Parando serviços Docker..."
	@$(DOCKER_COMPOSE) down
	@echo "✅ Serviços Docker parados!"

docker-restart: docker-down docker-up
	@echo "✅ Serviços Docker reiniciados!"

docker-ps:
	@echo "📊 Status dos containers:"
	@$(DOCKER_COMPOSE) ps

docker-logs:
	@echo "📋 Logs dos serviços (últimas 50 linhas):"
	@$(DOCKER_COMPOSE) logs --tail=50 -f

docker-build:
	@echo "🔨 Compilando imagens Docker..."
	@$(DOCKER_COMPOSE) build --no-cache

docker-clean:
	@echo "🧹 Removendo containers parados..."
	@docker container prune -f

docker-prune: docker-down
	@echo "🧹 Limpando volumes e imagens não usadas..."
	@docker system prune -a --volumes -f
	@echo "✅ Limpeza realizada!"

# ============================================================================
# BANCO DE DADOS
# ============================================================================

db-create:
	@echo "💾 Criando banco de dados..."
	@$(DOCKER_COMPOSE) exec -T postgres psql -U wms_user -d postgres -c "CREATE DATABASE wms_dev;" || true
	@echo "✅ Banco de dados criado!"

db-migrate:
	@echo "🔄 Executando migrações..."
	@if [ -f "backend/migrations/001_init.sql" ]; then \
		$(DOCKER_COMPOSE) exec -T postgres psql -U wms_user -d wms_dev < backend/migrations/001_init.sql; \
		echo "✅ Migrações executadas!"; \
	else \
		echo "⚠️  Diretório de migrações não encontrado em backend/migrations/"; \
	fi

db-seed:
	@echo "🌱 Populando banco de dados com dados de teste..."
	@if [ -f "backend/migrations/002_seed.sql" ]; then \
		$(DOCKER_COMPOSE) exec -T postgres psql -U wms_user -d wms_dev < backend/migrations/002_seed.sql; \
		echo "✅ Dados de teste inseridos!"; \
	else \
		echo "⚠️  Script de seed não encontrado em backend/migrations/002_seed.sql"; \
	fi

db-reset: docker-down
	@echo "🔄 Resetando banco de dados..."
	@docker volume rm wms_postgres_data || true
	@docker-compose up -d postgres
	@sleep 10
	@make db-migrate
	@echo "✅ Banco de dados resetado!"

db-shell:
	@echo "📋 Abrindo shell PostgreSQL..."
	@$(DOCKER_COMPOSE) exec postgres psql -U wms_user -d wms_dev

# ============================================================================
# EXECUÇÃO
# ============================================================================

run-backend:
	@echo "🚀 Iniciando backend API (porta 8080)..."
	@cd backend && $(GO) run ./cmd/api/main.go

run-frontend:
	@echo "🚀 Iniciando frontend (porta 5173)..."
	@cd frontend && $(NPM) run dev

run-all:
	@echo "🚀 Iniciando backend e frontend..."
	@echo "⚠️  Abra dois terminais diferentes e execute:"
	@echo "   Terminal 1: make run-backend"
	@echo "   Terminal 2: make run-frontend"

# ============================================================================
# VALIDAÇÃO
# ============================================================================

health-check:
	@echo "🏥 Verificando saúde dos serviços..."
	@echo ""
	@echo "  → PostgreSQL..."
	@$(DOCKER_COMPOSE) exec -T postgres pg_isready -U wms_user -d wms_dev && echo "     ✅ OK" || echo "     ❌ FALHA"
	@echo ""
	@echo "  → Redis..."
	@$(DOCKER_COMPOSE) exec -T redis redis-cli ping > /dev/null 2>&1 && echo "     ✅ OK" || echo "     ❌ FALHA"
	@echo ""
	@echo "  → Elasticsearch..."
	@curl -s http://localhost:9200/_cluster/health | grep -q '"status"' && echo "     ✅ OK" || echo "     ❌ FALHA"
	@echo ""
	@echo "  → Kafka..."
	@$(DOCKER_COMPOSE) exec -T kafka kafka-broker-api-versions.sh --bootstrap-server localhost:9092 > /dev/null 2>&1 && echo "     ✅ OK" || echo "     ❌ FALHA"
	@echo ""
	@echo "  → Prometheus..."
	@curl -s http://localhost:9090/-/healthy > /dev/null 2>&1 && echo "     ✅ OK" || echo "     ❌ FALHA"
	@echo ""
	@echo "  → Grafana..."
	@curl -s http://localhost:3000/api/health | grep -q '"status"' && echo "     ✅ OK" || echo "     ❌ FALHA"
	@echo ""

test:
	@echo "🧪 Executando testes..."
	@cd backend && $(GO) test -v -race -coverprofile=coverage.out ./...
	@echo "✅ Testes executados!"

lint:
	@echo "🔍 Executando linters..."
	@if command -v golangci-lint > /dev/null; then \
		cd backend && golangci-lint run ./...; \
	else \
		echo "⚠️  golangci-lint não instalado. Execute: go install github.com/golangci/golangci-lint/cmd/golangci-lint@latest"; \
	fi
	@echo "✅ Linting completado!"

fmt:
	@echo "✨ Formatando código..."
	@cd backend && $(GO) fmt ./...
	@cd frontend && $(NPM) run lint -- --fix 2>/dev/null || true
	@echo "✅ Código formatado!"

# ============================================================================
# MONITORAMENTO
# ============================================================================

dashboard:
	@echo "📊 Abrindo Grafana..."
	@echo "   URL: http://localhost:3000"
	@echo "   User: admin"
	@echo "   Password: admin"
	@if command -v xdg-open > /dev/null; then \
		xdg-open http://localhost:3000; \
	elif command -v open > /dev/null; then \
		open http://localhost:3000; \
	elif command -v start > /dev/null; then \
		start http://localhost:3000; \
	fi

prometheus:
	@echo "📊 Abrindo Prometheus..."
	@echo "   URL: http://localhost:9090"
	@if command -v xdg-open > /dev/null; then \
		xdg-open http://localhost:9090; \
	elif command -v open > /dev/null; then \
		open http://localhost:9090; \
	elif command -v start > /dev/null; then \
		start http://localhost:9090; \
	fi

jaeger:
	@echo "🔍 Abrindo Jaeger UI..."
	@echo "   URL: http://localhost:16686"
	@if command -v xdg-open > /dev/null; then \
		xdg-open http://localhost:16686; \
	elif command -v open > /dev/null; then \
		open http://localhost:16686; \
	elif command -v start > /dev/null; then \
		start http://localhost:16686; \
	fi

kafka-ui:
	@echo "📊 Abrindo Kafka UI..."
	@echo "   URL: http://localhost:8080"
	@if command -v xdg-open > /dev/null; then \
		xdg-open http://localhost:8080; \
	elif command -v open > /dev/null; then \
		open http://localhost:8080; \
	elif command -v start > /dev/null; then \
		start http://localhost:8080; \
	fi

pgadmin:
	@echo "💾 Abrindo pgAdmin..."
	@echo "   URL: http://localhost:5050"
	@echo "   Email: admin@wms.local"
	@echo "   Password: admin"
	@if command -v xdg-open > /dev/null; then \
		xdg-open http://localhost:5050; \
	elif command -v open > /dev/null; then \
		open http://localhost:5050; \
	elif command -v start > /dev/null; then \
		start http://localhost:5050; \
	fi

# ============================================================================
# LIMPEZA
# ============================================================================

clean:
	@echo "🗑️  Limpando diretórios de build..."
	@rm -rf backend/bin backend/build backend/coverage.out
	@rm -rf frontend/dist frontend/.parcel-cache
	@echo "✅ Limpeza realizada!"

clean-all: clean docker-prune
	@echo "🗑️  Limpeza completa..."
	@rm -rf backend/vendor backend/node_modules
	@rm -rf frontend/node_modules frontend/.next
	@rm -f .env.local .env.development
	@echo "✅ Limpeza completa realizada!"

# ============================================================================
# DEFAULT TARGET
# ============================================================================

.DEFAULT_GOAL := help
