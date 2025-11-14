# GUIA DE CONTRIBUIÇÃO - WMS ENTERPRISE

## 1. Bem-vindo ao WMS Enterprise!

Obrigado por considerar contribuir para o WMS Enterprise. Este documento fornece diretrizes e instruções para contribuir com o projeto.

---

## 2. Código de Conduta

Todos os contribuidores devem seguir nosso Código de Conduta:

- Seja respeitoso e inclusivo
- Aceite críticas construtivas
- Foque no melhor para a comunidade
- Denuncie comportamento inadequado

---

## 3. Como Começar

### 3.1 Pré-requisitos

- Git instalado (`git --version`)
- Docker e Docker Compose
- Node.js 18+ (para frontend)
- Go 1.21+ ou Rust 1.70+ (para backend)
- PostgreSQL 14+ (ou use docker-compose)

### 3.2 Setup Local

```bash
# Clone o repositório
git clone https://github.com/wms-enterprise/wms.git
cd wms

# Instale as dependências
make setup

# Ou manualmente:
cd backend && go mod download
cd ../frontend && npm install

# Inicie os containers Docker
docker-compose up -d

# Rode as migrations
make db-migrate

# Inicie o backend
make run-backend

# Em outro terminal, inicie o frontend
make run-frontend
```

### 3.3 Estrutura do Repositório

```
wms/
├── backend/
│   ├── cmd/                    # Executáveis
│   ├── internal/               # Código privado
│   │   ├── adapters/           # Adaptadores (HTTP, Database, etc)
│   │   ├── domain/             # Lógica de negócio
│   │   ├── services/           # Serviços de aplicação
│   │   └── repositories/       # Acesso a dados
│   ├── pkg/                    # Pacotes públicos/reusáveis
│   ├── migrations/             # Migrações de banco de dados
│   ├── tests/                  # Testes
│   └── go.mod                  # Dependências Go
│
├── frontend/
│   ├── src/
│   │   ├── components/         # Componentes React
│   │   ├── pages/              # Páginas (rotas)
│   │   ├── hooks/              # Custom hooks
│   │   ├── store/              # Redux/Zustand state
│   │   ├── services/           # API calls
│   │   ├── styles/             # Estilos globais
│   │   └── utils/              # Funções utilitárias
│   ├── public/                 # Arquivos estáticos
│   └── package.json
│
├── mobile/
│   └── App.tsx                 # React Native app
│
├── docs/                       # Documentação técnica
├── docker-compose.yml          # Orquestração local
├── Makefile                    # Comandos comuns
└── README.md
```

---

## 4. Fluxo de Desenvolvimento

### 4.1 Branches

**Nomeação de branches:**
```
feature/{JIRA-ID}-{descripao}    # nova funcionalidade
fix/{JIRA-ID}-{descricao}        # bugfix
docs/{descricao}                 # documentação
refactor/{descricao}             # refatoração
perf/{descricao}                 # otimização
```

**Exemplos:**
```
feature/WMS-123-picking-optimization
fix/WMS-456-inventory-sync-bug
docs/api-authentication
refactor/reduce-database-queries
perf/cache-layer-optimization
```

### 4.2 Commits

**Formato de commit:**
```
<tipo>(<escopo>): <assunto>

<corpo>

<rodapé>
```

**Exemplo:**
```
feat(picking): implement route optimization algorithm

- Add Traveling Salesman Problem solver
- Reduce picking time by 30%
- Add comprehensive unit tests

Closes #123
```

**Tipos válidos:**
- `feat`: Nova funcionalidade
- `fix`: Correção de bug
- `docs`: Mudanças em documentação
- `style`: Formatação, sem mudança de lógica
- `refactor`: Refatoração de código
- `perf`: Otimização de performance
- `test`: Adição/modificação de testes
- `chore`: Tarefas de build, dependências, etc.

**Escopos comuns:**
- `picking`, `receiving`, `shipping`, `inventory`
- `api`, `database`, `cache`
- `auth`, `security`, `compliance`

### 4.3 Pull Requests

**Processo:**

1. **Crie uma branch** a partir de `develop`
   ```bash
   git checkout develop
   git pull origin develop
   git checkout -b feature/WMS-123-minha-feature
   ```

2. **Faça suas mudanças** com commits significativos
   ```bash
   git add .
   git commit -m "feat(picking): optimize route calculation"
   ```

3. **Mantenha atualizado** com develop
   ```bash
   git fetch origin
   git rebase origin/develop
   ```

4. **Push para o repositório remoto**
   ```bash
   git push origin feature/WMS-123-minha-feature
   ```

5. **Abra um Pull Request** com template preenchido

**Template de PR:**
```markdown
## Descrição
Descrição clara do que foi mudado e por quê.

## Tipo de Mudança
- [ ] Bug fix (mudança não-breaking que corrige um issue)
- [ ] Nova funcionalidade (mudança não-breaking que adiciona funcionalidade)
- [ ] Breaking change (mudança que quebra compatibilidade)
- [ ] Documentação

## Como Testar?
Passos para reproduzir/testar a mudança:
1. Faça login como operador
2. Vá para picking
3. Etc.

## Checklist
- [ ] Meu código segue o style guide do projeto
- [ ] Realizei uma auto-review do meu código
- [ ] Comentei meu código, especialmente em seções complexas
- [ ] Atualizei a documentação relevante
- [ ] Minhas mudanças não geram novos warnings
- [ ] Adicionei testes que provam meu fix/feature funciona
- [ ] Novos e testes existentes passam localmente
- [ ] Quaisquer mudanças dependentes foram merged e publicadas

## Screenshots (se aplicável)
Antes e depois.
```

### 4.4 Code Review

**Revisor:**
- [ ] Código é legível e bem estruturado
- [ ] Lógica está correta
- [ ] Tests cobrem casos principais
- [ ] Performance é adequada
- [ ] Segurança foi considerada
- [ ] Documentação foi atualizada

**Autor:**
- Responda feedbacks de forma construtiva
- Não discuta para vencer, mas para aprender
- Faça mudanças se forem válidas
- Reclassifique após resolver feedbacks

---

## 5. Padrões de Codificação

### 5.1 Go (Backend)

```go
// ✅ Bom
package receiving

import (
    "context"
    "fmt"
    
    "wms/internal/domain/models"
    "wms/pkg/errors"
)

type ReceivingService struct {
    repo ReceivingRepository
    log  Logger
}

// NewReceivingService creates a new instance
func NewReceivingService(
    repo ReceivingRepository,
    log Logger,
) *ReceivingService {
    return &ReceivingService{
        repo: repo,
        log:  log,
    }
}

// ReceiveASN processes an inbound ASN
func (s *ReceivingService) ReceiveASN(
    ctx context.Context,
    asnID string,
) error {
    asn, err := s.repo.GetASN(ctx, asnID)
    if err != nil {
        s.log.Error("failed to get ASN", "asnID", asnID, "error", err)
        return fmt.Errorf("get ASN: %w", err)
    }

    if asn.Status != models.ASNStatusScheduled {
        return errors.NewInvalidStateError("ASN must be in SCHEDULED status")
    }

    asn.Status = models.ASNStatusReceived
    if err := s.repo.UpdateASN(ctx, asn); err != nil {
        return fmt.Errorf("update ASN: %w", err)
    }

    return nil
}

// ❌ Ruim
func receiveASN(asnID string) {
    asn := db.query("SELECT * FROM asn WHERE id = ?", asnID)
    if asn == nil {
        fmt.Println("Error getting ASN")
        return
    }
    db.execute("UPDATE asn SET status = 'RECEIVED' WHERE id = ?", asnID)
}
```

**Regras:**
- Use `context.Context` para cancelamento e timeouts
- Error handling explícito com `fmt.Errorf("operation: %w", err)`
- Logging estruturado
- Funções pequenas e focadas
- Interfaces para abstrair dependências

### 5.2 JavaScript/TypeScript (Frontend)

```typescript
// ✅ Bom
import { useState, useCallback } from 'react';
import { pickingService } from '@/services';
import { PickingOrder } from '@/types';

interface PickingListProps {
  warehouseId: string;
  onOrderPicked: (orderId: string) => void;
}

export const PickingList: React.FC<PickingListProps> = ({
  warehouseId,
  onOrderPicked,
}) => {
  const [orders, setOrders] = useState<PickingOrder[]>([]);
  const [loading, setLoading] = useState(false);
  const [error, setError] = useState<string | null>(null);

  const loadOrders = useCallback(async () => {
    setLoading(true);
    try {
      const data = await pickingService.getOrders(warehouseId);
      setOrders(data);
    } catch (err) {
      setError(err instanceof Error ? err.message : 'Unknown error');
    } finally {
      setLoading(false);
    }
  }, [warehouseId]);

  if (loading) return <LoadingSpinner />;
  if (error) return <ErrorAlert message={error} />;

  return (
    <div className="picking-list">
      {orders.map((order) => (
        <PickingOrderCard
          key={order.id}
          order={order}
          onPicked={() => onOrderPicked(order.id)}
        />
      ))}
    </div>
  );
};

// ❌ Ruim
function PickingList({ warehouseId }) {
  let orders = [];
  let loading = true;
  let error = null;

  fetch(`/api/orders?warehouse=${warehouseId}`)
    .then((r) => r.json())
    .then((d) => {
      orders = d;
      loading = false;
    })
    .catch((e) => {
      error = e;
    });

  return (
    <div>
      {loading && <p>Loading...</p>}
      {orders.map((o) => (
        <div key={o.id}>{o.name}</div>
      ))}
    </div>
  );
}
```

**Regras:**
- Use TypeScript sempre
- Components como arrow functions ou FC
- Custom hooks para lógica reutilizável
- Props bem tipadas
- Estado com `useState` ou context
- Callbacks com `useCallback` para performance

### 5.3 SQL

```sql
-- ✅ Bom: Índices, constraints, comentários
CREATE TABLE inventory_master (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    tenant_id UUID NOT NULL,
    warehouse_id UUID NOT NULL,
    sku_id UUID NOT NULL,
    
    -- Quantidades
    quantity_on_hand INT NOT NULL DEFAULT 0,
    quantity_reserved INT NOT NULL DEFAULT 0,
    
    -- Rastreamento
    last_movement_at TIMESTAMP,
    created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    
    FOREIGN KEY (tenant_id) REFERENCES tenants(id),
    FOREIGN KEY (warehouse_id) REFERENCES warehouses(id),
    FOREIGN KEY (sku_id) REFERENCES skus(id),
    
    CONSTRAINT quantity_reserved_valid CHECK (quantity_reserved >= 0),
    CONSTRAINT available_quantity_valid CHECK (quantity_on_hand >= quantity_reserved)
);

-- Índices para queries frequentes
CREATE INDEX idx_inventory_warehouse_sku 
ON inventory_master(warehouse_id, sku_id);

-- ❌ Ruim: Sem índices, sem constraints, sem comentários
CREATE TABLE inventory_master (
    id SERIAL PRIMARY KEY,
    tenant_id INT,
    warehouse_id INT,
    quantity INT,
    reserved INT
);
```

---

## 6. Testes

### 6.1 Unit Tests (Go)

```go
package receiving_test

import (
    "context"
    "testing"
    
    "github.com/stretchr/testify/assert"
    "github.com/stretchr/testify/require"
    
    "wms/internal/domain/models"
    "wms/internal/services/receiving"
)

type mockReceivingRepository struct {
    asn *models.ASN
}

func (m *mockReceivingRepository) GetASN(
    ctx context.Context,
    asnID string,
) (*models.ASN, error) {
    return m.asn, nil
}

func TestReceiveASN_Success(t *testing.T) {
    // Arrange
    repo := &mockReceivingRepository{
        asn: &models.ASN{
            ID:     "asn-123",
            Status: models.ASNStatusScheduled,
        },
    }
    service := receiving.NewService(repo)

    // Act
    err := service.ReceiveASN(context.Background(), "asn-123")

    // Assert
    assert.NoError(t, err)
    assert.Equal(t, models.ASNStatusReceived, repo.asn.Status)
}

func TestReceiveASN_InvalidStatus(t *testing.T) {
    // Arrange
    repo := &mockReceivingRepository{
        asn: &models.ASN{
            ID:     "asn-123",
            Status: models.ASNStatusDraft,
        },
    }
    service := receiving.NewService(repo)

    // Act
    err := service.ReceiveASN(context.Background(), "asn-123")

    // Assert
    assert.Error(t, err)
}
```

**Coverage:**
- [ ] Casos de sucesso
- [ ] Casos de erro
- [ ] Edge cases
- [ ] Validações

**Target:** > 80% coverage

### 6.2 Integration Tests

```bash
# Usar testcontainers para banco de dados
docker-compose -f docker-compose.test.yml up -d
go test -v -tags=integration ./...
docker-compose -f docker-compose.test.yml down
```

### 6.3 Frontend Tests

```typescript
import { render, screen, userEvent } from '@testing-library/react';
import { PickingList } from './PickingList';

describe('PickingList', () => {
  it('renders orders when loaded', async () => {
    // Arrange
    const mockOrders = [{ id: '1', name: 'Order 1' }];
    jest.mock('@/services', () => ({
      pickingService: {
        getOrders: jest.fn().mockResolvedValue(mockOrders),
      },
    }));

    // Act
    render(<PickingList warehouseId="wh-1" onOrderPicked={jest.fn()} />);

    // Assert
    expect(await screen.findByText('Order 1')).toBeInTheDocument();
  });
});
```

---

## 7. Documentação

### 7.1 Código

```go
// Package receiving handles inbound merchandise receiving operations.
package receiving

// ReceivingService provides business logic for receiving operations.
//
// It handles ASN processing, merchandise receipt validation,
// and inventory allocation.
type ReceivingService struct {
    repo ReceivingRepository
}

// ReceiveASN processes an inbound ASN and transitions it to RECEIVED status.
//
// It validates that the ASN is in SCHEDULED status before proceeding.
// Returns an error if validation fails or database operation fails.
func (s *ReceivingService) ReceiveASN(
    ctx context.Context,
    asnID string,
) error {
    // Implementation...
}
```

### 7.2 Mudanças na Arquitetura

Se sua mudança afeta a arquitetura, documente como ADR (Architecture Decision Record):

```
docs/adr/0001-use-kafka-for-event-streaming.md
```

Conteúdo:
```markdown
# ADR 001: Use Kafka for Event Streaming

## Context
We need an asynchronous event streaming system for decoupling microservices.

## Decision
We will use Apache Kafka as the message broker.

## Consequences
- Pro: High throughput, durability, ordering guarantees
- Con: Operational complexity, additional infrastructure
```

---

## 8. Performance

### 8.1 Ao implementar queries

```sql
-- Sempre use EXPLAIN ANALYZE antes de commit
EXPLAIN ANALYZE
SELECT o.*, ol.* 
FROM orders o
LEFT JOIN order_lines ol ON o.id = ol.order_id
WHERE o.warehouse_id = $1
ORDER BY o.created_at DESC
LIMIT 100;

-- Espere um plano eficiente:
-- Seq Scan on orders (bom se filter reduz muito)
-- ou Index Scan (melhor)
-- Evite: Nested Loop sem bom índice
```

### 8.2 Ao fazer requisições

```go
// ✅ Use context com timeout
ctx, cancel := context.WithTimeout(context.Background(), 5*time.Second)
defer cancel()

result, err := service.SomeOperation(ctx)

// ❌ Evite operações bloqueantes sem timeout
result, err := service.SomeOperation(context.Background())
```

---

## 9. Segurança

### 9.1 Input Validation

```go
// ✅ Sempre valide
asnID := req.PathParams["asn_id"]
if err := validate.UUID(asnID); err != nil {
    return errors.NewBadRequestError("invalid ASN ID format")
}

// ❌ Nunca confie em input do usuário
query := "SELECT * FROM orders WHERE id = " + orderID  // SQL injection!
```

### 9.2 Autenticação

```go
// Use middleware de autenticação em todas rotas protegidas
router.POST(
    "/api/v1/receiving/asn",
    middleware.Auth,  // Verifica JWT
    middleware.RequireRole("RECEIVING_OPERATOR"),
    handler.CreateASN,
)
```

### 9.3 Logging Sensível

```go
// ✅ Bom: Não loga dados sensíveis
log.Info("User logged in", "user_id", userID)

// ❌ Ruim: Loga informações sensíveis
log.Info("User logged in", "user", user)  // pode conter password!
```

---

## 10. Deployment

### 10.1 Antes de fazer merge para main

- [ ] Todos os testes passam
- [ ] Code review aprovado
- [ ] Documentação atualizada
- [ ] Sem hardcoded secrets
- [ ] Performance aceitável
- [ ] Sem breaking changes (ou com migration plan)

### 10.2 Após merge para main

- CI/CD automaticamente faz deploy para staging
- Monitore os logs e métricas
- Se algo der errado, considere reverter

---

## 11. Troubleshooting

### 11.1 Banco de dados

```bash
# Reset local database
docker-compose down -v
docker-compose up -d
make db-migrate
make db-seed

# Ver logs
docker-compose logs postgres
```

### 11.2 Backend

```bash
# Rodar com debug
dlv debug ./cmd/api
(dlv) break main.main
(dlv) continue
```

### 11.3 Frontend

```bash
# Usar React DevTools browser extension
# Verificar Network tab no DevTools
# Usar console para logs
console.log('Debug:', data);
```

---

## 12. Perguntas Frequentes

**P: Quanto tempo demora para meu PR ser revisado?**
R: Geralmente 1-2 dias úteis.

**P: Meu código está 100% diferente do original, como faço rebase?**
R: Considere abrir uma nova PR. Mantenha PRs menores para mais fácil review.

**P: Meu test está falhando aleatoriamente. O que faço?**
R: Provavelmente é race condition. Use `t.Parallel()` com cuidado e mutex quando necessário.

**P: Preciso urgentemente fazer deploy de uma mudança?**
R: Entre em contato com a equipe. Há processo de hotfix com review rápido.

---

## 13. Recursos

- [Go Style Guide](https://google.github.io/styleguide/go/)
- [React Best Practices](https://react.dev/learn)
- [PostgreSQL Documentation](https://www.postgresql.org/docs/)
- [Kubernetes Documentation](https://kubernetes.io/docs/)

---

## 14. Contato

- **Slack:** #wms-enterprise-dev
- **GitHub Issues:** Para bugs e features
- **Tech Lead:** [designar]
- **PR Questions:** Comente no PR

---

Obrigado por contribuir! 🚀

**Versão:** 1.0  
**Última Atualização:** Janeiro 2025
