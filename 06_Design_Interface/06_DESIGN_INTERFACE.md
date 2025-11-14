# DESIGN DE INTERFACE E UX - WMS ENTERPRISE

## 1. Princípios de Design

### 1.1 Filosofia de Design

O WMS Enterprise segue os princípios de **Don Norman** para bom design:

1. **Visibilidade:** O estado do sistema é sempre visível
2. **Feedback:** Resposta rápida e clara às ações
3. **Restrições:** Prevenir erros, guiar usuário
4. **Consistência:** Padrões visuais e interação
5. **Prevenção de Erros:** Melhor que mensagens de erro
6. **Reconhecimento:** Minimize carga de memória
7. **Flexibilidade:** Atalhos para usuários avançados
8. **Estética:** Design limpo e profissional
9. **Diálogos:** Linguagem simples e direta
10. **Documentação:** Help contextual e acessível

### 1.2 Design System

#### Cores Corporativas

```
Primary:     #1976D2 (Azul - Confiança, Profissionalismo)
Secondary:   #388E3C (Verde - Sucesso, Positivo)
Success:     #4CAF50 (Verde claro)
Warning:     #FF9800 (Laranja - Atenção)
Error:       #F44336 (Vermelho - Crítico)
Info:        #2196F3 (Azul claro - Informação)

Neutral 50:  #F5F5F5 (Background)
Neutral 100: #EEEEEE (Surface)
Neutral 200: #E0E0E0 (Borders)
Neutral 700: #424242 (Text Secondary)
Neutral 900: #212121 (Text Primary)
```

#### Tipografia

```
Font Family: Inter / Segoe UI (sans-serif)

Headings:
  H1: 32px / 1.2   / 700 / Letter-spacing -0.5px
  H2: 24px / 1.3   / 700 / Letter-spacing -0.25px
  H3: 20px / 1.4   / 600 / Letter-spacing 0
  H4: 16px / 1.5   / 600

Body:
  Body1: 16px / 1.5 / 400 / Letter-spacing 0.15px
  Body2: 14px / 1.6 / 400 / Letter-spacing 0.25px
  Caption: 12px / 1.4 / 400 / Letter-spacing 0.4px

Code:
  Font: IBM Plex Mono
  Size: 13px / 1.5 / 400
```

#### Espaçamento

```
xs:  4px
sm:  8px
md: 16px
lg: 24px
xl: 32px
2xl:48px
```

#### Componentes Base

- **Buttons:** 4 variantes (Contained, Outlined, Text, Elevated)
- **Input Fields:** Text, Select, Checkbox, Radio, Toggle
- **Cards:** Elevated, Outlined
- **Modals/Dialogs:** Com footer de ações
- **Alerts/Toasts:** Para feedback
- **Pagination:** Cursor-based para listas grandes
- **Data Tables:** Com sorting, filtering, selection
- **Navigation:** Top nav + Sidebar

---

## 2. Arquitetura de Informação

### 2.1 Mapa de Navegação

```
┌─────────────────────────────────────────────────────────────┐
│                   WMS ENTERPRISE                             │
│                                                              │
│  ┌────────────────────────────────────────────────────────┐ │
│  │ Sidebar                    │ Main Content Area         │ │
│  ├────────────────────────────┼────────────────────────────┤ │
│  │ ○ Dashboard                │ [Main Content]            │ │
│  │ ├ Recebimento             │ [Breadcrumb]             │ │
│  │ │ ├ ASN                    │ [Title]                  │ │
│  │ │ ├ Em Recebimento         │ [Content]                │ │
│  │ │ └ Histórico              │                          │ │
│  │ ├ Armazenagem             │                          │ │
│  │ │ ├ Localização            │                          │ │
│  │ │ ├ Inventário             │                          │ │
│  │ │ └ Contagem               │                          │ │
│  │ ├ Separação               │                          │ │
│  │ │ ├ Picking                │                          │ │
│  │ │ ├ Consolidação           │                          │ │
│  │ │ └ Qualidade              │                          │ │
│  │ ├ Expedição               │                          │ │
│  │ │ ├ Remessas               │                          │ │
│  │ │ ├ Rastreamento           │                          │ │
│  │ │ └ Devoluções             │                          │ │
│  │ ├ Relatórios              │                          │ │
│  │ ├ Configuração            │                          │ │
│  │ └ Sair                    │                          │ │
│  │                            │                          │ │
│  └────────────────────────────┴────────────────────────────┘ │
│  [Status Bar com alertas]                                    │
└─────────────────────────────────────────────────────────────┘
```

### 2.2 User Flows

#### Flow 1: Operador Recebendo Mercadoria

```
START
  ↓
[Tela Recebimento]
  - Listar ASNs programadas
  - Selecionar ASN
  ↓
[Detalhes ASN]
  - Ver informações
  - Iniciar recebimento
  ↓
[Scanner/Digite NF]
  - Ler código ou digitar
  ↓
[Conferência]
  - Validar quantidade
  - Foto de danos?
  ↓
[Alocação]
  - Sugestão automática
  - Confirmar localização
  ↓
[Confirmação]
  - Resumo da operação
  - Enviar para inventário
  ↓
END
```

#### Flow 2: Operador Fazendo Picking

```
START
  ↓
[Dashboard Picking]
  - Ver picking orders atribuídas
  ↓
[Selecionar Picking]
  - Abrir picking order
  ↓
[Rota Otimizada]
  - Ver sequência de localizações
  - Iniciar
  ↓
[Coleta de Itens]
  LOOP por linha:
    - Navegar até localização (mapa)
    - Ler código do produto
    - Inserir quantidade
    - Foto (opcional)
    - Prosseguir próxima linha
  ↓
[Consolidação]
  - Mover para staging
  ↓
[Confirmação]
  - Enviar para packing
  ↓
END
```

---

## 3. Wireframes e Mockups

### 3.1 Dashboard Principal

```
╔════════════════════════════════════════════════════════════════╗
║              WMS Dashboard - Quinta-feira, 15 jan 2025         ║
╠════════════════════════════════════════════════════════════════╣
║                                                                ║
║  ┌─────────────────────────────────────────────────────────┐  ║
║  │ KPI's Operacionais (Real-time)                          │  ║
║  ├─────────────────────────────────────────────────────────┤  ║
║  │                                                         │  ║
║  │  Pedidos Processados  │  Picking Eficiência │  Erros   │  ║
║  │       1.234           │       94.2%         │    8     │  ║
║  │  +2.3% vs ontem       │  +1.1% vs semana    │ -3 vs semana
║  │                                                         │  ║
║  └─────────────────────────────────────────────────────────┘  ║
║                                                                ║
║  ┌─────────────────────┐  ┌──────────────────────┐             ║
║  │ Alertas Críticos    │  │ Operações em Aberto  │             ║
║  ├─────────────────────┤  ├──────────────────────┤             ║
║  │ ⚠ Estoque baixo:    │  │ ℹ 25 ASNs esperadas  │             ║
║  │   SKU-001 (< 10)    │  │ ℹ 4 horas descarrego │             ║
║  │                     │  │ ℹ 145 pick orders    │             ║
║  │ ⚠ Produto vencido   │  │ ℹ 32 remessas saindo │             ║
║  │   LOT-2024-001      │  │                      │             ║
║  │                     │  └──────────────────────┘             ║
║  └─────────────────────┘                                       ║
║                                                                ║
║  ┌─────────────────────────────────────────────────────────┐  ║
║  │ Gráfico: Performance Últimas 24 horas                   │  ║
║  │ [Gráfico de linhas mostrando throughput]                 │  ║
║  └─────────────────────────────────────────────────────────┘  ║
║                                                                ║
╚════════════════════════════════════════════════════════════════╝
```

### 3.2 Tela de Picking para Tablet/Mobile

```
┌──────────────────────────────────────────┐
│ ◀ Picking ID: PICK-001      [Menu]       │  ← Header
├──────────────────────────────────────────┤
│                                          │
│  Pedido: ORD-12345                       │  ← Info do Pedido
│  Cliente: Acme Corp                      │
│  Linhas: 5 / Completo: 2/5               │
│                                          │
├──────────────────────────────────────────┤
│  Local Atual: C-3-2-A  [📍 Próximo: C]   │  ← Localização
│  Distância: 45m                          │
├──────────────────────────────────────────┤
│                                          │
│  ┌──────────────────────────────────┐    │
│  │ ⬜ SKU-00123 - Widget Azul     │    │  ← Item atual
│  │   Qtd: 25 unidades              │    │
│  │   Localização: C-3-2-A           │    │
│  │   [📸 Foto]  [🔊 Voz]            │    │
│  │                                  │    │
│  │   Quantidade Coletada: [25]      │    │  ← Input
│  │   [Menos]  [  25  ]  [Mais]      │    │
│  │                                  │    │
│  │   [✓ Confirmar] [✗ Cancelar]     │    │
│  └──────────────────────────────────┘    │
│                                          │
│  Próximas Linhas:                        │  ← Preview próximas
│  □ B-1-1-C - SKU-00456 (10 un)          │
│  □ B-2-3-A - SKU-00789 (15 un)          │
│                                          │
├──────────────────────────────────────────┤
│  ℹ Última atualização: 14:32:15          │
│  [⚡ Conexão OK]  [🔋 Bateria 87%]       │
└──────────────────────────────────────────┘
```

### 3.3 Tela de Listagem de Pedidos (Desktop)

```
┌─────────────────────────────────────────────────────────────┐
│  Pedidos                                                    │
├────────────┬─────────────────────────────────────────────────┤
│ Filtros    │ Pesquisar: _____________ [Pesquisar]           │
│ ┌────────┐ │ Filtros: Status [ ▼ ] Warehouse [ ▼ ]         │
│ │Status  │ │                                                 │
│ │  ☑ NEW │ │ [Exportar CSV] [Impressão]                     │
│ │  ☑ OPEN│ │                                                 │
│ │  ☐ SHIP│ │ Mostrando 1-50 de 1.234 resultados            │
│ │        │ │                                                 │
│ └────────┘ │  ┌────────────────────────────────────────────┐ │
│            │  │Order  │Date│Customer │Lines│Status │Action│ │
│            │  ├────────────────────────────────────────────┤ │
│ [Aplicar]  │  │ORD-1 │15j │Acme    │5   │🟢 NEW │[>]   │ │
│ [Limpar]   │  │ORD-2 │15j │Beta    │3   │🟡 OPN │[>]   │ │
│            │  │ORD-3 │15j │Gamma   │10  │🟠 PKG │[>]   │ │
│            │  │...   │... │...     │... │...   │...   │ │
│            │  └────────────────────────────────────────────┘ │
│            │                                                 │
│            │  ← Paginação → Página 1 de 25   [< 1 2 3 >]   │
│            │                                                 │
└────────────┴─────────────────────────────────────────────────┘
```

---

## 4. Componentes Reutilizáveis

### 4.1 Status Badge

```react
<StatusBadge 
  status="IN_PROGRESS" 
  variant="filled"
  size="small"
/>

// Renders:
// 🟡 Em Andamento (amarelo)
// 🟢 Concluído (verde)
// 🔴 Erro (vermelho)
```

### 4.2 Action Button

```react
<ActionButton
  action="PICK"
  count={234}
  isLoading={false}
  onClick={handlePick}
/>

// Renders:
// [PICKING] 234 itens
```

### 4.3 Data Table com Toolbar

```react
<DataTable
  columns={columns}
  data={orders}
  isLoading={loading}
  pagination={{
    pageSize: 50,
    total: 1234
  }}
  toolbar={{
    search: true,
    filter: true,
    export: true
  }}
  onRowClick={(row) => navigate(`/orders/${row.id}`)}
/>
```

---

## 5. Experiência em Diferentes Dispositivos

### 5.1 Desktop (1920x1080 e acima)

- Layout com Sidebar + Main Content
- Tabelas com múltiplas colunas visíveis
- Gráficos interativos grandes
- Múltiplas janelas abertas

### 5.2 Tablet (768-1024px)

- Sidebar colapsável
- Tabelas com scroll horizontal
- Toque otimizado (buttons maiores)
- Modal para ações

### 5.3 Mobile (até 768px)

- Full-width single column
- Accordion para agrupamento
- Botões grandes (48px min)
- Modals para formulários
- Suporte a orientação portrait/landscape

---

## 6. Acessibilidade (WCAG 2.1 AA)

### 6.1 Requisitos

- **Contraste:** Mínimo 4.5:1 para texto
- **Fonts:** Mínimo 14px
- **Focus:** Bem visível (outline ou highlight)
- **Labels:** Todos inputs têm labels
- **Teclado:** Navegação completa sem mouse
- **Screen Readers:** Hierarquia de headings, alt text

### 6.2 Exemplo de Markup Acessível

```html
<!-- ❌ Ruim -->
<div onclick="pickItem()">Picker este item</div>

<!-- ✅ Bom -->
<button
  aria-label="Coletar item SKU-001"
  onClick={pickItem}
  tabIndex={0}
>
  Coletar
</button>

<!-- ✅ Para inputs -->
<div className="form-group">
  <label htmlFor="sku-input">Código do Produto:</label>
  <input
    id="sku-input"
    type="text"
    placeholder="Ex: SKU-001"
    aria-describedby="sku-help"
    required
  />
  <span id="sku-help" className="helper-text">
    Digite o código de barras do produto
  </span>
</div>
```

---

## 7. Padrões de Interação

### 7.1 Carregamento

```
Fase 1: [Skeleton Screen] - 100ms
  └→ Fase 2: [Dados Começam] - 200-500ms
    └→ Fase 3: [Conteúdo Completo] - 500ms-2s
```

### 7.2 Feedback de Ação

```
Usuario clica → Botão desabilita (visual feedback)
           ↓
       [Enviando...]
           ↓
    Sucesso/Erro aparece
           ↓
    Toast notification desaparece após 3s
```

### 7.3 Confirmação Destrutiva

```
Usuario clica "Deletar"
           ↓
Modal: "Tem certeza?"
       [Cancelar] [Deletar]
           ↓
Se confirmar: ação executada
```

---

## 8. Onboarding e Treinamento

### 8.1 First Time User Experience (FTUE)

1. **Bem-vindo:** Explicação do sistema
2. **Tour Guiado:** Principais funcionalidades
3. **Tarefas Simuladas:** Praticar com dados fake
4. **Certificação:** Quiz de conhecimento

### 8.2 Tooltips Contextuais

- Aparecem automaticamente para novos usuários
- Podem ser desabilitados
- Conteúdo breve (max 100 caracteres)

### 8.3 Help & Documentation

- **Widget de Help:** "?" no canto inferior direito
- **Chat de Suporte:** Integrado ao sistema
- **Base de Conhecimento:** Artigos internos
- **Hotkeys:** Atalhos por teclado

---

## 9. Temas e Personalização

### 9.1 Dark Mode

```css
/* Light Mode (default) */
--bg-primary: #FFFFFF;
--bg-secondary: #F5F5F5;
--text-primary: #212121;
--text-secondary: #757575;

/* Dark Mode */
@media (prefers-color-scheme: dark) {
  --bg-primary: #121212;
  --bg-secondary: #1E1E1E;
  --text-primary: #FFFFFF;
  --text-secondary: #BDBDBD;
}
```

### 9.2 Personalização por Role

- Operadores veem apenas Picking
- Supervisores veem Dashboard + Analytics
- Gerentes veem tudo + Admin
- Configurável por role

---

**Documento Versão:** 1.0  
**Status:** Design System Definido  
**Próximos Passos:** Prototipar em Figma, usuário testes
