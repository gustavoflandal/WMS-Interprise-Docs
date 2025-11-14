# DEPLOYMENT, DEVOPS E INFRAESTRUTURA - WMS ENTERPRISE

## 1. Arquitetura de Infraestrutura

### 1.1 Multi-Region Deployment

```
┌─────────────────────────────────────────────────────────────┐
│              Global Load Balancer                            │
│              (AWS Route 53 / CloudFlare)                     │
└──────┬─────────────────────────────────────────────────────┘
       │
       ├─ Region 1: São Paulo (LATAM Primary)
       │  └─ Availability Zones: 3 (AZ-a, AZ-b, AZ-c)
       │
       ├─ Region 2: N. Virginia (USA Backup)
       │  └─ Availability Zones: 3
       │
       └─ Region 3: Frankfurt (Europe)
          └─ Availability Zones: 3
```

### 1.2 Stack de Infraestrutura

```
┌───────────────────────────────────────────────────────────┐
│ Cloud Provider: AWS / Azure / GCP                         │
├───────────────────────────────────────────────────────────┤
│ ▼ IaC (Infrastructure as Code)                            │
│  ├─ Terraform: VPC, RDS, Kubernetes, etc                 │
│  └─ Helm: Kubernetes charts para aplicações              │
│                                                            │
│ ▼ Kubernetes (EKS / AKS / GKE)                            │
│  ├─ Cluster: 1 por region (HA)                            │
│  ├─ Node Group: Auto-scaling, multiple AZ                │
│  └─ Add-ons: Ingress, monitoring, logging                │
│                                                            │
│ ▼ Service Mesh (Istio)                                    │
│  ├─ Traffic management                                    │
│  ├─ Security (mTLS)                                       │
│  └─ Observability                                         │
│                                                            │
│ ▼ Observability Stack                                     │
│  ├─ Metrics: Prometheus + Grafana                        │
│  ├─ Logs: ELK Stack / Loki                               │
│  ├─ Traces: Jaeger / DataDog                             │
│  └─ Alerts: Alertmanager                                 │
│                                                            │
└───────────────────────────────────────────────────────────┘
```

---

## 2. Containerização

### 2.1 Dockerfile (Multi-stage)

```dockerfile
# Stage 1: Build
FROM golang:1.22-alpine AS builder

WORKDIR /app
COPY go.mod go.sum ./
RUN go mod download

COPY . .
RUN CGO_ENABLED=0 GOOS=linux GOARCH=amd64 go build \
    -ldflags="-w -s" \
    -o /app/wms-server \
    ./cmd/server/main.go

# Stage 2: Runtime (Minimal)
FROM alpine:3.19

RUN apk add --no-cache ca-certificates tzdata

WORKDIR /app

# Copy apenas binário do stage anterior
COPY --from=builder /app/wms-server .

# Non-root user por segurança
RUN addgroup -g 1000 appuser && \
    adduser -D -u 1000 -G appuser appuser

USER appuser

EXPOSE 8080
HEALTHCHECK --interval=30s --timeout=5s --start-period=5s --retries=3 \
  CMD ["/app/wms-server", "health"]

ENTRYPOINT ["/app/wms-server"]
```

### 2.2 Docker Compose (Local Development)

```yaml
version: '3.9'

services:
  postgres:
    image: postgres:16-alpine
    environment:
      POSTGRES_DB: wms_dev
      POSTGRES_USER: wms_user
      POSTGRES_PASSWORD: dev_password
    ports:
      - "5432:5432"
    volumes:
      - postgres_data:/var/lib/postgresql/data
    healthcheck:
      test: ["CMD-SHELL", "pg_isready -U wms_user"]
      interval: 10s
      timeout: 5s
      retries: 5

  redis:
    image: redis:7-alpine
    ports:
      - "6379:6379"
    healthcheck:
      test: ["CMD", "redis-cli", "ping"]
      interval: 10s
      timeout: 5s
      retries: 5

  kafka:
    image: confluentinc/cp-kafka:7.5.0
    environment:
      KAFKA_BROKER_ID: 1
      KAFKA_ZOOKEEPER_CONNECT: zookeeper:2181
      KAFKA_ADVERTISED_LISTENERS: PLAINTEXT://kafka:29092,PLAINTEXT_HOST://kafka:9092
      KAFKA_LISTENER_SECURITY_PROTOCOL_MAP: PLAINTEXT:PLAINTEXT,PLAINTEXT_HOST:PLAINTEXT
      KAFKA_INTER_BROKER_LISTENER_NAME: PLAINTEXT
      KAFKA_OFFSETS_TOPIC_REPLICATION_FACTOR: 1
    depends_on:
      - zookeeper
    ports:
      - "9092:9092"

  wms-api:
    build:
      context: .
      dockerfile: Dockerfile
    environment:
      DATABASE_URL: postgresql://wms_user:dev_password@postgres:5432/wms_dev
      REDIS_URL: redis://redis:6379
      KAFKA_BROKERS: kafka:9092
    ports:
      - "8080:8080"
    depends_on:
      postgres:
        condition: service_healthy
      redis:
        condition: service_healthy
    volumes:
      - .:/app

volumes:
  postgres_data:
```

---

## 3. Kubernetes Deployment

### 3.1 Namespace Structure

```yaml
# Namespaces por ambiente
apiVersion: v1
kind: Namespace
metadata:
  name: wms-prod
  labels:
    environment: production
---
apiVersion: v1
kind: Namespace
metadata:
  name: wms-staging
  labels:
    environment: staging
---
apiVersion: v1
kind: Namespace
metadata:
  name: wms-dev
  labels:
    environment: development
```

### 3.2 Deployment Example

```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: wms-api
  namespace: wms-prod
  labels:
    app: wms-api
    version: v1
spec:
  replicas: 3
  strategy:
    type: RollingUpdate
    rollingUpdate:
      maxSurge: 1
      maxUnavailable: 0  # Zero downtime
  
  selector:
    matchLabels:
      app: wms-api
  
  template:
    metadata:
      labels:
        app: wms-api
        version: v1
    
    spec:
      # Anti-affinity para distribuir pods
      affinity:
        podAntiAffinity:
          preferredDuringSchedulingIgnoredDuringExecution:
          - weight: 100
            podAffinityTerm:
              labelSelector:
                matchExpressions:
                - key: app
                  operator: In
                  values:
                  - wms-api
              topologyKey: kubernetes.io/hostname
      
      # Service account com permissões
      serviceAccountName: wms-api
      
      containers:
      - name: wms-api
        image: wms-registry/wms-api:v1.2.3
        imagePullPolicy: IfNotPresent
        
        ports:
        - name: http
          containerPort: 8080
          protocol: TCP
        
        # Variáveis de ambiente
        env:
        - name: ENVIRONMENT
          value: "production"
        - name: LOG_LEVEL
          value: "INFO"
        - name: DATABASE_URL
          valueFrom:
            secretKeyRef:
              name: wms-secrets
              key: database-url
        
        # Health checks
        livenessProbe:
          httpGet:
            path: /health/live
            port: 8080
          initialDelaySeconds: 30
          periodSeconds: 10
          failureThreshold: 3
        
        readinessProbe:
          httpGet:
            path: /health/ready
            port: 8080
          initialDelaySeconds: 10
          periodSeconds: 5
          failureThreshold: 3
        
        # Resource limits
        resources:
          requests:
            cpu: "500m"
            memory: "512Mi"
          limits:
            cpu: "2000m"
            memory: "2Gi"
        
        # Security context
        securityContext:
          runAsNonRoot: true
          runAsUser: 1000
          readOnlyRootFilesystem: true
          capabilities:
            drop:
            - ALL
        
        # Volume mounts
        volumeMounts:
        - name: tmp
          mountPath: /tmp
        - name: cache
          mountPath: /app/cache
      
      volumes:
      - name: tmp
        emptyDir: {}
      - name: cache
        emptyDir: {}
```

### 3.3 Service & Ingress

```yaml
---
apiVersion: v1
kind: Service
metadata:
  name: wms-api
  namespace: wms-prod
  labels:
    app: wms-api
spec:
  type: ClusterIP
  ports:
  - port: 80
    targetPort: 8080
    protocol: TCP
    name: http
  selector:
    app: wms-api

---
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  name: wms-api-ingress
  namespace: wms-prod
  annotations:
    cert-manager.io/cluster-issuer: "letsencrypt-prod"
    nginx.ingress.kubernetes.io/rate-limit: "100"
spec:
  ingressClassName: nginx
  tls:
  - hosts:
    - api.wms.example.com
    secretName: wms-api-tls
  rules:
  - host: api.wms.example.com
    http:
      paths:
      - path: /
        pathType: Prefix
        backend:
          service:
            name: wms-api
            port:
              number: 80
```

---

## 4. CI/CD Pipeline

### 4.1 GitHub Actions Workflow

```yaml
# .github/workflows/deploy.yml
name: Deploy WMS

on:
  push:
    branches:
      - main
      - develop
  pull_request:
    branches:
      - main

jobs:
  test:
    runs-on: ubuntu-latest
    services:
      postgres:
        image: postgres:16-alpine
        env:
          POSTGRES_DB: wms_test
          POSTGRES_USER: test_user
          POSTGRES_PASSWORD: test_pass
        options: >-
          --health-cmd pg_isready
          --health-interval 10s
          --health-timeout 5s
          --health-retries 5
        ports:
          - 5432:5432
    
    steps:
    - uses: actions/checkout@v3
    
    - name: Set up Go
      uses: actions/setup-go@v4
      with:
        go-version: '1.22'
    
    - name: Cache Go modules
      uses: actions/cache@v3
      with:
        path: ~/go/pkg/mod
        key: ${{ runner.os }}-go-${{ hashFiles('**/go.sum') }}
        restore-keys: |
          ${{ runner.os }}-go-
    
    - name: Run tests
      env:
        DATABASE_URL: postgresql://test_user:test_pass@localhost:5432/wms_test
      run: |
        go test -v -race -coverprofile=coverage.out ./...
    
    - name: Upload coverage
      uses: codecov/codecov-action@v3
      with:
        files: ./coverage.out
    
    - name: SAST - SonarQube
      uses: SonarSource/sonarcloud-github-action@master
      env:
        GITHUB_TOKEN: ${{ secrets.GITHUB_TOKEN }}
        SONAR_TOKEN: ${{ secrets.SONAR_TOKEN }}

  build:
    needs: test
    runs-on: ubuntu-latest
    if: github.ref == 'refs/heads/main'
    
    steps:
    - uses: actions/checkout@v3
    
    - name: Set up Docker Buildx
      uses: docker/setup-buildx-action@v2
    
    - name: Login to Registry
      uses: docker/login-action@v2
      with:
        registry: ${{ secrets.DOCKER_REGISTRY }}
        username: ${{ secrets.DOCKER_USERNAME }}
        password: ${{ secrets.DOCKER_PASSWORD }}
    
    - name: Build and push
      uses: docker/build-push-action@v4
      with:
        context: .
        push: true
        tags: |
          ${{ secrets.DOCKER_REGISTRY }}/wms-api:${{ github.sha }}
          ${{ secrets.DOCKER_REGISTRY }}/wms-api:latest
        cache-from: type=registry,ref=${{ secrets.DOCKER_REGISTRY }}/wms-api:buildcache
        cache-to: type=registry,ref=${{ secrets.DOCKER_REGISTRY }}/wms-api:buildcache,mode=max

  deploy:
    needs: build
    runs-on: ubuntu-latest
    if: github.ref == 'refs/heads/main'
    
    steps:
    - uses: actions/checkout@v3
    
    - name: Deploy to Kubernetes
      uses: azure/k8s-deploy@v4
      with:
        manifests: |
          k8s/deployment.yaml
          k8s/service.yaml
          k8s/ingress.yaml
        images: |
          ${{ secrets.DOCKER_REGISTRY }}/wms-api:${{ github.sha }}
        namespace: wms-prod
```

---

## 5. Database Deployment

### 5.1 RDS (AWS) Configuration

```hcl
# terraform/rds.tf
resource "aws_db_instance" "wms_postgres" {
  identifier     = "wms-postgres"
  engine         = "postgres"
  engine_version = "16.1"
  instance_class = "db.r6i.2xlarge"
  
  # Storage
  allocated_storage    = 500  # GB
  storage_type         = "gp3"
  storage_encrypted    = true
  iops                = 3000
  
  # Backup
  backup_retention_period = 30
  backup_window          = "03:00-04:00"
  skip_final_snapshot    = false
  final_snapshot_identifier = "wms-postgres-final-${formatdate("YYYY-MM-DD-hhmm", timestamp())}"
  
  # High Availability
  multi_az            = true
  publicly_accessible = false
  
  # Network
  db_subnet_group_name   = aws_db_subnet_group.wms.name
  vpc_security_group_ids = [aws_security_group.wms_db.id]
  
  # Authentication
  db_name  = "wms"
  username = "wmsadmin"
  password = random_password.db_password.result
  
  # Monitoring
  enable_cloudwatch_logs_exports = ["postgresql"]
  monitoring_interval            = 60
  monitoring_role_arn            = aws_iam_role.rds_monitoring.arn
  
  # Performance Insights
  performance_insights_enabled    = true
  performance_insights_retention_period = 7
  
  # Parameter group customizado
  parameter_group_name = aws_db_parameter_group.wms.name
}

# Read replica para reports
resource "aws_db_instance" "wms_postgres_replica" {
  identifier     = "wms-postgres-replica"
  replicate_source_db = aws_db_instance.wms_postgres.identifier
  instance_class = "db.r6i.xlarge"
  
  availability_zone = "us-east-1b"  # Diferente da primary
  
  skip_final_snapshot = false
}
```

### 5.2 Migration Strategy

```bash
# 1. Usar Flyway para migrations
# migrations/
# ├── V1__initial_schema.sql
# ├── V2__add_audit_table.sql
# └── V3__create_indexes.sql

# 2. Flyway em container
docker run --rm \
  -v $(pwd)/migrations:/flyway/sql \
  -e FLYWAY_URL=jdbc:postgresql://localhost:5432/wms \
  -e FLYWAY_USER=wmsadmin \
  -e FLYWAY_PASSWORD=$DB_PASS \
  flyway/flyway:9.0 migrate

# 3. Blue-green deployment
# - Deploy em DB nova
# - Testar
# - Switchover traffic
# - Keep old DB for rollback
```

---

## 6. Monitoring & Alerting

### 6.1 Prometheus Rules

```yaml
# monitoring/prometheus-rules.yaml
groups:
- name: wms-app
  interval: 30s
  rules:
  
  # Alert: Taxa de erro alta
  - alert: HighErrorRate
    expr: rate(http_requests_total{status=~"5.."}[5m]) > 0.05
    for: 5m
    annotations:
      summary: "Taxa de erro alta em {{ $labels.instance }}"
      description: "{{ $value | humanizePercentage }} de requisições falhando"
  
  # Alert: Latência alta
  - alert: HighLatency
    expr: histogram_quantile(0.95, http_request_duration_seconds_bucket) > 1
    for: 5m
    annotations:
      summary: "P95 latência > 1s"
  
  # Alert: DB lentão
  - alert: SlowDatabase
    expr: pg_stat_statements_mean_time > 1000  # ms
    for: 10m
    annotations:
      summary: "Queries PostgreSQL lentas"
  
  # Alert: Fila de eventos cresce
  - alert: KafkaLagHigh
    expr: kafka_consumer_lag > 10000
    for: 5m
    annotations:
      summary: "Consumer lag alto em {{ $labels.topic }}"
```

### 6.2 Grafana Dashboards

```
Dashboards pré-configurados:
├── System Overview
│   └─ CPU, Memory, Disk, Network
├── Application Metrics
│   └─ Request rate, Latency, Error rate
├── Database Performance
│   └─ Connections, Slow queries, Transactions
├── Message Queue
│   └─ Producer/Consumer lag, Throughput
└── Business Metrics
    └─ Orders/hour, Picking efficiency, etc
```

---

## 7. Disaster Recovery

### 7.1 RTO & RPO

```
Objetivo de Tempo de Recuperação (RTO): < 30 minutos
Objetivo de Ponto de Recuperação (RPO): < 1 minuto

Estratégia:
├── Backup automático a cada 15 minutos
├── Replicação síncrona em standby (outro AZ)
├── Failover automático em < 2 minutos
└── Restore testado mensalmente
```

### 7.2 Backup & Restore

```bash
# Backup manual
pg_dump -U wmsadmin -h localhost wms | gzip > wms_backup_$(date +%Y%m%d).sql.gz

# Restore
gunzip < wms_backup_20240115.sql.gz | psql -U wmsadmin -h localhost wms

# Backup to S3 (daily)
aws s3 sync /backups/ s3://wms-backups/ --sse AES256

# Restore from S3
aws s3 cp s3://wms-backups/wms_backup_20240115.sql.gz .
```

---

## 8. Scaling

### 8.1 Horizontal Scaling (Auto-scaling)

```yaml
apiVersion: autoscaling/v2
kind: HorizontalPodAutoscaler
metadata:
  name: wms-api-hpa
  namespace: wms-prod
spec:
  scaleTargetRef:
    apiVersion: apps/v1
    kind: Deployment
    name: wms-api
  
  minReplicas: 3
  maxReplicas: 20
  
  metrics:
  - type: Resource
    resource:
      name: cpu
      target:
        type: Utilization
        averageUtilization: 70  # Scale up se > 70%
  
  - type: Resource
    resource:
      name: memory
      target:
        type: Utilization
        averageUtilization: 80
  
  behavior:
    scaleUp:
      stabilizationWindowSeconds: 60
      policies:
      - type: Percent
        value: 50  # Max 50% aumento por minuto
        periodSeconds: 60
    
    scaleDown:
      stabilizationWindowSeconds: 300
      policies:
      - type: Percent
        value: 10
        periodSeconds: 60
```

### 8.2 Database Scaling

```
Read-heavy queries: Use read replicas
Write-heavy: Sharding por tenant/warehouse
Cache: Redis cluster (não sobrecarrega DB)
Archival: Move old data para cold storage
```

---

## 9. Post-deployment Checks

```bash
#!/bin/bash
# deployment/post-deploy-checks.sh

echo "=== Post-Deployment Health Checks ==="

# 1. Verificar pods estão saudáveis
echo "Checking pod health..."
kubectl get pods -n wms-prod | grep -v Running && exit 1

# 2. Verificar endpoints
echo "Checking endpoints..."
curl -f https://api.wms.example.com/health/ready || exit 1

# 3. Smoke test de API
echo "Running smoke tests..."
./tests/smoke-tests.sh || exit 1

# 4. Verificar metricas normais
echo "Checking metrics..."
curl -s https://prometheus.wms.example.com/api/v1/query?query='up{job="wms-api"}' | grep '"value":1' || exit 1

# 5. Rollback se falhar
if [ $? -ne 0 ]; then
  echo "Post-deployment checks FAILED. Initiating rollback..."
  kubectl rollout undo deployment/wms-api -n wms-prod
  exit 1
fi

echo "=== All checks passed! ==="
```

---

**Documento Versão:** 1.0  
**Status:** Infraestrutura Desenhada  
**Próximo Passo:** Configurar ambientes e testar deployment
