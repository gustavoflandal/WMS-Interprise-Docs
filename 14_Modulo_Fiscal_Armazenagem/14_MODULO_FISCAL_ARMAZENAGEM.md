# MÓDULO FISCAL DE ARMAZENAGEM - WMS ENTERPRISE

## Versão: 1.0
**Data:** Janeiro 2025  
**Status:** Especificação Completa  
**Autor:** Equipe de Engenharia  
**Criticidade:** ALTA (Compliance Regulatório)

---

## 📋 ÍNDICE

1. [Visão Geral](#1-visão-geral)
2. [Requisitos Funcionais](#2-requisitos-funcionais)
3. [Design do Banco de Dados](#3-design-do-banco-de-dados)
4. [Fluxos de Operação](#4-fluxos-de-operação)
5. [Integração com ERP](#5-integração-com-erp)
6. [Algoritmos de Alocação](#6-algoritmos-de-alocação-fiscal)
7. [Rastreabilidade Completa](#7-rastreabilidade-completa)
8. [Relatórios Fiscais](#8-relatórios-fiscais)
9. [Conformidade Regulatória](#9-conformidade-regulatória)
10. [Exemplos de Implementação](#10-exemplos-de-implementação)

---

## 1. Visão Geral

### 1.1 Conceito

O Módulo Fiscal de Armazenagem garante que **TODAS as operações de armazenagem (recebimento, armazenagem, picking, devolução) sejam rastreáveis para sua origem fiscal**, ou seja, linkadas ao documento de entrada (Nota Fiscal de Entrada) e sua linha específica (item da NF).

### 1.2 Objetivo Principal

```
Garantir rastreabilidade 100% fiscal de cada unidade de produto
no armazém, desde sua entrada até sua saída, para atender:

✅ Conformidade regulatória (SPED, NF-e, ICMS, etc)
✅ Auditorias internas e externas
✅ Controle de estoque por origem
✅ Rastreamento de lotes/séries por documento
✅ Devolução com referência fiscal
✅ Apuração correta de impostos
```

### 1.3 Premissas Fundamentais

```
1. CADA ENTRADA = UMA NOTA FISCAL (NF-e)
   └─ Cada NF tem um ID único (chave de acesso ou ID interno)
   
2. CADA NF = MÚLTIPLOS ITENS
   └─ Cada item tem um número sequencial único
   └─ Cada item = um SKU com quantidade e valor
   
3. CADA ARMAZENAGEM DEVE REFERENCIAR
   ├─ fiscal_document_id (NF de entrada)
   ├─ fiscal_document_item_id (item da NF)
   └─ Rastreamento por lote/série se aplicável

4. OPERAÇÕES SEM RASTREAMENTO FISCAL = ERRO
   └─ Sistema recusa qualquer movimento sem origem fiscal
```

### 1.4 Arquitetura Conceitual

```
┌─────────────────────────────────────────────────────────┐
│                    ERP (Sistema Fiscal)                 │
│  - Gera NF-e de entrada                                │
│  - Define itens e valores                              │
│  - Integra com SPED/e-Lalur                            │
│  - Responsável pela legalidade fiscal                  │
└────────────────┬────────────────────────────────────────┘
                 │ (Envia ASN + Info Fiscal)
                 ▼
┌─────────────────────────────────────────────────────────┐
│              WMS ENTERPRISE (Armazenagem)               │
│  - Recebe ASN com dados fiscais                        │
│  - Armazena referência fiscal em cada posição          │
│  - Rastreia movimento de cada item fiscal              │
│  - Fornece dados para auditoria fiscal                 │
│  - Relatórios de conformidade                          │
└────────────────┬────────────────────────────────────────┘
                 │ (Retorna confirmações de movimento)
                 ▼
┌─────────────────────────────────────────────────────────┐
│           AUDITORIA / COMPLIANCE / SPED                 │
│  - Conciliação fiscal                                  │
│  - Rastreabilidade completa                            │
│  - Conformidade regulatória                            │
└─────────────────────────────────────────────────────────┘
```

---

## 2. Requisitos Funcionais

### 2.1 RF-010: Rastreamento Fiscal de Entrada (Novo)

**Objetivo:** Vincular cada recebimento de mercadoria a seu documento fiscal de origem

**Atores:**
- Operador de Recebimento
- Sistema ERP
- Supervisor de Qualidade

**Fluxo Principal:**

```gherkin
Feature: Rastreamento Fiscal de Entrada

  Scenario: Receber mercadoria com rastreamento fiscal
    Given ERP envia ASN com fiscal_document_id="NF123456"
    And ASN contém fiscal_document_item_id="1" para SKU-001
    When operador confirma recebimento de 100 unidades de SKU-001
    Then sistema cria inventory_master com:
      ├─ sku_id = SKU-001
      ├─ fiscal_document_id = NF123456
      ├─ fiscal_document_item_id = 1
      ├─ quantity = 100
      └─ fiscal_origin = "ENTRADA"
    And rastreabilidade completa é estabelecida
    And cada unidade pode ser rastreada até NF123456

  Scenario: Recusar entrada sem informação fiscal
    Given ASN é recebido SEM fiscal_document_id
    When operador tenta confirmar recebimento
    Then sistema retorna erro: "FISCAL_DOCUMENT_REQUIRED"
    And recebimento é bloqueado até informação fiscal ser fornecida
```

**Dados Necessários do ERP:**

```json
{
  "asn": {
    "asn_id": "ASN-2025-001",
    "fiscal_document": {
      "document_id": "NF-E-ID-2025-0000001",
      "document_type": "NF-e",
      "access_key": "35250101234567000123550010000000011234567890",
      "issue_date": "2025-01-10",
      "supplier_id": "CNPJ-12345678901234",
      "total_value": 50000.00
    },
    "lines": [
      {
        "item_id": 1,
        "sku_id": "SKU-001",
        "description": "Produto A",
        "quantity": 100,
        "unit_price": 500.00,
        "line_value": 50000.00,
        "icms_rate": 7.00,
        "ncm": "1234567890",
        "batch_number": "LOTE-2024-12345"
      }
    ]
  }
}
```

### 2.2 RF-011: Alocação Considerando Origem Fiscal

**Objetivo:** Alocar produtos mantendo separação fiscal quando necessário

**Contexto:**
Diferentes notas fiscais podem ter diferentes ICMS, impostos ou restrições. Algumas operações requerem manutenção de separação fiscal.

**Fluxo:**

```gherkin
Feature: Alocação com Rastreamento Fiscal

  Scenario: Alocar mantendo origem fiscal separada
    Given mesmo SKU entra em 2 NF diferentes:
      ├─ NF-001 com 50 unidades (ICMS 7%)
      └─ NF-002 com 50 unidades (ICMS 12%)
    When sistema aloca no armazém
    Then cada lote mantém separação fiscal:
      ├─ Localização A: 50 un de NF-001
      └─ Localização B: 50 un de NF-002
    And picking respeita separação fiscal se configurado

  Scenario: Consolidação fiscal autorizada
    Given fiscal_consolidation_allowed = true para SKU
    When mesmo SKU de NF-001 e NF-002 é alocado
    Then pode consolidar em mesma localização:
      ├─ Localização C: 100 unidades
      ├─ Referência fiscal = [NF-001 (50), NF-002 (50)]
      └─ Rastreabilidade mantida por lote
```

### 2.3 RF-012: Picking com Validação Fiscal

**Objetivo:** Garantir que picking respeite restrições fiscais

**Fluxo:**

```gherkin
Feature: Picking com Conformidade Fiscal

  Scenario: Picking respeitando origem fiscal
    Given pedido solicita 30 unidades de SKU-001
    And localização A tem: 20 un de NF-001
    And localização B tem: 30 un de NF-002
    When sistema calcula picking
    Then sugere:
      ├─ 20 un de localização A (NF-001)
      └─ 10 un de localização B (NF-002)
    And picking order registra origem fiscal de cada lote

  Scenario: Rejeitar picking se violaria conformidade
    Given configuração "MANTER_SEPARACAO_FISCAL" = true
    And pedido requer 50 unidades consecutivas de mesmo lote fiscal
    And apenas 30 unidades disponíveis de NF-001
    When picking é solicitado
    Then sistema oferece opções:
      ├─ Opção 1: Separar em 2 pedidos (30 de NF-001 + 20 de NF-002)
      ├─ Opção 2: Aguardar reabastecimento de NF-001
      └─ Opção 3: Aceitar mistura de fiscal (com aprovação)
```

### 2.4 RF-013: Rastreamento de Devolução Fiscal

**Objetivo:** Rastrear devoluções mantendo origem fiscal

**Fluxo:**

```gherkin
Feature: Devolução com Rastreamento Fiscal

  Scenario: Devolver produto mantendo origem fiscal
    Given produto original saiu de NF-001
    When cliente devolve produto
    Then sistema cria registro de devolução:
      ├─ original_fiscal_document = NF-001
      ├─ original_fiscal_item = 1
      ├─ return_reason = "Dano"
      └─ Nota fiscal de devolução (NF-e de retorno) é gerada no ERP
    And rastreabilidade completa é mantida

  Scenario: Reconciliação fiscal de devoluções
    Given múltiplas devoluções de produto X
    When relatório fiscal é gerado
    Then inclui:
      ├─ Quantidade original por NF de entrada
      ├─ Quantidade devolvida por NF de entrada
      ├─ Motivo de devolução
      └─ Referência de NF de saída (NF de devolução)
```

---

## 3. Design do Banco de Dados

### 3.1 Novas Tabelas

#### TABLE: fiscal_documents (Documentos Fiscais)

```sql
CREATE TABLE fiscal_documents (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    tenant_id UUID NOT NULL,
    warehouse_id UUID NOT NULL,
    
    -- Identificação do Documento Fiscal
    document_id VARCHAR(100) NOT NULL,
    document_type VARCHAR(20) DEFAULT 'NF-e',  -- NF-e, NFC-e, CF-e
    access_key VARCHAR(50) UNIQUE,  -- Chave de acesso NF-e
    
    -- Informações de Origem
    supplier_id UUID NOT NULL,
    supplier_cnpj VARCHAR(18),
    supplier_name VARCHAR(255),
    
    -- Datas
    issue_date DATE NOT NULL,
    emission_date TIMESTAMP NOT NULL,
    receipt_date TIMESTAMP,
    
    -- Valores
    subtotal DECIMAL(15,2),
    total_value DECIMAL(15,2),
    total_items INT,
    
    -- Status
    fiscal_status ENUM (
        'EMITIDA',
        'CANCELADA',
        'DENEGADA',
        'REJEITADA'
    ) DEFAULT 'EMITIDA',
    
    -- Rastreamento
    asn_id UUID UNIQUE,  -- Link para ASN
    received_lines INT DEFAULT 0,
    total_lines INT,
    
    -- Auditoria
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    received_at TIMESTAMP,
    created_by UUID,
    
    FOREIGN KEY (tenant_id) REFERENCES tenants(id),
    FOREIGN KEY (warehouse_id) REFERENCES warehouses(id),
    FOREIGN KEY (supplier_id) REFERENCES suppliers(id),
    FOREIGN KEY (created_by) REFERENCES users(id),
    
    UNIQUE(tenant_id, document_id)
);

CREATE INDEX idx_fiscal_documents_access_key ON fiscal_documents(access_key);
CREATE INDEX idx_fiscal_documents_supplier ON fiscal_documents(supplier_id);
CREATE INDEX idx_fiscal_documents_status ON fiscal_documents(fiscal_status);
CREATE INDEX idx_fiscal_documents_date ON fiscal_documents(issue_date);
```

#### TABLE: fiscal_document_items (Itens de Documentos Fiscais)

```sql
CREATE TABLE fiscal_document_items (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    fiscal_document_id UUID NOT NULL,
    tenant_id UUID NOT NULL,
    
    -- Identificação do Item
    item_number INT NOT NULL,  -- Sequencial (1, 2, 3...)
    sku_id UUID NOT NULL,
    
    -- Descrição
    product_description VARCHAR(500),
    ncm VARCHAR(10),  -- Nomenclatura Comum do Mercosul
    cfop VARCHAR(4),  -- Código Fiscal de Operação
    
    -- Quantidades
    quantity INT NOT NULL,
    unit_measure VARCHAR(10) DEFAULT 'UN',  -- Unidade de Medida
    
    -- Valores
    unit_price DECIMAL(12,2),
    line_total DECIMAL(15,2),
    
    -- Impostos (ICMS, PIS, COFINS, etc)
    icms_rate DECIMAL(5,2),
    icms_value DECIMAL(15,2),
    pis_rate DECIMAL(5,2),
    pis_value DECIMAL(15,2),
    cofins_rate DECIMAL(5,2),
    cofins_value DECIMAL(15,2),
    
    -- Lote/Série
    batch_number VARCHAR(100),
    lot_number VARCHAR(100),
    expiration_date DATE,
    serial_number VARCHAR(100),
    
    -- Status
    item_status ENUM (
        'PENDENTE',
        'RECEBIDO',
        'PARCIALMENTE_RECEBIDO',
        'REJEITADO'
    ) DEFAULT 'PENDENTE',
    
    received_quantity INT DEFAULT 0,
    rejected_quantity INT DEFAULT 0,
    
    -- Auditoria
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    received_at TIMESTAMP,
    
    FOREIGN KEY (fiscal_document_id) REFERENCES fiscal_documents(id) ON DELETE CASCADE,
    FOREIGN KEY (tenant_id) REFERENCES tenants(id),
    FOREIGN KEY (sku_id) REFERENCES skus(id),
    
    UNIQUE(fiscal_document_id, item_number)
);

CREATE INDEX idx_fiscal_items_sku ON fiscal_document_items(sku_id);
CREATE INDEX idx_fiscal_items_batch ON fiscal_document_items(batch_number);
CREATE INDEX idx_fiscal_items_status ON fiscal_document_items(item_status);
```

### 3.2 Modificações em Tabelas Existentes

#### TABLE: inventory_master (Adicionar Campos Fiscais)

```sql
ALTER TABLE inventory_master ADD COLUMN (
    -- Rastreamento Fiscal (OBRIGATÓRIO)
    fiscal_document_id UUID NOT NULL,
    fiscal_document_item_id UUID NOT NULL,
    
    -- Origem Fiscal
    fiscal_origin VARCHAR(50),  -- ENTRADA, DEVOLUCAO, TRANSFERENCIA
    
    -- Informações Fiscais
    ncm VARCHAR(10),
    cfop VARCHAR(4),
    icms_rate DECIMAL(5,2),
    
    -- Referência para Auditoria
    receipt_sequence INT,  -- Sequencial de recebimento
    
    FOREIGN KEY (fiscal_document_id) REFERENCES fiscal_documents(id),
    FOREIGN KEY (fiscal_document_item_id) REFERENCES fiscal_document_items(id)
);

CREATE INDEX idx_inventory_fiscal_doc ON inventory_master(fiscal_document_id);
CREATE INDEX idx_inventory_fiscal_item ON inventory_master(fiscal_document_item_id);
```

#### TABLE: locations (Adicionar Campo de Separação Fiscal)

```sql
ALTER TABLE locations ADD COLUMN (
    -- Configuração
    enforce_fiscal_separation BOOLEAN DEFAULT FALSE,
    -- Se TRUE, mesma localização não pode ter diferentes origem fiscal
    
    last_fiscal_document_id UUID,
    last_fiscal_origin VARCHAR(50)
);
```

#### TABLE: picking_orders (Adicionar Rastreamento Fiscal)

```sql
ALTER TABLE picking_orders ADD COLUMN (
    -- Rastreamento Fiscal
    fiscal_documents_involved TEXT[],  -- JSON array com IDs dos documentos
    fiscal_compliance_status VARCHAR(50),
    -- COMPLIANT, WARNING, VIOLATION
    
    fiscal_notes TEXT
);
```

### 3.3 Nova Tabela: Auditoria Fiscal

#### TABLE: fiscal_audit_trail

```sql
CREATE TABLE fiscal_audit_trail (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    tenant_id UUID NOT NULL,
    
    -- Rastreamento
    fiscal_document_id UUID,
    fiscal_document_item_id UUID,
    inventory_id UUID,
    
    -- Operação
    operation_type VARCHAR(50),  -- RECEBIMENTO, PICKING, DEVOLUCAO, AJUSTE
    
    -- Detalhes
    quantity_before INT,
    quantity_after INT,
    location_before UUID,
    location_after UUID,
    
    -- Conformidade
    fiscal_compliant BOOLEAN,
    violation_reason VARCHAR(500),
    
    -- Auditoria
    user_id UUID,
    user_role VARCHAR(50),
    ip_address INET,
    
    -- Timestamp
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    
    FOREIGN KEY (tenant_id) REFERENCES tenants(id),
    FOREIGN KEY (fiscal_document_id) REFERENCES fiscal_documents(id),
    FOREIGN KEY (fiscal_document_item_id) REFERENCES fiscal_document_items(id),
    FOREIGN KEY (inventory_id) REFERENCES inventory_master(id),
    FOREIGN KEY (user_id) REFERENCES users(id)
);

CREATE INDEX idx_fiscal_audit_doc ON fiscal_audit_trail(fiscal_document_id);
CREATE INDEX idx_fiscal_audit_date ON fiscal_audit_trail(created_at DESC);
CREATE INDEX idx_fiscal_audit_user ON fiscal_audit_trail(user_id);
```

---

## 4. Fluxos de Operação

### 4.1 Recebimento com Rastreamento Fiscal

```
┌─────────────────────────────────────────────────────────┐
│ 1. ERP ENVIA ASN COM DADOS FISCAIS                      │
└─────────────────┬───────────────────────────────────────┘
                  │
                  ▼
┌─────────────────────────────────────────────────────────┐
│ 2. WMS RECEBE E VALIDA DOCUMENTO FISCAL                 │
│    ├─ Verifica access_key da NF-e                      │
│    ├─ Valida status no SEFAZ (se online)               │
│    ├─ Confere integridade dos dados                     │
│    └─ Cria registro de fiscal_documents                 │
└─────────────────┬───────────────────────────────────────┘
                  │
                  ▼
┌─────────────────────────────────────────────────────────┐
│ 3. CRIA REGISTROS DE ITENS FISCAIS                      │
│    ├─ Um registro por item da NF                        │
│    ├─ Armazena NCM, CFOP, ICMS, etc                    │
│    └─ fiscal_document_items são criados                │
└─────────────────┬───────────────────────────────────────┘
                  │
                  ▼
┌─────────────────────────────────────────────────────────┐
│ 4. OPERADOR RECEBE MERCADORIA                           │
│    ├─ Escaneiacodigo de barras do produto             │
│    ├─ Confirma quantidade recebida                      │
│    └─ Sistema associa automaticamente ao item fiscal    │
└─────────────────┬───────────────────────────────────────┘
                  │
                  ▼
┌─────────────────────────────────────────────────────────┐
│ 5. CRIA INVENTORY_MASTER COM DADOS FISCAIS              │
│    ├─ fiscal_document_id = ID da NF                     │
│    ├─ fiscal_document_item_id = ID do item              │
│    ├─ fiscal_origin = 'ENTRADA'                         │
│    ├─ ncm, cfop, icms_rate copiados                    │
│    └─ Rastreabilidade 100% estabelecida                │
└─────────────────┬───────────────────────────────────────┘
                  │
                  ▼
┌─────────────────────────────────────────────────────────┐
│ 6. ALOCA PARA LOCALIZAÇÃO RESPEITANDO FISCAL            │
│    ├─ Se enforce_fiscal_separation = true              │
│    │  └─ Localização deve ter mesmo documento fiscal   │
│    ├─ Se false                                          │
│    │  └─ Pode consolidar (mas rastreabilidade mantida) │
│    └─ inventory_master.location_id é preenchido        │
└─────────────────┬───────────────────────────────────────┘
                  │
                  ▼
┌─────────────────────────────────────────────────────────┐
│ 7. REGISTRA AUDITORIA FISCAL                            │
│    ├─ Quem recebeu                                      │
│    ├─ Quando recebeu                                    │
│    ├─ Dados fiscais completos                           │
│    └─ Conformidade: OK                                  │
└─────────────────────────────────────────────────────────┘
```

### 4.2 Picking com Validação Fiscal

```
Pedido solicita 50 unidades de SKU-001

CENÁRIO 1: Mesma origem fiscal
├─ 50 un disponíveis de NF-001
├─ Picking simples: pegar os 50 de NF-001
└─ picking_orders.fiscal_documents_involved = ["NF-001"]

CENÁRIO 2: Múltiplas origem fiscal
├─ 30 un disponíveis de NF-001 (ICMS 7%)
└─ 50 un disponíveis de NF-002 (ICMS 12%)

Opções:
┌─ Opção A: Respeitar separação
│  └─ Picking 1: 30 un de NF-001
│     Picking 2: 20 un de NF-002
│     (Gera 2 pedidos separados)
│
├─ Opção B: Consolidar com aviso
│  ├─ 1 Picking: 30 (NF-001) + 20 (NF-002)
│  ├─ fiscal_compliance_status = "WARNING"
│  ├─ Requer aprovação de supervisor
│  └─ picking_orders.fiscal_documents_involved = ["NF-001", "NF-002"]
│
└─ Opção C: Rejeitar e esperar
   └─ Bloqueia até reabastecimento de mesma origem
```

---

## 5. Integração com ERP

### 5.1 API de Sincronização Fiscal

**Endpoint: POST /api/v1/fiscal/documents/sync**

```json
{
  "action": "CREATE_FROM_NF",
  "data": {
    "document_id": "NF-E-2025-000001",
    "access_key": "35250101234567000123550010000000011234567890",
    "supplier": {
      "cnpj": "12345678901234",
      "name": "Fornecedor LTDA"
    },
    "issue_date": "2025-01-10",
    "total_value": 50000.00,
    "items": [
      {
        "item_number": 1,
        "sku_code": "SKU-001",
        "description": "Produto A",
        "quantity": 100,
        "unit_price": 500.00,
        "ncm": "1234567890",
        "cfop": "1102",
        "icms_rate": 7.00,
        "batch_number": "LOTE-2024-001",
        "expiration_date": "2026-01-10"
      }
    ]
  }
}
```

**Response:**

```json
{
  "status": "success",
  "fiscal_document_id": "uuid-xxx",
  "items_created": 1,
  "fiscal_status": "REGISTRADO",
  "can_receive": true,
  "message": "Documento fiscal registrado com sucesso"
}
```

### 5.2 Webhook de Confirmação

**ERP envia confirmação para WMS quando mercadoria é recebida:**

```json
POST {erp_callback_url}/wms/fiscal-receipt-confirmation

{
  "fiscal_document_id": "NF-E-2025-000001",
  "item_number": 1,
  "warehouse_id": "wh-001",
  "location_id": "AISLE-A-1-1-A",
  "quantity_received": 100,
  "receipt_date": "2025-01-11T10:30:00Z",
  "inventory_id": "inv-xxxxx",
  "audit_trail_id": "audit-xxxxx"
}
```

---

## 6. Algoritmos de Alocação Fiscal

### 6.1 Alocação Inteligente com Separação Fiscal

```go
// PseudoCódigo do Algoritmo de Alocação Fiscal

func AllocateWithFiscalTracking(
    inventoryItem InventoryMaster,
    warehouse Warehouse,
) (Location, error) {
    
    // 1. Validar que item tem dados fiscais
    if inventoryItem.FiscalDocumentID == "" {
        return nil, errors.New("FISCAL_DOCUMENT_REQUIRED")
    }
    
    // 2. Procurar localização compatível
    compatibleLocations := FindCompatibleLocations(
        warehouse,
        inventoryItem.SKU,
        inventoryItem.FiscalDocumentID,
    )
    
    // 3. Se enforce_fiscal_separation = true
    if warehouse.EnforceFiscalSeparation {
        // Apenas localizações vazias OU com mesmo documento fiscal
        compatibleLocations = FilterByFiscalDocument(
            compatibleLocations,
            inventoryItem.FiscalDocumentID,
        )
    }
    
    // 4. Selecionar melhor localização
    bestLocation := SelectBestLocation(compatibleLocations)
    
    // 5. Atualizar localização
    bestLocation.LastFiscalDocumentID = inventoryItem.FiscalDocumentID
    bestLocation.LastFiscalOrigin = inventoryItem.FiscalOrigin
    
    return bestLocation, nil
}

func FindCompatibleLocations(
    warehouse Warehouse,
    sku SKU,
    fiscalDocID string,
) []Location {
    
    var compatible []Location
    
    for _, location := range warehouse.Locations {
        // Verificar capacidade
        if !location.CanAccommodate(sku) {
            continue
        }
        
        // Verificar produto específico
        if !location.AllowsProduct(sku) {
            continue
        }
        
        // Se vazia, sempre compatível
        if location.IsEmpty() {
            compatible = append(compatible, location)
            continue
        }
        
        // Se não-vazia, verificar compatibilidade
        existingFiscalDoc := location.GetFiscalDocument()
        
        // Se mesmo documento fiscal, compatível
        if existingFiscalDoc == fiscalDocID {
            compatible = append(compatible, location)
            continue
        }
        
        // Se enforce_fiscal_separation, incompatível
        if location.EnforceFiscalSeparation {
            continue
        }
        
        // Caso contrário, ainda é compatível (mas registra warning)
        compatible = append(compatible, location)
    }
    
    return compatible
}
```

### 6.2 Algoritmo de Picking Fiscal

```go
func GeneratePickingOrder(
    salesOrder SalesOrder,
    warehouse Warehouse,
) ([]PickingTask, error) {
    
    var pickingTasks []PickingTask
    var fiscalDocsInvolved = make(map[string]bool)
    
    for _, orderLine := range salesOrder.Lines {
        var qtyRemaining = orderLine.Quantity
        var tasks []PickingTask
        
        // 1. Buscar produtos disponíveis
        availableInventory := FindInventory(
            warehouse,
            orderLine.SKU,
        )
        
        // 2. Ordenar por preferência fiscal
        availableInventory = SortByFiscalPreference(availableInventory)
        
        // 3. Gerar tasks
        for _, invItem := range availableInventory {
            if qtyRemaining == 0 {
                break
            }
            
            qtyToPick := min(qtyRemaining, invItem.Quantity)
            
            task := PickingTask{
                OrderLineID: orderLine.ID,
                InventoryID: invItem.ID,
                Quantity: qtyToPick,
                Location: invItem.Location,
                
                // Rastreamento Fiscal
                FiscalDocument: invItem.FiscalDocumentID,
                FiscalItem: invItem.FiscalDocumentItemID,
            }
            
            tasks = append(tasks, task)
            fiscalDocsInvolved[invItem.FiscalDocumentID] = true
            qtyRemaining -= qtyToPick
        }
        
        // 4. Validar se conseguiu atender
        if qtyRemaining > 0 {
            return nil, errors.New("INSUFFICIENT_INVENTORY")
        }
        
        pickingTasks = append(pickingTasks, tasks...)
    }
    
    // 5. Determinar conformidade fiscal
    pickingOrder := CreatePickingOrder(pickingTasks)
    pickingOrder.FiscalDocumentsInvolved = GetKeys(fiscalDocsInvolved)
    
    if len(fiscalDocsInvolved) > 1 {
        pickingOrder.FiscalComplianceStatus = "WARNING"
        pickingOrder.FiscalNotes = "Múltiplos documentos fiscais envolvidos"
    } else {
        pickingOrder.FiscalComplianceStatus = "COMPLIANT"
    }
    
    return pickingTasks, nil
}

func SortByFiscalPreference(inventory []InventoryMaster) []InventoryMaster {
    // Ordenar para:
    // 1. Agrupar por documento fiscal (minimizar mistura)
    // 2. FIFO dentro de cada documento
    // 3. Lotes que vencem logo em seguida
    
    sort.Slice(inventory, func(i, j int) bool {
        // Primeiro: agrupar por fiscal_document_id
        if inventory[i].FiscalDocumentID != inventory[j].FiscalDocumentID {
            return inventory[i].FiscalDocumentID < inventory[j].FiscalDocumentID
        }
        
        // Dentro do mesmo documento: FIFO
        if inventory[i].CreatedAt != inventory[j].CreatedAt {
            return inventory[i].CreatedAt.Before(inventory[j].CreatedAt)
        }
        
        // Por fim: expiration date
        if inventory[i].ExpirationDate != inventory[j].ExpirationDate {
            return inventory[i].ExpirationDate.Before(inventory[j].ExpirationDate)
        }
        
        return false
    })
    
    return inventory
}
```

---

## 7. Rastreabilidade Completa

### 7.1 Cadeia de Rastreamento

```
NF-E-2025-000001 (Item 1: 100 un de SKU-001)
       │
       ├─ fiscal_document_id: uuid-doc-001
       ├─ fiscal_document_item_id: uuid-item-001
       │
       ▼
RECEBIMENTO: 100 un → Localização AISLE-A-1-1-A
       │
       ├─ inventory_master[1]: 100 un
       │  ├─ fiscal_document_id: uuid-doc-001
       │  ├─ fiscal_document_item_id: uuid-item-001
       │  ├─ location_id: loc-A
       │  └─ fiscal_origin: ENTRADA
       │
       ├─ audit_trail[1]: Recebimento registrado
       │  └─ fiscal_compliant: true
       │
       ▼
PICKING: 50 un para Pedido #PED-001
       │
       ├─ picking_line[1]: 50 un
       │  ├─ inventory_id: inv-1
       │  ├─ fiscal_document_id: uuid-doc-001 ✅
       │  └─ quantity_picked: 50
       │
       ├─ picking_order[1]:
       │  ├─ fiscal_documents_involved: [uuid-doc-001]
       │  ├─ fiscal_compliance_status: COMPLIANT
       │  └─ audit_trail[2]: Picking realizado
       │
       ▼
PACKING: 50 un em Package #PKG-001
       │
       ├─ package[1]: 50 un
       │  ├─ fiscal_document_source: uuid-doc-001
       │  └─ picking_order_id: po-1
       │
       ▼
SHIPPING: 50 un saem do armazém
       │
       ├─ shipment[1]: 50 un
       │  ├─ fiscal_document_source: uuid-doc-001
       │  ├─ package_ids: [pkg-1]
       │  └─ nf_saida_id: uuid-doc-saida-001
       │
       ▼
CLIENTE RECEBE: 50 un
       │
       └─ Rastreabilidade reversa: uuid-doc-001 → Cliente A

=====================================

AUDITORIA COMPLETA:
  NF-E entrada: uuid-doc-001
  Item: 1 (100 un SKU-001)
  Recebimento: 2025-01-11 10:00
  Picking: 2025-01-12 14:30 (50 un)
  Shipping: 2025-01-12 16:45 (50 un)
  Cliente: Cliente A
  NF-e saída: uuid-doc-saida-001

✅ Rastreamento completo desde entrada até saída
```

### 7.2 Query de Rastreamento Completo

```sql
-- Rastrear origem fiscal de um produto no cliente

SELECT 
    fd.document_id as nf_entrada,
    fdi.item_number,
    fdi.ncm,
    fdi.cfop,
    fdi.icms_rate,
    im.quantity_on_hand,
    im.location_id,
    po.id as picking_order_id,
    pkg.package_number,
    sh.shipment_number,
    sh.manifest_number,
    c.name as customer_name,
    sh_saida.document_id as nf_saida,
    fat.created_at as audit_timestamp
FROM fiscal_documents fd
JOIN fiscal_document_items fdi ON fd.id = fdi.fiscal_document_id
JOIN inventory_master im ON fdi.id = im.fiscal_document_item_id
LEFT JOIN picking_lines pl ON im.id = pl.inventory_id
LEFT JOIN picking_orders po ON pl.picking_order_id = po.id
LEFT JOIN packages pkg ON pkg.picking_order_id = po.id
LEFT JOIN shipments sh ON sh.id = (
    SELECT shipment_id FROM shipment_packages 
    WHERE package_id = pkg.id LIMIT 1
)
LEFT JOIN fiscal_documents sh_saida ON sh.nf_saida_id = sh_saida.id
LEFT JOIN customers c ON sh.customer_id = c.id
LEFT JOIN fiscal_audit_trail fat ON fd.id = fat.fiscal_document_id
WHERE fd.access_key = '35250101234567000123550010000000011234567890'
ORDER BY fat.created_at ASC;
```

---

## 8. Relatórios Fiscais

### 8.1 Relatório de Conformidade Fiscal

```
RELATÓRIO: CONFORMIDADE FISCAL DE ARMAZENAGEM
Período: 01/01/2025 a 31/01/2025
Armazém: Armazém Centro - SP
Gerado em: 2025-01-31 17:00

═════════════════════════════════════════════════════════

RESUMO EXECUTIVO
└─ Total de NF-e Recebidas: 1.250
└─ Total de Itens: 5.680
└─ Total de Unidades: 125.340
└─ Conformidade: 99,8%

═════════════════════════════════════════════════════════

RECEBIMENTO
├─ Documentos Fiscais Processados: 1.250
├─ Documentos com Divergência: 3
│  ├─ Quantidade divergente: 2
│  └─ Dados incorretos: 1
├─ Documentos Rejeitados: 0
└─ Taxa de Aceito: 99,76%

═════════════════════════════════════════════════════════

ARMAZENAGEM
├─ SKUs Distintos Armazenados: 385
├─ Localizações Utilizadas: 2.145
├─ Separação Fiscal Obrigatória: 128
│  └─ Conformidade: 100%
├─ Consolidação Autorizada: 42
│  └─ Documentos distintos: 2-5 por localização
└─ Status Geral: ✅ CONFORME

═════════════════════════════════════════════════════════

PICKING & SAÍDA
├─ Pedidos Processados: 3.200
├─ Picking com Múltiplos Documentos Fiscais: 145
│  ├─ Com Aprovação: 142
│  └─ Sem Aprovação: 3 (VIOLAÇÕES)
├─ NF-e de Saída Geradas: 3.200
└─ Rastreabilidade: 100%

═════════════════════════════════════════════════════════

CONFORMIDADE REGULATÓRIA
├─ SPED - Escrituração Fiscal: ✅ OK
├─ NF-e - Documentos Eletrônicos: ✅ OK
├─ ICMS - Impostos Estaduais: ✅ OK
├─ PIS/COFINS: ✅ OK
└─ Audit Trail Completo: ✅ OK

═════════════════════════════════════════════════════════

VIOLAÇÕES ENCONTRADAS
├─ Violation #1
│  ├─ Data: 2025-01-15
│  ├─ Tipo: PICKING_SEM_SEPARACAO_FISCAL
│  ├─ Picking Order: PO-2025-00145
│  ├─ Documentos Envolvidos: NF-001, NF-002
│  ├─ Status: Corrigido retroativamente
│  └─ Ação Recomendada: Retreinamento de operador
│
├─ Violation #2
│  ├─ Data: 2025-01-22
│  ├─ Tipo: INVENTORY_SEM_FISCAL_DOCUMENT
│  ├─ Quantidade: 5 unidades
│  ├─ Status: Investigação em andamento
│  └─ Ação Recomendada: Buscar origem no ERP

└─ Taxa de Violação: 0,2% (3/1.500 operações)

═════════════════════════════════════════════════════════

RECOMENDAÇÕES
└─ Conformidade geral excelente
└─ Investigar violações encontradas
└─ Reforçar treinamento sobre separação fiscal
└─ Revisar configuração de enforce_fiscal_separation
```

### 8.2 Relatório de Rastreabilidade por NF

```sql
SELECT 
    fd.document_id,
    fd.issue_date,
    s.name as supplier,
    COUNT(DISTINCT fdi.id) as total_items,
    SUM(fdi.quantity) as total_units,
    COUNT(DISTINCT im.location_id) as locations_used,
    COUNT(DISTINCT po.id) as picking_orders,
    SUM(CASE WHEN po.fiscal_compliance_status = 'COMPLIANT' THEN 1 ELSE 0 END) as compliant_picks,
    SUM(CASE WHEN po.fiscal_compliance_status = 'WARNING' THEN 1 ELSE 0 END) as warning_picks,
    SUM(CASE WHEN po.fiscal_compliance_status = 'VIOLATION' THEN 1 ELSE 0 END) as violation_picks,
    MAX(fat.created_at) as last_movement
FROM fiscal_documents fd
LEFT JOIN suppliers s ON fd.supplier_id = s.id
LEFT JOIN fiscal_document_items fdi ON fd.id = fdi.fiscal_document_id
LEFT JOIN inventory_master im ON fdi.id = im.fiscal_document_item_id
LEFT JOIN picking_lines pl ON im.id = pl.inventory_id
LEFT JOIN picking_orders po ON pl.picking_order_id = po.id
LEFT JOIN fiscal_audit_trail fat ON fd.id = fat.fiscal_document_id
GROUP BY fd.id, fd.document_id, fd.issue_date, s.name
ORDER BY fd.issue_date DESC;
```

---

## 9. Conformidade Regulatória

### 9.1 Requisitos Legais

```
CONFORMIDADE BRASILEIRA (OBRIGATÓRIA)

✅ SPED - Sistema Público de Escrituração Digital
   └─ Mantém registro de todas as operações com origem fiscal
   └─ Auditoria trail disponível para Receita Federal
   
✅ NF-e - Nota Fiscal Eletrônica
   └─ Valida chave de acesso
   └─ Sincroniza status com SEFAZ
   └─ Gera NF-e de saída com referência de entrada
   
✅ ICMS - Imposto sobre Circulação de Mercadorias
   └─ Registra alíquota ICMS em cada operação
   └─ Permite apuração correta em APURAÇÃO
   
✅ PIS/COFINS - Contribuições Sociais
   └─ Rastreia valor de entrada
   └─ Permite cálculo de créditos
   
✅ Lockbox/Rastreabilidade
   └─ Cada operação é imutável
   └─ Auditoria temporal preservada
   └─ Impossível alterar dados históricos

CONFORMIDADE INTERNACIONAL

✅ GDPR (se aplicável)
   └─ Anonimização de dados pessoais possível
   
✅ SOX (se company pública)
   └─ Controles internos para dados financeiros
   └─ Auditoria trail completo
```

### 9.2 Testes de Conformidade

```
SUITE DE TESTES: Conformidade Fiscal

Test 1: Toda entrada deve ter documento fiscal
  ├─ Setup: Criar inventory_master SEM fiscal_document_id
  ├─ Validação: Sistema rejeita operação
  └─ Result: PASS/FAIL

Test 2: ICMS correto em cada operação
  ├─ Setup: Receber item com ICMS 7%
  ├─ Validação: Picking preserva ICMS 7%
  └─ Result: PASS/FAIL

Test 3: Rastreabilidade reversa funciona
  ├─ Setup: Rastrear um produto até a NF de origem
  ├─ Validação: Query retorna NF-E correta
  └─ Result: PASS/FAIL

Test 4: Separação fiscal é obedecida
  ├─ Setup: enforce_fiscal_separation = true
  ├─ Validação: Sistema rejeita consolidação incorreta
  └─ Result: PASS/FAIL

Test 5: Auditoria é imutável
  ├─ Setup: Tentar alterar fiscal_audit_trail
  ├─ Validação: Sistema rejeita UPDATE
  └─ Result: PASS/FAIL

Test 6: Devolução mantém origem
  ├─ Setup: Devolver item que veio de NF-001
  ├─ Validação: Devolução referencia NF-001
  └─ Result: PASS/FAIL
```

---

## 10. Exemplos de Implementação

### 10.1 Exemplo: Recebimento Fiscal Completo

```go
package receiving

import (
    "context"
    "fmt"
    "wms/internal/domain"
    "wms/internal/fiscal"
)

type ReceivingService struct {
    repo       ReceivingRepository
    fiscalSvc  *fiscal.Service
    inventory  InventoryRepository
    auditLog   AuditLogRepository
}

// ReceiveWithFiscalTracking processa entrada com rastreamento fiscal
func (s *ReceivingService) ReceiveWithFiscalTracking(
    ctx context.Context,
    asnID string,
    fiscalData *fiscal.InboundFiscalData,
    operatorID string,
) error {
    
    // 1. Validar que ASN tem referência fiscal
    asn, err := s.repo.GetASN(ctx, asnID)
    if err != nil {
        return fmt.Errorf("get ASN: %w", err)
    }
    
    if asn.Status != domain.ASNStatusScheduled {
        return fmt.Errorf("ASN not in SCHEDULED status")
    }
    
    // 2. Criar registro de documento fiscal
    fiscalDoc, err := s.fiscalSvc.CreateFiscalDocument(ctx, fiscalData)
    if err != nil {
        return fmt.Errorf("create fiscal document: %w", err)
    }
    
    // 3. Para cada item fiscal
    for _, itemData := range fiscalData.Items {
        
        // 4. Validar SKU existe
        sku, err := s.repo.GetSKU(ctx, itemData.SKUCode)
        if err != nil {
            return fmt.Errorf("get SKU: %w", err)
        }
        
        // 5. Criar registro de item fiscal
        fiscalItem, err := s.fiscalSvc.CreateFiscalItem(
            ctx,
            fiscalDoc.ID,
            itemData,
            sku.ID,
        )
        if err != nil {
            return fmt.Errorf("create fiscal item: %w", err)
        }
        
        // 6. Criar inventory_master com rastreamento fiscal
        inventory := &domain.InventoryMaster{
            WarehouseID:           asn.WarehouseID,
            SKUID:                 sku.ID,
            QuantityOnHand:        itemData.Quantity,
            QuantityReserved:      0,
            
            // ✅ DADOS FISCAIS (OBRIGATÓRIO)
            FiscalDocumentID:      fiscalDoc.ID,
            FiscalDocumentItemID:  fiscalItem.ID,
            FiscalOrigin:          "ENTRADA",
            NCM:                   itemData.NCM,
            CFOP:                  itemData.CFOP,
            ICMSRate:              itemData.ICMSRate,
            ReceiptSequence:       itemData.ReceiptSequence,
        }
        
        // 7. Alocar para localização respeitando fiscal
        location, err := s.AllocateWithFiscalTracking(
            ctx,
            asn.WarehouseID,
            inventory,
        )
        if err != nil {
            return fmt.Errorf("allocate with fiscal: %w", err)
        }
        
        inventory.LocationID = location.ID
        
        // 8. Salvar inventory
        if err := s.inventory.Create(ctx, inventory); err != nil {
            return fmt.Errorf("create inventory: %w", err)
        }
        
        // 9. Registrar na auditoria fiscal
        auditEntry := &domain.FiscalAuditTrail{
            TenantID:              asn.TenantID,
            FiscalDocumentID:      fiscalDoc.ID,
            FiscalDocumentItemID:  fiscalItem.ID,
            InventoryID:           inventory.ID,
            OperationType:         "RECEBIMENTO",
            QuantityAfter:         itemData.Quantity,
            LocationAfter:         location.ID,
            FiscalCompliant:       true,
            UserID:                operatorID,
        }
        
        if err := s.auditLog.CreateFiscalEntry(ctx, auditEntry); err != nil {
            return fmt.Errorf("create audit entry: %w", err)
        }
    }
    
    // 10. Atualizar status do ASN
    asn.Status = domain.ASNStatusFullyReceived
    if err := s.repo.UpdateASN(ctx, asn); err != nil {
        return fmt.Errorf("update ASN: %w", err)
    }
    
    // 11. Publicar evento
    event := &domain.Event{
        Type:     "InboundFiscalReceived",
        AggregateID: asnID,
        Data:     fiscalData,
        Timestamp: time.Now(),
    }
    
    return s.repo.PublishEvent(ctx, event)
}

// AllocateWithFiscalTracking aloca respeitando restrições fiscais
func (s *ReceivingService) AllocateWithFiscalTracking(
    ctx context.Context,
    warehouseID string,
    inventory *domain.InventoryMaster,
) (*domain.Location, error) {
    
    warehouse, err := s.repo.GetWarehouse(ctx, warehouseID)
    if err != nil {
        return nil, fmt.Errorf("get warehouse: %w", err)
    }
    
    // Buscar localizações compatíveis
    locations, err := s.FindCompatibleLocations(
        ctx,
        warehouse,
        inventory.SKUID,
        inventory.FiscalDocumentID,
    )
    if err != nil {
        return nil, fmt.Errorf("find locations: %w", err)
    }
    
    if len(locations) == 0 {
        return nil, fmt.Errorf("no compatible locations available")
    }
    
    // Selecionar melhor localização
    bestLocation := s.SelectBestLocation(locations)
    
    // Atualizar último documento fiscal da localização
    bestLocation.LastFiscalDocumentID = inventory.FiscalDocumentID
    bestLocation.LastFiscalOrigin = inventory.FiscalOrigin
    
    if err := s.repo.UpdateLocation(ctx, bestLocation); err != nil {
        return nil, fmt.Errorf("update location: %w", err)
    }
    
    return bestLocation, nil
}
```

### 10.2 Exemplo: Query de Rastreamento

```sql
-- Rastrear um produto específico da entrada até saída

WITH product_journey AS (
    SELECT 
        'ENTRADA' as stage,
        fd.document_id,
        fd.issue_date,
        fdi.item_number,
        im.quantity_on_hand,
        im.location_id,
        NULL as picking_order_id,
        NULL as shipment_id,
        fd.created_at as event_date,
        fd.created_by as user_id
    FROM fiscal_documents fd
    JOIN fiscal_document_items fdi ON fd.id = fdi.fiscal_document_id
    JOIN inventory_master im ON fdi.id = im.fiscal_document_item_id
    WHERE fd.document_id = 'NF-E-2025-000001'
    
    UNION ALL
    
    SELECT 
        'PICKING',
        fd.document_id,
        fd.issue_date,
        fdi.item_number,
        pl.quantity_required,
        loc.location_code,
        po.id,
        NULL,
        po.started_at,
        po.assigned_to_user_id
    FROM fiscal_documents fd
    JOIN fiscal_document_items fdi ON fd.id = fdi.fiscal_document_id
    JOIN inventory_master im ON fdi.id = im.fiscal_document_item_id
    JOIN picking_lines pl ON im.id = pl.inventory_id
    JOIN picking_orders po ON pl.picking_order_id = po.id
    JOIN locations loc ON pl.location_id = loc.id
    WHERE fd.document_id = 'NF-E-2025-000001'
    
    UNION ALL
    
    SELECT 
        'SHIPPING',
        fd.document_id,
        fd.issue_date,
        fdi.item_number,
        sp.quantity_shipped,
        NULL,
        NULL,
        sh.id,
        sh.dispatched_at,
        NULL
    FROM fiscal_documents fd
    JOIN fiscal_document_items fdi ON fd.id = fdi.fiscal_document_id
    JOIN inventory_master im ON fdi.id = im.fiscal_document_item_id
    JOIN picking_lines pl ON im.id = pl.inventory_id
    JOIN picking_orders po ON pl.picking_order_id = po.id
    JOIN shipment_picking_orders spo ON po.id = spo.picking_order_id
    JOIN shipments sh ON spo.shipment_id = sh.id
    JOIN shipment_packages sp ON sh.id = sp.shipment_id
    WHERE fd.document_id = 'NF-E-2025-000001'
)

SELECT * FROM product_journey ORDER BY event_date ASC;
```

---

## ✅ Checklist de Implementação

```
Banco de Dados
├─ [ ] Criar tabela fiscal_documents
├─ [ ] Criar tabela fiscal_document_items
├─ [ ] Criar tabela fiscal_audit_trail
├─ [ ] Adicionar campos a inventory_master
├─ [ ] Adicionar campos a locations
├─ [ ] Adicionar campos a picking_orders
├─ [ ] Criar índices de performance
└─ [ ] Migração: teste em staging

APIs
├─ [ ] POST /api/v1/fiscal/documents/sync
├─ [ ] GET /api/v1/fiscal/documents/{id}
├─ [ ] GET /api/v1/fiscal/document/{id}/items
├─ [ ] POST /api/v1/fiscal/trace/{inventory_id}
├─ [ ] GET /api/v1/fiscal/audit-trail
└─ [ ] Documentação Swagger

Serviços
├─ [ ] FiscalService implementado
├─ [ ] ReceivingService com fiscal tracking
├─ [ ] AllocationService com validação fiscal
├─ [ ] PickingService com conformidade
├─ [ ] AuditService para trailing

Testes
├─ [ ] Teste unitário: criação documento fiscal
├─ [ ] Teste unitário: validação de item
├─ [ ] Teste integração: recebimento completo
├─ [ ] Teste integração: picking com múltiplos docs
├─ [ ] Teste conformidade: rastreabilidade
├─ [ ] Teste conformidade: impossibilidade de alteração
├─ [ ] Teste de carga: performance de queries

Relatórios
├─ [ ] Relatório conformidade fiscal
├─ [ ] Relatório rastreabilidade por NF
├─ [ ] Relatório SPED
├─ [ ] Dashboard fiscal em tempo real

Integração ERP
├─ [ ] Sincronização de NF-e
├─ [ ] Webhook de confirmação
├─ [ ] Retry logic
├─ [ ] Error handling

Documentação
├─ [ ] Guia para operators
├─ [ ] Guia para analistas
├─ [ ] Runbook de troubleshooting
└─ [ ] Atualizar diagrama de arquitetura
```

---

**Documento Versão:** 1.0  
**Status:** Especificação Completa  
**Data:** Janeiro 2025  
**Próxima Etapa:** Implementação Técnica

🚀 **Módulo Fiscal 100% Especificado e Pronto para Desenvolvimento!**
