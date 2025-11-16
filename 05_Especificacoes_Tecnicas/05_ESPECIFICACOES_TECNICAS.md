# ESPECIFICAÇÕES TÉCNICAS - WMS ENTERPRISE

## 1. Stack de Desenvolvimento Recomendado

### 1.1 Backend

#### Opção Recomendada: .NET 10 (C# 13)

**Justificativa:**
- Performance de última geração com compilação Native AOT otimizada
- Ecossistema maduro e enterprise-ready
- Async/await e Task-based async pattern altamente otimizados
- Tooling robusto com Visual Studio 2022 e JetBrains Rider
- Forte tipagem com melhorias em nullable reference types e pattern matching
- Suporte LTS (Long-Term Support) com atualizações até 2027
- Melhorias significativas em performance e memory footprint
- Record types e init-only properties para imutabilidade
- File-scoped namespaces e global usings para código mais limpo
- Ecossistema rico para cloud-native e sistemas distribuídos

**Stack Principal:**
```
Language: C# 13 / .NET 10
Framework: ASP.NET Core 10 (Minimal APIs ou Controllers)
Event Bus: MassTransit 8.x + Kafka/RabbitMQ
ORM: Entity Framework Core 10 / Dapper 2.x (para queries de alta performance)
Logging: Serilog 4.x + Seq/Loki/OpenTelemetry
Testing: xUnit 2.x / NUnit 4.x + FluentAssertions 7.x
Build: MSBuild / dotnet CLI + Docker
Serialization: System.Text.Json (built-in, high performance)
```

#### Alternativa: Node.js (TypeScript)

**Justificativa:**
- Mesma linguagem no frontend e backend
- Excelente para I/O assíncrono
- Ecossistema npm muito rico

**Stack:**
```
Framework: NestJS / Fastify
Database: Prisma ORM / TypeORM
Testing: Jest + Supertest
```

### 1.2 Frontend

#### Web Application

```
Framework: React 18+ com TypeScript
State Management: Redux Toolkit + RTK Query
UI Library: Material-UI v5 / shadcn/ui
Build Tool: Vite
Testing: Vitest + React Testing Library
E2E: Cypress / Playwright
Code Quality: ESLint + Prettier
```

#### Mobile Application

```
Framework: React Native / Expo
State: Redux Persist
Native Modules: Camera (QR code), Location, Vibration
Build: Fastlane para CI/CD
```

### 1.3 DevOps & Infrastructure

```
Containerization: Docker 24+
Orchestration: Kubernetes 1.28+
Service Mesh: Istio 1.17+
Package Manager: Helm 3+
Config Management: Kustomize / Helm
CI/CD: GitLab CI / GitHub Actions
IaC: Terraform / Pulumi
Monitoring: Prometheus + Grafana
Logging: ELK Stack / Loki
APM: Jaeger / DataDog
```

---

## 2. Padrões de Código e Arquitetura

### 2.1 Project Structure (.NET 10)

```
wms-backend/
├── src/
│   ├── WMS.API/                    # Web API Entry Point
│   │   ├── Program.cs              # Entry point & configuration
│   │   ├── appsettings.json
│   │   ├── Controllers/            # API Controllers (ou Endpoints se Minimal API)
│   │   ├── Middleware/             # HTTP middleware
│   │   │   ├── AuthenticationMiddleware.cs
│   │   │   ├── LoggingMiddleware.cs
│   │   │   ├── ExceptionHandlerMiddleware.cs
│   │   │   └── RateLimitingMiddleware.cs
│   │   └── WMS.API.csproj
│   │
│   ├── WMS.Domain/                 # Domain Layer (Entities, Interfaces)
│   │   ├── Entities/               # Domain models
│   │   ├── Interfaces/             # Repository & Service interfaces
│   │   ├── ValueObjects/           # Value objects
│   │   ├── Events/                 # Domain events
│   │   └── WMS.Domain.csproj
│   │
│   ├── WMS.Application/            # Application Layer (Use Cases)
│   │   ├── UseCases/
│   │   │   ├── Inbound/
│   │   │   ├── Picking/
│   │   │   ├── Shipping/
│   │   │   └── ...
│   │   ├── DTOs/                   # Data Transfer Objects
│   │   ├── Mappings/               # AutoMapper profiles
│   │   ├── Validators/             # FluentValidation
│   │   └── WMS.Application.csproj
│   │
│   ├── WMS.Infrastructure/         # Infrastructure Layer
│   │   ├── Persistence/            # Database implementation
│   │   │   ├── ApplicationDbContext.cs
│   │   │   ├── Repositories/
│   │   │   └── Configurations/     # EF Core entity configurations
│   │   ├── Caching/                # Redis implementation
│   │   ├── Messaging/              # Kafka/RabbitMQ implementation
│   │   ├── ExternalServices/       # Integrations
│   │   └── WMS.Infrastructure.csproj
│   │
│   └── WMS.Shared/                 # Shared utilities
│       ├── Extensions/
│       ├── Helpers/
│       └── WMS.Shared.csproj
│
├── tests/
│   ├── WMS.UnitTests/
│   ├── WMS.IntegrationTests/
│   └── WMS.E2ETests/
│
├── docker/                         # Docker files
├── k8s/                           # Kubernetes manifests
├── .github/workflows/             # CI/CD
├── migrations/                    # EF Core migrations ou SQL scripts
├── WMS.sln                        # Solution file
├── Dockerfile
├── docker-compose.yml
├── .editorconfig
└── Directory.Build.props
```

### 2.2 Padrões de Design Aplicados

#### Domain-Driven Design (DDD)

```csharp
// WMS.Domain/Entities/Order.cs
namespace WMS.Domain.Entities;

public class Order : BaseEntity
{
    public Guid Id { get; private set; }
    public OrderNumber Number { get; private set; }
    public OrderStatus Status { get; private set; }
    public List<OrderLine> Lines { get; private set; } = new();

    // Private constructor para forçar uso de Factory Method
    private Order() { }

    public static Order Create(OrderNumber number, Guid tenantId)
    {
        var order = new Order
        {
            Id = Guid.NewGuid(),
            Number = number,
            Status = OrderStatus.New,
            TenantId = tenantId,
            CreatedAt = DateTime.UtcNow
        };

        order.AddDomainEvent(new OrderCreatedEvent(order.Id));
        return order;
    }

    // Métodos de Domínio
    public Result Pick(OrderLine line)
    {
        if (Status != OrderStatus.New)
        {
            return Result.Failure($"Cannot pick order with status {Status}");
        }

        Lines.Add(line);
        Status = OrderStatus.Picked;
        AddDomainEvent(new OrderPickedEvent(Id, line.Id));

        return Result.Success();
    }
}

// WMS.Domain/ValueObjects/OrderNumber.cs
public record OrderNumber
{
    public string Value { get; }

    private OrderNumber(string value) => Value = value;

    public static Result<OrderNumber> Create(string value)
    {
        if (string.IsNullOrWhiteSpace(value))
        {
            return Result<OrderNumber>.Failure("Order number is required");
        }

        if (value.Length > 50)
        {
            return Result<OrderNumber>.Failure("Order number too long");
        }

        return Result<OrderNumber>.Success(new OrderNumber(value));
    }
}

// WMS.Domain/Enums/OrderStatus.cs
public enum OrderStatus
{
    New,
    Picked,
    Packed,
    Shipped,
    Cancelled
}
```

#### Repository Pattern

```csharp
// WMS.Domain/Interfaces/IOrderRepository.cs
namespace WMS.Domain.Interfaces;

public interface IOrderRepository : IRepository<Order>
{
    Task<Order?> GetByIdAsync(Guid id, CancellationToken cancellationToken = default);
    Task<Order?> GetByNumberAsync(OrderNumber number, CancellationToken cancellationToken = default);
    Task<PagedResult<Order>> ListAsync(OrderFilter filter, CancellationToken cancellationToken = default);
    Task AddAsync(Order order, CancellationToken cancellationToken = default);
    Task UpdateAsync(Order order, CancellationToken cancellationToken = default);
    Task DeleteAsync(Order order, CancellationToken cancellationToken = default);
}

// WMS.Infrastructure/Persistence/Repositories/OrderRepository.cs
namespace WMS.Infrastructure.Persistence.Repositories;

public class OrderRepository : IOrderRepository
{
    private readonly ApplicationDbContext _context;

    public OrderRepository(ApplicationDbContext context)
    {
        _context = context;
    }

    public async Task<Order?> GetByIdAsync(Guid id, CancellationToken cancellationToken = default)
    {
        return await _context.Orders
            .Include(o => o.Lines)
            .FirstOrDefaultAsync(o => o.Id == id, cancellationToken);
    }

    public async Task<Order?> GetByNumberAsync(OrderNumber number, CancellationToken cancellationToken = default)
    {
        return await _context.Orders
            .Include(o => o.Lines)
            .FirstOrDefaultAsync(o => o.Number == number, cancellationToken);
    }

    public async Task AddAsync(Order order, CancellationToken cancellationToken = default)
    {
        await _context.Orders.AddAsync(order, cancellationToken);
        await _context.SaveChangesAsync(cancellationToken);
    }
}
```

#### Service Layer

```csharp
// WMS.Application/UseCases/Picking/IPickingService.cs
namespace WMS.Application.UseCases.Picking;

public interface IPickingService
{
    Task<Result<PickingOrder>> CreatePickingOrderAsync(
        CreatePickingOrderCommand command,
        CancellationToken cancellationToken = default);

    Task<Result> CompletePickingOrderAsync(
        CompletePickingOrderCommand command,
        CancellationToken cancellationToken = default);
}

// WMS.Application/UseCases/Picking/PickingService.cs
public class PickingService : IPickingService
{
    private readonly IOrderRepository _orderRepository;
    private readonly IPickingOrderRepository _pickingRepository;
    private readonly IEventPublisher _eventPublisher;
    private readonly ILogger<PickingService> _logger;

    public PickingService(
        IOrderRepository orderRepository,
        IPickingOrderRepository pickingRepository,
        IEventPublisher eventPublisher,
        ILogger<PickingService> logger)
    {
        _orderRepository = orderRepository;
        _pickingRepository = pickingRepository;
        _eventPublisher = eventPublisher;
        _logger = logger;
    }

    public async Task<Result<PickingOrder>> CreatePickingOrderAsync(
        CreatePickingOrderCommand command,
        CancellationToken cancellationToken = default)
    {
        try
        {
            // Validação
            var order = await _orderRepository.GetByIdAsync(command.OrderId, cancellationToken);
            if (order == null)
            {
                return Result<PickingOrder>.Failure($"Order not found: {command.OrderId}");
            }

            // Lógica de negócio
            var pickingOrder = PickingOrder.Create(order, command);
            if (pickingOrder.IsFailure)
            {
                return Result<PickingOrder>.Failure(pickingOrder.Error);
            }

            // Persistência
            await _pickingRepository.AddAsync(pickingOrder.Value, cancellationToken);

            // Publicar eventos de domínio
            foreach (var domainEvent in pickingOrder.Value.DomainEvents)
            {
                await _eventPublisher.PublishAsync(domainEvent, cancellationToken);
            }

            _logger.LogInformation("Picking order {PickingOrderId} created for order {OrderId}",
                pickingOrder.Value.Id, command.OrderId);

            return Result<PickingOrder>.Success(pickingOrder.Value);
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "Error creating picking order for order {OrderId}", command.OrderId);
            return Result<PickingOrder>.Failure($"Failed to create picking order: {ex.Message}");
        }
    }
}
```

---

## 3. API REST Specification

### 3.1 Convenções

- **Versionamento:** /api/v1/
- **Autenticação:** Bearer Token (JWT)
- **Content-Type:** application/json
- **Rate Limiting:** 1000 req/min por usuário
- **Paginação:** cursor-based para dados grandes

### 3.2 Estrutura de Resposta

```json
// Sucesso
{
    "success": true,
    "data": {
        "id": "uuid",
        "name": "...",
        // ...
    },
    "meta": {
        "timestamp": "2024-01-15T10:30:00Z",
        "request_id": "req-123456"
    }
}

// Lista com Paginação
{
    "success": true,
    "data": [
        { "id": "uuid1", ... },
        { "id": "uuid2", ... }
    ],
    "pagination": {
        "cursor_next": "base64_cursor",
        "total_count": 1000,
        "page_size": 50
    }
}

// Erro
{
    "success": false,
    "error": {
        "code": "VALIDATION_ERROR",
        "message": "Invalid field: sku_code",
        "details": [
            {
                "field": "sku_code",
                "message": "must be alphanumeric"
            }
        ]
    },
    "meta": {
        "timestamp": "2024-01-15T10:30:00Z",
        "request_id": "req-123456"
    }
}
```

### 3.3 Exemplos de Endpoints

#### Recebimento (Inbound)

```http
# Criar ASN (Aviso de Recebimento)
POST /api/v1/inbound/asn
Content-Type: application/json
Authorization: Bearer {token}

{
    "asn_number": "ASN20240115001",
    "po_number": "PO20240115001",
    "supplier_id": "uuid",
    "scheduled_arrival_date": "2024-01-16",
    "lines": [
        {
            "sku_code": "SKU001",
            "expected_quantity": 100,
            "lot_number": "LOT202401",
            "expiration_date": "2025-01-15"
        }
    ]
}

Response: 201 Created
{
    "success": true,
    "data": {
        "id": "uuid",
        "asn_number": "ASN20240115001",
        "status": "SCHEDULED",
        "created_at": "2024-01-15T10:30:00Z"
    }
}

# Confirmar Recebimento
POST /api/v1/inbound/{asn_id}/confirm
Content-Type: application/json

{
    "lines": [
        {
            "asn_line_id": "uuid",
            "quantity_received": 100,
            "quality_approved": true
        }
    ],
    "final_location_id": "uuid"
}
```

#### Picking

```http
# Listar Picking Orders Atribuídas
GET /api/v1/picking?status=ASSIGNED&warehouse_id={wh_id}&assigned_to_me=true
Authorization: Bearer {token}

Response: 200 OK
{
    "success": true,
    "data": [
        {
            "id": "uuid",
            "picking_id": "PICK001",
            "order_number": "ORD001",
            "status": "IN_PROGRESS",
            "total_lines": 5,
            "completed_lines": 2,
            "suggested_route": {
                "locations": ["A-1-1-A", "B-2-3-C", "C-1-2-B"],
                "distance_meters": 250,
                "estimated_time_minutes": 8
            }
        }
    ]
}

# Atualizar Linha de Picking
PUT /api/v1/picking/{picking_id}/lines/{line_id}
Content-Type: application/json

{
    "quantity_picked": 10,
    "location_id": "uuid",
    "timestamp": "2024-01-15T10:35:00Z"
}

Response: 200 OK
{
    "success": true,
    "data": {
        "id": "uuid",
        "status": "PICKED",
        "verified": false
    }
}

# Completar Picking
POST /api/v1/picking/{picking_id}/complete
Content-Type: application/json

{
    "photo_urls": ["s3://...", "s3://..."],
    "notes": "Some items moved to staging area"
}

Response: 200 OK
```

#### Expedição (Shipping)

```http
# Criar Remessa
POST /api/v1/shipments
Content-Type: application/json

{
    "warehouse_id": "uuid",
    "orders": ["ORD001", "ORD002", "ORD003"],
    "carrier_id": "uuid",
    "shipping_method": "TRUCK"
}

Response: 201 Created
{
    "success": true,
    "data": {
        "id": "uuid",
        "shipment_number": "SHIP001",
        "manifest_number": null,
        "status": "PREPARATION",
        "total_packages": 3
    }
}
```

---

## 4. Autenticação e Autorização

### 4.1 Fluxo OAuth 2.0 + JWT

```
1. Usuário faz login
2. Backend valida credenciais
3. Se OK, gera JWT com:
   - sub: user_id
   - tenant_id: tenant_id
   - roles: [role1, role2]
   - exp: 24 horas
   - iat: timestamp atual

4. Cliente armazena JWT
5. Cada requisição inclui: Authorization: Bearer {jwt}
6. Backend valida JWT antes de processar
```

### 4.2 RBAC (Role-Based Access Control)

```go
// middleware/rbac.go
func RequireRole(roles ...string) echo.MiddlewareFunc {
    return func(next echo.HandlerFunc) echo.HandlerFunc {
        return func(c echo.Context) error {
            token := c.Get("user").(*jwt.Token)
            claims := token.Claims.(jwt.MapClaims)
            
            userRoles := claims["roles"].([]interface{})
            
            hasRole := false
            for _, allowed := range roles {
                for _, userRole := range userRoles {
                    if userRole == allowed {
                        hasRole = true
                        break
                    }
                }
            }
            
            if !hasRole {
                return echo.NewHTTPError(http.StatusForbidden, "insufficient permissions")
            }
            
            return next(c)
        }
    }
}

// Uso
e.POST("/api/v1/orders", createOrder, RequireRole("WAREHOUSE_ADMIN", "INBOUND_OPERATOR"))
```

### 4.3 MFA (Multi-Factor Authentication)

- **Método:** TOTP (Time-based One-Time Password)
- **Lib:** github.com/pquerna/otp
- **Backup Codes:** 10 códigos de emergência

---

## 5. Tratamento de Erros e Validação

### 5.1 Custom Error Types

```go
// domain/errors.go
type ErrorCode string

const (
    ErrCodeValidation ErrorCode = "VALIDATION_ERROR"
    ErrCodeNotFound ErrorCode = "NOT_FOUND"
    ErrCodeUnauthorized ErrorCode = "UNAUTHORIZED"
    ErrCodeConflict ErrorCode = "CONFLICT"
    ErrCodeInternal ErrorCode = "INTERNAL_ERROR"
)

type DomainError struct {
    Code    ErrorCode
    Message string
    Details map[string]string
    Err     error
}

func (e *DomainError) Error() string {
    return fmt.Sprintf("[%s] %s", e.Code, e.Message)
}

// middleware/error_handler.go
func ErrorHandler(err error, c echo.Context) {
    var code int
    var response interface{}
    
    switch e := err.(type) {
    case *DomainError:
        code = mapErrorCodeToStatus(e.Code)
        response = map[string]interface{}{
            "success": false,
            "error": map[string]interface{}{
                "code": e.Code,
                "message": e.Message,
                "details": e.Details,
            },
        }
    default:
        code = http.StatusInternalServerError
        response = map[string]interface{}{
            "success": false,
            "error": map[string]interface{}{
                "code": "INTERNAL_ERROR",
                "message": "An unexpected error occurred",
            },
        }
    }
    
    c.JSON(code, response)
}
```

### 5.2 Validação com Struct Tags

```go
// handler/create_order.go
type CreateOrderRequest struct {
    OrderNumber    string        `json:"order_number" validate:"required,max=50"`
    CustomerID     string        `json:"customer_id" validate:"required,uuid"`
    DeliveryDate   time.Time     `json:"delivery_date" validate:"required,gtfield=OrderDate"`
    Lines          []OrderLine   `json:"lines" validate:"required,min=1,dive"`
}

type OrderLine struct {
    SKUCode       string `json:"sku_code" validate:"required,max=50"`
    Quantity      int    `json:"quantity" validate:"required,gt=0"`
    UnitPrice     float64 `json:"unit_price" validate:"required,gt=0"`
}

// Uso em handler
func CreateOrder(c echo.Context) error {
    req := &CreateOrderRequest{}
    if err := c.BindJSON(req); err != nil {
        return err
    }
    
    // Validar
    if err := validator.Validate(req); err != nil {
        return &DomainError{
            Code: ErrCodeValidation,
            Message: "Invalid request data",
            Details: err.Details,
        }
    }
    
    // ...
}
```

---

## 6. Testes Automatizados

### 6.1 Estratégia de Testes

```
                    Testes (Cobertura Esperada)
                    
Unit Tests (60%)
├── Domain Models
├── Value Objects
└── Business Rules

Integration Tests (25%)
├── Repository
├── Service Integration
└── Database

E2E Tests (15%)
├── API Flow
├── Critical Workflows
└── UI Interactions
```

### 6.2 Exemplo: Unit Test

```go
// domain/order_test.go
func TestOrderPickingValidation(t *testing.T) {
    tests := []struct {
        name    string
        status  OrderStatus
        wantErr bool
    }{
        {
            name:    "should allow picking on NEW status",
            status:  OrderStatusNew,
            wantErr: false,
        },
        {
            name:    "should prevent picking on CANCELLED status",
            status:  OrderStatusCancelled,
            wantErr: true,
        },
    }
    
    for _, tt := range tests {
        t.Run(tt.name, func(t *testing.T) {
            order := &Order{Status: tt.status}
            
            err := order.Pick(OrderLine{})
            
            if (err != nil) != tt.wantErr {
                t.Errorf("Pick() error = %v, wantErr %v", err, tt.wantErr)
            }
        })
    }
}
```

### 6.3 Exemplo: Integration Test

```go
// tests/integration/inbound_test.go
func TestReceiveASN(t *testing.T) {
    // Setup
    db := testutil.SetupTestDB(t)
    defer db.Close()
    
    repo := postgres.NewOrderRepository(db)
    svc := application.NewPickingService(repo)
    
    // Arrange
    order := testutil.CreateTestOrder(t, db)
    
    // Act
    picking, err := svc.CreatePickingOrder(context.Background(), CreatePickingOrderCommand{
        OrderID: order.ID,
    })
    
    // Assert
    require.NoError(t, err)
    require.NotNil(t, picking)
    assert.Equal(t, PickingStatusCreated, picking.Status)
}
```

---

## 7. Logging e Monitoring

### 7.1 Structured Logging

```go
// infrastructure/logger/logger.go
type Logger struct {
    handler slog.Handler
}

func (l *Logger) Info(ctx context.Context, msg string, args ...interface{}) {
    l.handler.Handle(ctx, slog.NewRecord(
        time.Now(),
        slog.LevelInfo,
        msg,
        0,
    ).AddAttrs(args...))
}

// Uso
logger.Info(ctx, "order received",
    slog.String("order_id", orderID),
    slog.String("customer", customerName),
    slog.Int("lines", len(lines)),
)

// Saída
{
    "timestamp": "2024-01-15T10:30:00Z",
    "level": "INFO",
    "message": "order received",
    "order_id": "uuid",
    "customer": "Acme Corp",
    "lines": 5,
    "request_id": "req-123456"
}
```

### 7.2 Métricas (Prometheus)

```go
// infrastructure/metrics/metrics.go
var (
    ordersTotal = promet.NewCounterVec(
        promet.CounterOpts{
            Name: "wms_orders_total",
            Help: "Total number of orders",
        },
        []string{"status", "warehouse"},
    )
    
    pickingDurationSeconds = promet.NewHistogramVec(
        promet.HistogramOpts{
            Name: "wms_picking_duration_seconds",
            Help: "Time spent on picking operations",
        },
        []string{"operator", "order_type"},
    )
)

// Uso em handler
func CreateOrder(c echo.Context) error {
    ordersTotal.WithLabelValues("new", warehouseID).Inc()
    
    // ...
}
```

### 7.3 Distributed Tracing (Jaeger)

```go
import "go.opentelemetry.io/otel"

tracer := otel.Tracer("wms")

func (s *pickingService) CreatePickingOrder(ctx context.Context, cmd CreatePickingOrderCommand) (*PickingOrder, error) {
    ctx, span := tracer.Start(ctx, "CreatePickingOrder")
    defer span.End()
    
    span.SetAttributes(
        attribute.String("order_id", cmd.OrderID.String()),
    )
    
    // ...
}
```

---

## 8. Performance e Otimização

### 8.1 Database Query Optimization

```go
// ❌ Ruim: N+1 Query
func (r *orderRepository) FindAll(ctx context.Context) ([]*Order, error) {
    rows, _ := r.db.QueryContext(ctx, "SELECT * FROM orders")
    
    var orders []*Order
    for rows.Next() {
        order := &Order{}
        rows.Scan(...)
        
        // ❌ Uma query por ordem!
        lines, _ := r.db.QueryContext(ctx, "SELECT * FROM order_lines WHERE order_id = ?", order.ID)
        // ...
    }
}

// ✅ Bom: Join única query
func (r *orderRepository) FindAll(ctx context.Context) ([]*Order, error) {
    const query = `
        SELECT o.id, o.number, ol.id, ol.sku_id, ol.quantity
        FROM orders o
        LEFT JOIN order_lines ol ON o.id = ol.order_id
        ORDER BY o.id
    `
    
    rows, _ := r.db.QueryContext(ctx, query)
    
    orders := make(map[uuid.UUID]*Order)
    for rows.Next() {
        // Mapear resultado
    }
    
    return lo.Values(orders), nil
}
```

### 8.2 Caching Strategy

```go
// infrastructure/cache/order_cache.go
func (c *OrderCache) GetByID(ctx context.Context, id OrderID) (*Order, error) {
    // 1. Tentar cache
    val, err := c.redis.Get(ctx, fmt.Sprintf("order:%s", id)).Result()
    if err == nil {
        return deserialize(val), nil
    }
    
    // 2. Buscar database
    order, err := c.db.FindByID(ctx, id)
    if err != nil {
        return nil, err
    }
    
    // 3. Armazenar cache (TTL: 1 hora)
    c.redis.Set(ctx, fmt.Sprintf("order:%s", id), serialize(order), 1*time.Hour)
    
    return order, nil
}

// Invalidar cache em update
func (c *OrderCache) Update(ctx context.Context, order *Order) error {
    if err := c.db.Save(ctx, order); err != nil {
        return err
    }
    
    c.redis.Del(ctx, fmt.Sprintf("order:%s", order.ID))
    return nil
}
```

---

## 9. Segurança

### 9.1 OWASP Top 10

| Vulnerabilidade | Mitigação |
|---|---|
| Injection | Prepared statements, input validation |
| Broken Auth | JWT + MFA, password hashing (bcrypt) |
| Sensitive Data Exposure | HTTPS, encryption, PII redaction |
| XML External Entities | Disable DTD processing |
| Broken Access Control | RBAC, RLS no banco |
| Security Misconfiguration | Secure defaults, secrets vault |
| XSS | Input encoding, CSP headers |
| Insecure Deserialization | Whitelist types, avoid pickle |
| Broken Components | Dependency scanning |
| Logging/Monitoring | Audit log, alertas |

### 9.2 Secrets Management

```bash
# .env (local development - nunca commit)
DATABASE_URL=postgresql://user:pass@localhost/wms
JWT_SECRET=super_secret_key

# Production (usando Vault)
vault kv put secret/wms/db url=postgresql://...
vault kv put secret/wms/jwt secret=...
```

```go
// infrastructure/config/config.go
type Config struct {
    DatabaseURL string
    JWTSecret   string
}

func LoadConfig() (*Config, error) {
    // 1. Tentar Vault (produção)
    client := api.NewClient(...)
    secret, err := client.Logical().Read("secret/wms/db")
    if err == nil {
        return fromVault(secret), nil
    }
    
    // 2. Fallback para env vars
    return fromEnv(), nil
}
```

---

**Documento Versão:** 1.0  
**Status:** Especificações Técnicas  
**Próximo Passo:** Implementação de protótipos
