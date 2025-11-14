# SEGURANÇA - WMS ENTERPRISE

## 1. Política de Segurança

### 1.1 Princípios

1. **Defense in Depth:** Múltiplas camadas de proteção
2. **Least Privilege:** Mínima permissão necessária
3. **Fail Secure:** Em caso de erro, preferir negar acesso
4. **Audit Trail:** Registrar tudo que importa
5. **Encryption by Default:** Sempre encriptado
6. **Zero Trust:** Nunca confiar, sempre verificar

---

## 2. Autenticação e Autorização

### 2.1 Autenticação Multi-fator (MFA)

**Requisitos:**
- MFA obrigatória para roles com acesso crítico
- Métodos suportados:
  - TOTP (Google Authenticator, Authy)
  - SMS (fallback, menos seguro)
  - Hardware key (FIDO2)

**Fluxo:**
```
Usuário digita email + senha
    ↓
[Validar credenciais contra bcrypt hash]
    ↓
Se correto e MFA habilitado:
    └─ Gerar código TOTP/enviar SMS
    └─ Usuário confirma código
    ↓
[Gerar JWT com 24h de validade]
    ↓
Usuário autenticado
```

### 2.2 JWT (JSON Web Token)

**Estrutura:**
```
Header.Payload.Signature

Header:
{
  "alg": "RS256",
  "typ": "JWT",
  "kid": "2024-01-key"  // Key ID para rotação
}

Payload:
{
  "sub": "user-uuid",           // Subject (user ID)
  "tenant_id": "tenant-uuid",   // Tenant isolation
  "roles": ["PICKING_OPERATOR", "QUALITY_INSPECTOR"],
  "permissions": ["picking:read", "picking:write"],
  "warehouses": ["WH-001", "WH-002"],
  "exp": 1705344000,            // Expiration (24h)
  "iat": 1705257600,            // Issued at
  "iss": "wms.example.com",     // Issuer
  "aud": "wms-users"            // Audience
}

Signature:
HMACSHA256(
  base64UrlEncode(header) + "." +
  base64UrlEncode(payload),
  secret
)
```

**Validação:**
```go
func validateJWT(tokenString string) (*Claims, error) {
    // 1. Parse JWT
    token, err := jwt.ParseWithClaims(tokenString, &Claims{}, func(token *jwt.Token) (interface{}, error) {
        // Verificar algoritmo
        if _, ok := token.Method.(*jwt.SigningMethodRSA); !ok {
            return nil, fmt.Errorf("unexpected signing method: %v", token.Header["alg"])
        }
        
        // Obter chave pública (com cache)
        return getPublicKey(token.Header["kid"]), nil
    })
    
    // 2. Extrair claims
    claims := token.Claims.(*Claims)
    
    // 3. Validações
    if !token.Valid {
        return nil, errors.New("invalid token")
    }
    
    if claims.ExpiresAt < time.Now().Unix() {
        return nil, errors.New("token expired")
    }
    
    if claims.TenantID == "" {
        return nil, errors.New("missing tenant_id")
    }
    
    return claims, nil
}
```

### 2.3 RBAC (Role-Based Access Control)

**Roles Pré-definidas:**

| Role | Permissões | Acesso |
|------|-----------|--------|
| WAREHOUSE_ADMIN | Tudo | Todos os armazéns |
| WAREHOUSE_SUPERVISOR | Leitura +, Supervisão | Seu armazém |
| INBOUND_OPERATOR | Receber, conferir | Recebimento |
| PICKING_OPERATOR | Picking | Picking |
| PACKING_OPERATOR | Packing | Packing |
| QUALITY_INSPECTOR | Inspeção | Qualidade |
| SHIPPING_MANAGER | Expedição | Expedição |
| ANALYTICS_VIEWER | Leitura | Reports |
| SUPPORT_ADMIN | Debug | Suporte técnico |

**Permissões Granulares:**
```json
{
  "picking:read": "Visualizar picking orders",
  "picking:write": "Editar picking orders",
  "picking:assign": "Atribuir picking",
  "picking:complete": "Completar picking",
  "inventory:read": "Visualizar inventário",
  "inventory:write": "Editar quantidades",
  "reports:export": "Exportar relatórios",
  "admin:user_manage": "Gerenciar usuários"
}
```

### 2.4 Session Management

**Características:**
- Sessão com JWT (stateless)
- Sem cookies (exceto SameSite=Strict)
- Logout: Adicionar token em blacklist por 24h

**Detecção de Anomalias:**
- Login simultâneo de mesmo usuário em múltiplos locais
- Login fora do horário normal
- Localização geográfica suspeita
- Taxa de requisições anormal

---

## 3. Encriptação de Dados

### 3.1 Encriptação em Trânsito

**TLS 1.3 obrigatório:**
```
Requisito mínimo: TLS 1.3
Suportado: TLS 1.3 e 1.2 (TLS 1.2 por compatibilidade)
Desabilitado: SSL 3.0, TLS 1.0, 1.1
```

**Certificados:**
- Self-signed em desenvolvimento
- Certificado válido em staging/produção
- HSTS header: `Strict-Transport-Security: max-age=31536000; includeSubDomains`

**Cipher Suites Preferidos:**
```
TLS_AES_256_GCM_SHA384
TLS_AES_128_GCM_SHA256
TLS_CHACHA20_POLY1305_SHA256
```

### 3.2 Encriptação em Repouso

**Dados Sensíveis (obrigatório):**
- Senhas: bcrypt (cost 12)
- PII (CPF, CNPJ): AES-256-GCM
- Dados de integração (tokens API): AES-256-GCM
- Histórico de movimentação: AES-256-GCM (regulatório)

**Chaves de Encriptação:**
- Armazenadas em Vault (HashiCorp Vault)
- Rotação: Anual (ou conforme política)
- Backup: Replicadas geograficamente

**Exemplo: Encriptação AES-256**
```go
func encryptAES256(plaintext []byte, keyHex string) (string, error) {
    // Decodificar chave
    key, err := hex.DecodeString(keyHex)
    if err != nil {
        return "", err
    }
    
    // Criar cipher
    cipher, err := aes.NewCipher(key)
    if err != nil {
        return "", err
    }
    
    // GCM (Galois/Counter Mode) com autenticação
    gcm, err := cipher.NewGCM()
    if err != nil {
        return "", err
    }
    
    // Gerar nonce aleatório
    nonce := make([]byte, gcm.NonceSize())
    if _, err := io.ReadFull(rand.Reader, nonce); err != nil {
        return "", err
    }
    
    // Encriptar
    ciphertext := gcm.Seal(nonce, nonce, plaintext, nil)
    
    return base64.StdEncoding.EncodeToString(ciphertext), nil
}
```

---

## 4. Proteção contra Vulnerabilidades

### 4.1 OWASP Top 10 (2023)

| Vulnerabilidade | Proteção |
|---|---|
| 1. Broken Access Control | RBAC, Row-Level Security, audit logs |
| 2. Cryptographic Failures | AES-256, TLS 1.3, key rotation |
| 3. Injection | Prepared statements, input validation |
| 4. Insecure Design | Secure by design, threat modeling |
| 5. Security Misconfiguration | Hardened defaults, security scanning |
| 6. Vulnerable Components | SBOM, dependency scanning, updates |
| 7. Authentication Failures | MFA, session management, CAPTCHA |
| 8. Data Integrity Failures | Signing, checksums, audit trail |
| 9. Logging/Monitoring | Centralized logging, alertas |
| 10. SSRF | URL validation, allowlist, network segmentation |

### 4.2 SQL Injection Prevention

```go
// ❌ NUNCA fazer isto (SQL Injection)
query := fmt.Sprintf("SELECT * FROM orders WHERE id = '%s'", userInput)
db.Query(query)

// ✅ Usar prepared statements
query := "SELECT * FROM orders WHERE id = $1"
db.Query(query, userInput)

// ✅ Com ORM (SQLC)
err := db.GetOrderByID(ctx, orderID)
```

### 4.3 XSS Protection

```html
<!-- ❌ Vulnerável -->
<div id="username">{{ user_input }}</div>

<!-- ✅ Sanitizado -->
<div id="username">{{ htmlEscape(user_input) }}</div>

<!-- ✅ React sanitiza automaticamente -->
<div>{userInput}</div>

<!-- ✅ Content Security Policy -->
<meta http-equiv="Content-Security-Policy" content="
  default-src 'self';
  script-src 'self' 'unsafe-inline';
  style-src 'self' 'unsafe-inline';
  img-src 'self' data: https:;
  font-src 'self' data:;
  connect-src 'self' https://api.example.com;
  frame-ancestors 'none'
">
```

### 4.4 CSRF Protection

```html
<!-- Token CSRF em formulário -->
<form method="POST" action="/api/v1/orders">
  <input type="hidden" name="csrf_token" value="{{ csrfToken }}">
  <!-- ... -->
</form>

<!-- Ou header customizado (SPA) -->
fetch('/api/v1/orders', {
  method: 'POST',
  headers: {
    'X-CSRF-Token': csrfToken,
    'Content-Type': 'application/json'
  },
  body: JSON.stringify(data)
})
```

### 4.5 Rate Limiting

```go
// Middleware de rate limiting
func RateLimit(requester string, limit int, window time.Duration) bool {
    key := fmt.Sprintf("rate_limit:%s", requester)
    
    count, err := redis.Incr(key)
    if err != nil {
        return false // Falhar de forma segura
    }
    
    if count == 1 {
        redis.Expire(key, window)
    }
    
    return count <= limit
}

// Uso
// 100 requisições por minuto por user
if !RateLimit(userID, 100, time.Minute) {
    return http.StatusTooManyRequests
}
```

---

## 5. Auditoria e Compliance

### 5.1 Audit Trail

**Todas as operações são registradas:**

```json
{
  "id": "audit-uuid",
  "timestamp": "2024-01-15T10:30:00Z",
  "tenant_id": "tenant-uuid",
  "user_id": "user-uuid",
  "user_role": "PICKING_OPERATOR",
  "ip_address": "192.168.1.100",
  "user_agent": "Mozilla/5.0...",
  "action": "UPDATE",
  "entity_type": "PICKING_ORDER",
  "entity_id": "pick-order-uuid",
  "old_values": {
    "status": "IN_PROGRESS",
    "completed_lines": 3
  },
  "new_values": {
    "status": "COMPLETED",
    "completed_lines": 5
  },
  "changes_summary": "Order completed by operator",
  "result": "SUCCESS",
  "error_message": null,
  "duration_ms": 234
}
```

**Retenção:**
- Operacional: 90 dias (hot storage)
- Compliance: 7 anos (cold storage)
- Imutável: Não pode ser deletado (apenas marcado como archive)

### 5.2 LGPD Compliance (Lei Geral de Proteção de Dados)

**Direitos do Titular:**
- Acesso: Exportar dados pessoais (GDPR-like)
- Retificação: Corrigir dados incorretos
- Supressão: "Direito ao esquecimento"
- Portabilidade: Dados em formato aberto
- Consentimento: Opt-in explícito

**Implementação:**
```go
// 1. Exportar dados do usuário
func (s *dataService) ExportUserData(ctx context.Context, userID string) (*DataExport, error) {
    // Coletar de todas as tabelas
    data := &DataExport{
        User: s.getUserData(ctx, userID),
        Orders: s.getUserOrders(ctx, userID),
        AuditLog: s.getAuditLog(ctx, userID),
        // ...
    }
    
    // Retornar como JSON/ZIP
    return data, nil
}

// 2. Deletar usuário (com cascata)
func (s *dataService) DeleteUser(ctx context.Context, userID string) error {
    // 1. Verificar permissão do usuário
    // 2. Deletar de tabelas não-críticas
    // 3. Anonimizar em audit_log (LGPD)
    // 4. Manter referências históriacs
    
    return nil
}
```

### 5.3 NF-e Compliance (Brasil)

- Armazenamento seguro de XML de NF-e
- Rastreabilidade de movimentação fiscal
- Integração com SEFAZ
- Retenção conforme legislação (5 anos)

---

## 6. Vulnerabilidades Conhecidas e Mitigação

### 6.1 Denial of Service (DoS)

**Ataques:** 
- Flood de requisições
- Requisições com payload gigante
- Query complexo no banco

**Mitigação:**
```go
// 1. Rate limiting (por IP/usuário)
// 2. Limitar tamanho de payload
e.Use(middleware.BodyLimit("1M"))

// 3. Timeout em queries
ctx, cancel := context.WithTimeout(context.Background(), 30*time.Second)
defer cancel()

// 4. WAF (Web Application Firewall)
// - Usar AWS WAF, Cloudflare, etc
// - Bloquear padrões suspeitos

// 5. DDoS Protection
// - CDN com DDoS mitigation
// - Geographic filtering
```

### 6.2 Man-in-the-Middle (MITM)

**Mitigação:**
- TLS 1.3 obrigatório (não negociável)
- Certificate Pinning para aplicações mobile
- HPKP header (HTTP Public Key Pinning)

### 6.3 Privilege Escalation

**Mitigação:**
- Validar permissões em TODA operação crítica
- Não confiar no cliente (sempre validar no servidor)
- Audit log de cada operação admin

---

## 7. Infraestrutura de Segurança

### 7.1 Network Segmentation

```
┌─────────────────────────────────────────────────────┐
│ Internet                                             │
└──────────────────┬──────────────────────────────────┘
                   │
        ┌──────────▼────────────┐
        │   WAF / DDoS Shield   │
        └──────────┬────────────┘
                   │
        ┌──────────▼────────────┐
        │   Load Balancer       │
        │  (TLS Termination)    │
        └──────────┬────────────┘
                   │
        ┌──────────▼────────────┐
        │ API Gateway           │
        │ (Rate Limit, Auth)    │
        └──────────┬────────────┘
                   │
        ┌──────────▼──────────────────┐
        │ Kubernetes Cluster          │
        │ (Private Subnet)            │
        │                             │
        │ ├─ API Services (Pod)       │
        │ ├─ Database (Stateful)      │
        │ ├─ Cache (Stateful)         │
        │ └─ Message Broker           │
        │                             │
        └─────────────────────────────┘
```

### 7.2 Secrets Management

```bash
# Nunca committar secrets!
# .gitignore
.env
.env.local
secrets/

# Usar Vault para produção
vault kv put secret/wms/db/prod \
  url=postgresql://user:pass@host/db \
  connection_timeout=30 \
  max_connections=50

# Aplicação fetcha em startup
config := loadSecretsFromVault()
```

### 7.3 Certificate Management

```bash
# Geração e rotação automática
# Usar Let's Encrypt com Cert Manager (Kubernetes)

apiVersion: cert-manager.io/v1
kind: Certificate
metadata:
  name: wms-tls
spec:
  secretName: wms-tls-cert
  issuerRef:
    name: letsencrypt-prod
  commonName: wms.example.com
  dnsNames:
  - wms.example.com
  - api.wms.example.com
```

---

## 8. Monitoramento de Segurança

### 8.1 Detecção de Anomalias

**Alertas Automáticos:**
- 5+ failed login attempts → Bloquear conta
- Acesso de múltiplos IPs em < 5 min → Flag suspeito
- Exportação grande de dados → Revisar
- Múltiplas deletações em < 1 hora → Alertar admin
- Taxa de erro > 10% → Investigar

### 8.2 Security Events Log

```
2024-01-15 10:30:00 | SECURITY | Failed login attempt | user@example.com | IP: 192.168.1.1
2024-01-15 10:31:00 | SECURITY | Account locked | user@example.com | Reason: 5 attempts
2024-01-15 10:32:00 | SECURITY | Permission escalation detected | user2@example.com | Attempted admin access
2024-01-15 10:33:00 | SECURITY | Unusual data export | user3@example.com | 10GB exported | IP: 10.0.0.5
```

### 8.3 Pentesting e Code Review

**Frequência:**
- Code review: Toda PR (2+ reviewers para segurança)
- Pentest: Trimestral
- Vulnerability scanning: Contínuo (SAST + DAST)
- Dependency check: Diário

---

**Documento Versão:** 1.0  
**Status:** Política de Segurança Estabelecida  
**Próximo Passo:** Implementação de controles
