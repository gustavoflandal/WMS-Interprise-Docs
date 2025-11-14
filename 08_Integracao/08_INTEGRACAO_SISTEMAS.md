# INTEGRAÇÃO COM SISTEMAS EXTERNOS - WMS ENTERPRISE

## 1. Visão Geral de Integração

O WMS Enterprise foi projetado para ser agnóstico a sistemas externos através de um **Integration Adapter Pattern** que permite conexão com múltiplos ERP, PCP e YMS sem modificações no core do WMS.

```
┌─────────────────────────────────────────────────────────────┐
│                      WMS Enterprise                         │
│              (Event Bus + Message Streaming)                │
└──────────┬──────────────────────────────────────────────────┘
           │
           ├── [ERP Adapter]          ←→ SAP, Oracle, Totvs, etc
           ├── [PCP Adapter]          ←→ Softwares de produção
           ├── [YMS Adapter]          ←→ Gestão de pátio
           ├── [TMS Adapter]          ←→ Gestão de transporte
           └── [EDI Adapter]          ←→ Fornecedores/Clientes
```

---

## 2. Padrão de Integração

### 2.1 Arquitetura Adapter

```go
// domain/ports/erp_service.go
type ERPService interface {
    // Outbound (WMS → ERP)
    SendReceiptConfirmation(ctx context.Context, receipt *ReceiptConfirmation) error
    SendPickingConfirmation(ctx context.Context, picking *PickingConfirmation) error
    SendShippingConfirmation(ctx context.Context, shipping *ShippingConfirmation) error
    
    // Inbound (ERP → WMS)
    GetSalesOrder(ctx context.Context, orderID string) (*SalesOrder, error)
    GetInventoryLevels(ctx context.Context, warehouseID string) (*InventoryLevels, error)
}

// infrastructure/integration/erp_adapter.go
type ERPAdapter struct {
    client HTTPClient
    config ERPConfig
    logger Logger
    metrics MetricsCollector
}

func (a *ERPAdapter) SendReceiptConfirmation(
    ctx context.Context,
    receipt *ReceiptConfirmation,
) error {
    // 1. Converter para formato ERP
    payload := convertToERPFormat(receipt)
    
    // 2. Enviar
    resp, err := a.client.Post(
        a.config.ReceiptEndpoint,
        payload,
        withTimeout(30*time.Second),
        withRetry(3, exponentialBackoff),
    )
    
    if err != nil {
        // 3. Logar erro
        a.logger.Error("failed to send receipt", err,
            slog.String("receipt_id", receipt.ID.String()),
        )
        
        // 4. Registrar métrica
        a.metrics.IncrementCounter("erp_receipt_failed")
        
        return &IntegrationError{
            Code: "ERP_SEND_FAILED",
            Message: "Failed to send receipt to ERP",
            OriginalError: err,
            Retryable: isRetryable(err),
        }
    }
    
    // 5. Validar resposta
    if !isSuccessResponse(resp) {
        return &IntegrationError{
            Code: "ERP_REJECTED",
            Message: "ERP rejected receipt",
            Details: resp.ErrorMessage,
        }
    }
    
    // 6. Registrar sucesso
    a.metrics.IncrementCounter("erp_receipt_success")
    
    return nil
}
```

### 2.2 Resilience Pattern

```go
// infrastructure/integration/circuit_breaker.go
type CircuitBreaker struct {
    failureThreshold int
    successThreshold int
    timeout time.Duration
    state CircuitState  // CLOSED, OPEN, HALF_OPEN
}

func (cb *CircuitBreaker) Execute(fn func() error) error {
    switch cb.state {
    case CLOSED:
        return fn()
    case OPEN:
        if time.Since(cb.lastFailure) > cb.timeout {
            cb.state = HALF_OPEN
            cb.successCount = 0
            return fn()
        }
        return &CircuitBreakerOpenError{"Circuit breaker is open"}
    case HALF_OPEN:
        if err := fn(); err != nil {
            cb.state = OPEN
            cb.lastFailure = time.Now()
            return err
        }
        cb.successCount++
        if cb.successCount >= cb.successThreshold {
            cb.state = CLOSED
            cb.failureCount = 0
        }
        return nil
    }
}
```

---

## 3. Integração com ERP

### 3.1 Fluxo de Dados ERP → WMS

#### 3.1.1 Pedido de Venda → Ordem de Picking

```
ERP (SAP/Oracle/Totvs)
    │
    ├─ Cria Pedido de Venda
    │  └─ Evento: SalesOrderCreated
    │
    ├─ REST API: POST /api/v1/erp/orders
    │     or
    │  EDI: X12 850 ou 997
    │     or
    │  Message Queue: Kafka/RabbitMQ
    │
    ▼
WMS Integration Layer
    │
    ├─ Validar: SKU existe? Estoque suficiente?
    ├─ Transformar: Formato SAP → Formato WMS
    ├─ Criar: Order + Order Lines
    ├─ Alocar: Reservar inventário
    └─ Publicar evento: order.created
    
    ▼
WMS Core
    │
    ├─ Picking Module: Criar picking order
    ├─ Picking Optimization: Calcular rota
    └─ Notificar operador
```

**Formato ERP (JSON):**
```json
{
  "erp_order_id": "ORD-2024-001",
  "customer": {
    "id": "CUST-001",
    "name": "Acme Corp",
    "address": "Rua 1, 123"
  },
  "lines": [
    {
      "line_number": 1,
      "sku": "SKU-001",
      "quantity": 100,
      "unit": "UN",
      "price": 10.50,
      "promised_date": "2024-01-20"
    }
  ],
  "delivery_date": "2024-01-20",
  "shipping_method": "TRUCK"
}
```

**Transformação para WMS:**
```go
func transformSalesOrder(erp *ERPSalesOrder) *Order {
    lines := make([]OrderLine, len(erp.Lines))
    
    for i, line := range erp.Lines {
        lines[i] = OrderLine{
            SKU: NewSKUFromCode(line.SKU),
            Quantity: line.Quantity,
            UnitPrice: line.Price,
        }
    }
    
    return &Order{
        Number: NewOrderNumber(erp.OrderID),
        Customer: &Customer{
            ID: NewCustomerID(erp.Customer.ID),
            Name: erp.Customer.Name,
        },
        Lines: lines,
        DeliveryDate: erp.DeliveryDate,
    }
}
```

### 3.2 Fluxo de Dados WMS → ERP

#### 3.2.1 Confirmação de Recebimento

```
WMS (Recebimento confirmado)
    │
    ├─ Evento: inbound.confirmed
    │  Dados: ASN ID, quantidades, localização
    │
    ├─ Converter para formato ERP
    │
    └─ Enviar via REST/EDI/Message Queue
    
    ▼
ERP
    │
    ├─ Receber confirmação
    ├─ Criar Recibo (PO Receipt)
    ├─ Atualizar Estoque
    └─ Notificar Financeiro (se invoice matching)
```

**Mensagem de Confirmação:**
```json
{
  "wms_reference": "ASN-2024-001",
  "erp_reference": "PO-2024-001",
  "receipt_date": "2024-01-15T10:30:00Z",
  "lines": [
    {
      "line_number": 1,
      "sku": "SKU-001",
      "quantity_received": 100,
      "quantity_accepted": 100,
      "quantity_rejected": 0,
      "location": "A-1-1-A",
      "lot_number": "LOT-2024-001"
    }
  ],
  "notes": "Recebimento sem problemas"
}
```

#### 3.2.2 Confirmação de Expedição

```
WMS (Remessa descarregada)
    │
    ├─ Evento: shipping.dispatched
    │
    ├─ Coletar dados:
    │  - Pedidos inclusos
    │  - Remessa ID
    │  - Transportadora
    │  - Tracking
    │
    └─ Enviar para ERP
    
    ▼
ERP
    │
    ├─ Receber confirmação
    ├─ Faturar pedido (se não foi antes)
    ├─ Gerar NF-e
    └─ Notificar cliente
```

---

## 4. Integração com PCP (Planejamento e Controle da Produção)

### 4.1 Fluxo de Dados

```
PCP: Cria Ordem de Produção
    │
    ├─ Notifica WMS: "Será recebido 500 unidades SKU-001 em 2024-01-20"
    │
    └─ WMS reserva espaço
    
    ▼
Produção executa
    │
    ├─ PCP: Produção concluída
    │
    └─ WMS: Receber produtos
    
    ▼
WMS: Aloca e armazena
    │
    ├─ Confirma recebimento para PCP
    │
    └─ Notifica disponibilidade
```

**Dados Sincronizados PCP → WMS:**

```json
{
  "production_order_id": "PO-2024-001",
  "sku": "SKU-001",
  "quantity_planned": 500,
  "start_date": "2024-01-15",
  "estimated_end_date": "2024-01-20",
  "receiving_warehouse": "WH-001",
  "notes": "Lote especial para cliente X"
}
```

---

## 5. Integração com YMS (Yard Management System)

### 5.1 Agendamento de Dock

```
WMS: Tem 5 páletes prontos para descarregar
    │
    ├─ Requisita dock do YMS
    ├─ Passa: Hora, tipo de carga, peso
    │
    ▼
YMS
    │
    ├─ Verifica disponibilidade
    ├─ Aloca dock e horário
    └─ Retorna: Dock 3, Horário 14:00
    
    ▼
WMS
    │
    ├─ Prepara carga
    └─ Alerta operador
```

**Requisição de Dock:**
```json
{
  "wms_shipment_id": "SHIP-001",
  "dock_type": "RECEIVING",  // RECEIVING ou SHIPPING
  "required_date": "2024-01-15",
  "required_time_start": "14:00",
  "required_time_end": "15:00",
  "cargo_type": "PALLET",
  "estimated_pallets": 5,
  "estimated_weight_kg": 2500,
  "priority": "NORMAL"
}
```

---

## 6. Integração com TMS (Transport Management System)

### 6.1 Consolidação e Roteirização

```
WMS: Remessa pronta para expedição
    │
    ├─ Envia dados para TMS:
    │  - Pacotes
    │  - Pesos, volumes
    │  - Destino
    │  - Data promissória
    │
    ▼
TMS
    │
    ├─ Consolida com outras remessas
    ├─ Otimiza rotas
    ├─ Aloca veículo
    └─ Retorna: Nº Remessa, Transportadora, ETA
    
    ▼
WMS
    │
    ├─ Recebe rastreamento
    ├─ Notifica cliente
    └─ Mantém dashboard de tracking
```

**Dados para TMS:**
```json
{
  "shipment_id": "SHIP-001",
  "packages": [
    {
      "tracking_number": "BR123456789",
      "weight_kg": 5.2,
      "volume_m3": 0.02,
      "dimensions": {"length": 30, "width": 20, "height": 10}
    }
  ],
  "destination": {
    "customer": "Cliente XYZ",
    "address": "Rua 1, 123",
    "city": "São Paulo",
    "state": "SP",
    "postal_code": "01234-567"
  },
  "promised_date": "2024-01-20",
  "special_requirements": ["FRAGILE", "SIGNATURE_REQUIRED"]
}
```

---

## 7. Integração EDI (Electronic Data Interchange)

### 7.1 Padrões Suportados

- **X12 (USA/Canadá)**
  - 850: Purchase Order
  - 997: Functional Acknowledgement
  - 945: Warehouse Shipment Notice

- **EDIFACT (Internacional)**
  - ORDERS: Purchase Order
  - RECADV: Goods Receipt Notification

- **JSON/REST (Moderno)**
  - Mais fácil de implementar
  - Melhor para integrações novas

### 7.2 Exemplo: Integração EDI X12

```
EDI Partner enviar: X12 850 (Purchase Order)
    │
    ├─ WMS recebe e processa
    ├─ Converte X12 → JSON
    ├─ Valida contra esquema
    ├─ Cria Order no WMS
    │
    └─ Retorna: X12 997 (Functional Acknowledgement)
    
    ▼
EDI Partner recebe confirmação
    │
    └─ Sabe que pedido foi recebido
```

---

## 8. Tratamento de Erros e Reconciliação

### 8.1 Retry Policy

```go
type RetryPolicy struct {
    MaxAttempts int
    InitialDelay time.Duration
    MaxDelay time.Duration
    BackoffMultiplier float64
}

// Exemplo: Exponential Backoff
// Tentativa 1: agora
// Tentativa 2: + 1 segundo
// Tentativa 3: + 4 segundos
// Tentativa 4: + 16 segundos
// Tentativa 5: + 64 segundos (máx 300s)

func (rp *RetryPolicy) CalculateDelay(attempt int) time.Duration {
    delay := time.Duration(math.Pow(rp.BackoffMultiplier, float64(attempt-1))) * rp.InitialDelay
    if delay > rp.MaxDelay {
        return rp.MaxDelay
    }
    return delay
}
```

### 8.2 Dead Letter Queue

```
Envio para ERP falha após 5 tentativas
    │
    ├─ Mover para Dead Letter Queue (DLQ)
    ├─ Logar com contexto completo
    ├─ Alertar administrador
    │
    ▼
Admin investigar
    │
    ├─ Analisar erro
    ├─ Corrigir (ex: endpoint do ERP está down)
    ├─ Reprocessar mensagem manualmente
    │
    └─ Monitorar retry
```

### 8.3 Reconciliação

```
Diariamente (02:00 UTC):

1. Buscar ordens no ERP criadas nas últimas 24h
2. Comparar com ordens no WMS
3. Se ausente no WMS: Recriar order
4. Se divergência em quantidade: Alertar
5. Confirmar sucesso em log

Resultado: Garantir consistência de dados
```

---

## 9. Segurança de Integração

### 9.1 Autenticação

```go
// OAuth 2.0
auth := &oauth2.Config{
    ClientID: os.Getenv("ERP_CLIENT_ID"),
    ClientSecret: os.Getenv("ERP_CLIENT_SECRET"),
    Endpoint: oauth2.Endpoint{
        AuthURL: "https://erp.example.com/oauth/authorize",
        TokenURL: "https://erp.example.com/oauth/token",
    },
}

// Basic Auth (deprecated, mas ainda usado)
req.SetBasicAuth(username, password)

// API Key (para partners)
req.Header.Add("X-API-Key", apiKey)
```

### 9.2 Encriptação

```go
// TLS 1.3 obrigatório
client := &http.Client{
    Transport: &http.Transport{
        TLSClientConfig: &tls.Config{
            MinVersion: tls.VersionTLS13,
        },
    },
}

// Payload encriptado (se sensível)
encryptedPayload := encryptAES256(payload, encryptionKey)
```

### 9.3 Validação de Assinatura (Webhook)

```go
func validateWebhookSignature(
    payload []byte,
    signature string,
    secret string,
) (bool, error) {
    h := hmac.New(sha256.New, []byte(secret))
    h.Write(payload)
    expectedSignature := hex.EncodeToString(h.Sum(nil))
    
    return hmac.Equal([]byte(signature), []byte(expectedSignature)), nil
}
```

---

## 10. Configuração de Integração por Depositante

```yaml
# config/tenant-1/integrations.yaml
erp:
  enabled: true
  type: "SAP"
  endpoints:
    order: "https://erp.example.com/api/v2/orders"
    receipt: "https://erp.example.com/api/v2/receipts"
    shipment: "https://erp.example.com/api/v2/shipments"
  auth:
    type: "oauth2"
    client_id: "${ERP_CLIENT_ID}"
  timeout: 30
  retry:
    max_attempts: 3
    initial_delay: 1000  # ms

pcp:
  enabled: true
  type: "MES"
  endpoint: "wss://pcp.example.com/api/ws"
  
yms:
  enabled: true
  type: "YMS_INTERNAL"
  
tms:
  enabled: true
  type: "SHIPAROUND"
  api_key: "${TMS_API_KEY}"
  webhook_url: "https://wms.example.com/webhooks/tms"
```

---

## 11. Monitoramento de Integrações

**Dashboard de Integrações:**

```
┌─────────────────────────────────────────────────┐
│ Integration Status Dashboard                     │
├─────────────────────────────────────────────────┤
│                                                 │
│ ERP (SAP)                         ✓ Connected  │
│ └─ Last sync: 2024-01-15 10:30   │ 1,234 events
│ └─ Pending: 0                      │ ↻ Retry: 0
│                                    │
│ PCP (MES)                         ✓ Connected  │
│ └─ Last sync: 2024-01-15 10:35   │ 456 events
│                                    │
│ YMS                               ✓ Connected  │
│ └─ Last sync: 2024-01-15 10:40   │ No pending
│                                    │
│ TMS (ShipAround)                  ⚠ Delayed   │
│ └─ Last sync: 2024-01-15 09:50   │ Delay: 40 min
│ └─ Error: "Timeout on GET /status"│ Retry: 2/3
│                                    │
└─────────────────────────────────────────────────┘
```

**Alertas Configuráveis:**
- Não sincronizado por > 1 hora
- Taxa de erro > 5%
- Dead letter queue > 100 mensagens
- Latência > 60 segundos

---

**Documento Versão:** 1.0  
**Status:** Padrões de Integração Definidos  
**Próximo Passo:** Documentar adaptadores específicos por sistema
