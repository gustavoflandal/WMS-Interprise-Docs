# Correções Aplicadas na Implantação - WMS Enterprise

**Data:** 2025-11-14
**Versão:** 1.0

---

## 📋 Resumo

Este documento registra todas as correções aplicadas durante a implantação do ambiente de desenvolvimento do WMS Enterprise com Docker Compose. Use este guia como referência para evitar problemas em futuras implantações.

---

## 🔧 Correções Aplicadas

### 1. PostgreSQL - Configuração Inicial

**Problema:** O parâmetro `POSTGRES_INITDB_ARGS` não aceita flags `-c` para configuração do servidor.

**Erro:**
```
initdb: unrecognized option: c
initdb: hint: Try "initdb --help" for more information.
```

**Solução:** Mover as configurações do PostgreSQL para o parâmetro `command`.

**Arquivo:** `docker-compose.yml` (linhas 34-38)

**Antes:**
```yaml
environment:
  POSTGRES_DB: ${DB_NAME:-wms_dev}
  POSTGRES_USER: ${DB_USER:-wms_user}
  POSTGRES_PASSWORD: ${DB_PASSWORD:-wms_password_dev}
  POSTGRES_INITDB_ARGS: "-c max_connections=200 -c shared_buffers=256MB"
```

**Depois:**
```yaml
environment:
  POSTGRES_DB: ${DB_NAME:-wms_dev}
  POSTGRES_USER: ${DB_USER:-wms_user}
  POSTGRES_PASSWORD: ${DB_PASSWORD:-wms_password_dev}
command: postgres -c max_connections=200 -c shared_buffers=256MB
```

---

### 2. PostgreSQL - Extensão JSON Inexistente

**Problema:** A extensão "json" não existe no PostgreSQL porque JSON é um tipo nativo.

**Erro:**
```
ERROR: extension "json" is not available
DETAIL: Could not open extension control file "/usr/local/share/postgresql/extension/json.control"
```

**Solução:** Remover a linha que tenta criar a extensão "json".

**Arquivo:** `docker/postgres/init-scripts/001-init.sql` (linha 11)

**Antes:**
```sql
-- Habilitar extensões necessárias
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";
CREATE EXTENSION IF NOT EXISTS "pgcrypto";
CREATE EXTENSION IF NOT EXISTS "json";
CREATE EXTENSION IF NOT EXISTS "hstore";
```

**Depois:**
```sql
-- Habilitar extensões necessárias
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";
CREATE EXTENSION IF NOT EXISTS "pgcrypto";
CREATE EXTENSION IF NOT EXISTS "hstore";
```

---

### 3. PostgreSQL - Sintaxe de Índices em CREATE TABLE

**Problema:** No PostgreSQL, não é possível criar índices dentro da definição do `CREATE TABLE`. A sintaxe `INDEX` só funciona no MySQL.

**Erro:**
```
ERROR: syntax error at or near "DESC" at character 549
```

**Solução:** Remover as definições de índices de dentro do `CREATE TABLE` e criá-los separadamente na seção de índices.

**Arquivo:** `docker/postgres/init-scripts/001-init.sql`

**Antes (linhas 192-206):**
```sql
CREATE TABLE IF NOT EXISTS wms.inventory_transactions (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    inventory_id UUID NOT NULL REFERENCES wms.inventory_master(id),
    transaction_type VARCHAR(50) NOT NULL,
    quantity INT NOT NULL,
    quantity_before INT,
    quantity_after INT,
    reason TEXT,
    reference_id UUID,
    user_id UUID REFERENCES wms.users(id),
    created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    INDEX idx_inventory_type (inventory_id, transaction_type),
    INDEX idx_created (created_at DESC)
);
```

**Depois:**
```sql
-- Tabela sem índices inline
CREATE TABLE IF NOT EXISTS wms.inventory_transactions (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    inventory_id UUID NOT NULL REFERENCES wms.inventory_master(id),
    transaction_type VARCHAR(50) NOT NULL,
    quantity INT NOT NULL,
    quantity_before INT,
    quantity_after INT,
    reason TEXT,
    reference_id UUID,
    user_id UUID REFERENCES wms.users(id),
    created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP
);

-- Índices criados separadamente (linhas 428-430)
CREATE INDEX IF NOT EXISTS idx_inventory_trans_inventory ON wms.inventory_transactions(inventory_id, transaction_type);
CREATE INDEX IF NOT EXISTS idx_inventory_trans_created ON wms.inventory_transactions(created_at DESC);
```

**Mesmo problema na tabela `wms.audit_log` (linhas 388-400):**

**Antes:**
```sql
CREATE TABLE IF NOT EXISTS wms.audit_log (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    tenant_id UUID NOT NULL REFERENCES wms.tenants(id),
    user_id UUID REFERENCES wms.users(id),
    action VARCHAR(100) NOT NULL,
    entity_type VARCHAR(100) NOT NULL,
    entity_id UUID,
    old_values JSONB,
    new_values JSONB,
    ip_address INET,
    user_agent TEXT,
    created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    INDEX idx_entity (entity_type, entity_id),
    INDEX idx_created (created_at DESC)
);
```

**Depois:**
```sql
-- Tabela sem índices inline
CREATE TABLE IF NOT EXISTS wms.audit_log (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    tenant_id UUID NOT NULL REFERENCES wms.tenants(id),
    user_id UUID REFERENCES wms.users(id),
    action VARCHAR(100) NOT NULL,
    entity_type VARCHAR(100) NOT NULL,
    entity_id UUID,
    old_values JSONB,
    new_values JSONB,
    ip_address INET,
    user_agent TEXT,
    created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP
);

-- Índices criados separadamente (linhas 458-459)
CREATE INDEX IF NOT EXISTS idx_audit_entity ON wms.audit_log(entity_type, entity_id);
CREATE INDEX IF NOT EXISTS idx_audit_created ON wms.audit_log(created_at DESC);
```

---

### 4. Loki - Configuração Desatualizada

**Problema:** A configuração do Loki estava usando campos deprecados e incompatíveis com a versão mais recente.

**Erro:**
```
failed parsing config: /etc/loki/local-config.yaml: yaml: unmarshal errors:
  line 7: field max_streams_matcher_size not found in type ingester.Config
  line 8: field commit_timeout not found in type ingester.Config
  line 11: field enforce_metric_name not found in type validation.plain
  line 37: field shared_store not found in type boltdb.IndexCfg
  line 41: field max_look_back_period not found in type config.ChunkStoreConfig
```

**Solução:** Atualizar a configuração do Loki para usar o schema v13 com TSDB e a estrutura de configuração moderna.

**Arquivo:** `docker/loki/loki-config.yml`

**Configuração atualizada completa:**
```yaml
auth_enabled: false

server:
  http_listen_port: 3100
  log_level: info

common:
  path_prefix: /loki
  storage:
    filesystem:
      chunks_directory: /loki/chunks
      rules_directory: /loki/rules
  replication_factor: 1
  ring:
    kvstore:
      store: inmemory

schema_config:
  configs:
    - from: 2020-10-24
      store: tsdb
      object_store: filesystem
      schema: v13
      index:
        prefix: index_
        period: 24h

limits_config:
  reject_old_samples: true
  reject_old_samples_max_age: 168h
  ingestion_rate_mb: 8
  ingestion_burst_size_mb: 16
  max_cache_freshness_per_query: 10m
  split_queries_by_interval: 15m

query_range:
  align_queries_with_step: true
  max_retries: 5
  cache_results: true

ingester:
  chunk_idle_period: 3m
  chunk_retain_period: 1m
  max_chunk_age: 1h
  flush_check_period: 10s
  flush_op_timeout: 10s

table_manager:
  retention_deletes_enabled: false
  retention_period: 0s

compactor:
  working_directory: /loki/compactor
  compaction_interval: 10m
```

---

### 5. Promtail - Configuração Docker Deprecada

**Problema:** O Promtail não suporta mais o scrape config tipo `docker:` nas versões recentes.

**Erro:**
```
Unable to parse config: /etc/promtail/config.yml: yaml: unmarshal errors:
  line 14: field docker not found in type scrapeconfig.plain
```

**Solução:** Usar `static_configs` com paths para os logs dos containers Docker.

**Arquivo:** `docker/promtail/promtail-config.yml`

**Antes:**
```yaml
scrape_configs:
  - job_name: docker
    docker:
      host: unix:///var/run/docker.sock
      labels:
        container_name: ''
        image_name: ''
```

**Depois:**
```yaml
scrape_configs:
  # Docker container logs via static path
  - job_name: docker-logs
    static_configs:
      - targets:
          - localhost
        labels:
          job: docker
          __path__: /var/lib/docker/containers/*/*.log
    pipeline_stages:
      - json:
          expressions:
            log: log
            stream: stream
            time: time
      - timestamp:
          source: time
          format: RFC3339Nano
      - output:
          source: log
```

---

### 6. Promtail - Sintaxe Multiline Incorreta

**Problema:** O campo `line_start_pattern` foi renomeado para `firstline` no Promtail.

**Erro:**
```
error="failed to make file target manager: invalid multiline stage config: multiline stage config must define `firstline` regular expression"
```

**Solução:** Substituir `line_start_pattern` por `firstline`.

**Arquivo:** `docker/promtail/promtail-config.yml`

**Antes:**
```yaml
pipeline_stages:
  - multiline:
      line_start_pattern: '^\d{4}-\d{2}-\d{2}'
```

**Depois:**
```yaml
pipeline_stages:
  - multiline:
      firstline: '^\d{4}-\d{2}-\d{2}'
```

---

### 7. pgAdmin - Email Inválido

**Problema:** O pgAdmin não aceita domínios `.local` como válidos para email.

**Erro:**
```
'admin@wms.local' does not appear to be a valid email address.
The part after the @-sign is a special-use or reserved name that cannot be used with email.
```

**Solução:** Mudar o email padrão para um domínio válido como `.dev`.

**Arquivo:** `docker-compose.yml` (linha 277)

**Antes:**
```yaml
environment:
  PGADMIN_DEFAULT_EMAIL: ${PGADMIN_EMAIL:-admin@wms.local}
  PGADMIN_DEFAULT_PASSWORD: ${PGADMIN_PASSWORD:-admin}
```

**Depois:**
```yaml
environment:
  PGADMIN_DEFAULT_EMAIL: ${PGADMIN_EMAIL:-admin@wms.dev}
  PGADMIN_DEFAULT_PASSWORD: ${PGADMIN_PASSWORD:-admin}
```

---

## 🚀 Processo de Implantação Corrigido

### Comandos para Primeira Execução:

```bash
# 1. Subir todos os serviços
docker-compose up -d

# 2. Verificar o status
docker-compose ps

# 3. Verificar logs se necessário
docker-compose logs -f [nome-do-servico]

# 4. Parar todos os serviços
docker-compose down

# 5. Parar e remover volumes (resetar tudo)
docker-compose down -v
```

### Ordem de Inicialização dos Serviços:

1. **Infraestrutura base**: PostgreSQL, Redis, Zookeeper
2. **Mensageria**: Kafka (depende do Zookeeper)
3. **Busca**: Elasticsearch
4. **Monitoramento**: Prometheus, Loki
5. **Visualização**: Grafana (depende do Prometheus)
6. **GUIs**: pgAdmin, Redis Commander, Kafka UI
7. **Log Collection**: Promtail (depende do Loki)
8. **Tracing**: Jaeger

---

## ✅ Verificação de Saúde

Após inicializar, aguarde alguns minutos e verifique:

```bash
# Status geral
docker-compose ps

# Health checks específicos
docker inspect wms-postgres | grep -A 5 Health
docker inspect wms-redis | grep -A 5 Health
docker inspect wms-elasticsearch | grep -A 5 Health
```

### Serviços e suas Portas:

| Serviço | URL/Porta | Credenciais | Status Esperado |
|---------|-----------|-------------|-----------------|
| PostgreSQL | localhost:5432 | wms_user / wms_password_dev | healthy |
| pgAdmin | http://localhost:5050 | admin@wms.dev / admin | healthy |
| Redis | localhost:6379 | - | healthy |
| Redis Commander | http://localhost:8081 | - | healthy |
| Elasticsearch | http://localhost:9200 | - | healthy |
| Kafka | localhost:9092 | - | healthy |
| Kafka UI | http://localhost:8080 | - | healthy |
| Prometheus | http://localhost:9090 | - | healthy |
| Grafana | http://localhost:3000 | admin / admin | healthy |
| Loki | http://localhost:3100 | - | healthy |
| Jaeger | http://localhost:16686 | - | healthy |
| Zookeeper | localhost:2181 | - | running |
| Promtail | - | - | running |

---

## 🐛 Problemas Conhecidos e Soluções

### Promtail - Avisos de Logs Antigos

**Sintoma:** Logs do Promtail mostram erros sobre timestamps muito antigos:
```
entry has timestamp too old: 2024-XX-XX, oldest acceptable timestamp is: 2025-XX-XX
```

**Causa:** Promtail está tentando processar logs antigos de containers anteriores que excedem o limite de retenção do Loki (7 dias).

**Impacto:** Nenhum. Novos logs são processados normalmente.

**Solução (opcional):** Limpar logs antigos de containers:
```bash
# No Windows/Linux
docker system prune --volumes
```

---

### pgAdmin - Container Reiniciando Após Mudança de Email

**Sintoma:** Após alterar o `PGADMIN_DEFAULT_EMAIL`, o container continua com erro.

**Causa:** O volume do pgAdmin mantém a configuração antiga.

**Solução:**
```bash
docker-compose stop pgadmin
docker-compose rm -f pgadmin
docker volume rm wms-interprise-docs_pgadmin_data
docker-compose up -d pgadmin
```

---

### Kafka - Health Check Lento

**Sintoma:** Kafka demora para ficar "healthy".

**Causa:** Kafka precisa se conectar ao Zookeeper e inicializar os tópicos.

**Solução:** Aguardar 30-60 segundos após o Zookeeper estar rodando.

---

## 📝 Checklist de Implantação

Antes de executar `docker-compose up -d`, verifique:

- [ ] Todas as correções deste documento foram aplicadas
- [ ] Os arquivos de configuração estão no lugar correto:
  - [ ] `docker/postgres/init-scripts/001-init.sql`
  - [ ] `docker/loki/loki-config.yml`
  - [ ] `docker/promtail/promtail-config.yml`
  - [ ] `docker/prometheus/prometheus.yml`
  - [ ] `docker/grafana/provisioning/`
  - [ ] `docker/pgadmin/servers.json`
- [ ] Docker e Docker Compose estão instalados e rodando
- [ ] As portas necessárias estão livres (3000, 3100, 5050, 5432, 6379, 8080, 8081, 9090, 9200, etc.)
- [ ] Você tem recursos suficientes:
  - CPU: Mínimo 4 cores
  - RAM: Mínimo 8GB
  - Disco: Mínimo 20GB livres

---

## 🔄 Atualizações Futuras

Ao atualizar versões dos containers, verifique:

1. **Loki/Promtail**: Compatibilidade de schema e configuração
2. **PostgreSQL**: Migrações de versões maiores requerem dump/restore
3. **Elasticsearch**: Atualizações entre major versions precisam de cuidados especiais
4. **Kafka**: Verificar compatibilidade com Zookeeper

---

## 📞 Suporte

Em caso de problemas não documentados aqui:

1. Verificar logs do container específico: `docker logs wms-[nome-servico]`
2. Verificar configuração: `docker inspect wms-[nome-servico]`
3. Consultar documentação oficial do serviço
4. Criar issue no repositório do projeto

---

**Última atualização:** 2025-11-14
**Responsável:** Claude Code
**Versão Docker Compose:** 2.x
**Ambiente Testado:** Windows 11, Docker Desktop
