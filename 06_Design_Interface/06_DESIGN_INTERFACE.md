# 📐 Padrões de Interface - WMS Enterprise

**Documento de referência para desenvolvimento de todas as telas, formulários, modais e dashboards do WMS-Interprise**

---

## 📋 Índice

1. [Visão Geral](#visão-geral)
2. [Padrões de Layout](#padrões-de-layout)
3. [Componentes Reutilizáveis](#componentes-reutilizáveis)
4. [Formulários](#formulários)
5. [Tabelas e Listas](#tabelas-e-listas)
6. [Dashboards e KPIs](#dashboards-e-kpis)
7. [Modais e Alertas](#modais-e-alertas)
8. [Padrões de Código Vue](#padrões-de-código-vue)
9. [Estado Global (Pinia)](#estado-global-pinia)
10. [Roteamento](#roteamento)
11. [Integração com API](#integração-com-api)
12. [Boas Práticas](#boas-práticas)

---

## 🎯 Visão Geral

O WMS-Interprise segue uma arquitetura de interface moderna baseada em:

- **React 18** com TypeScript
- **Material-UI (MUI)** para componentes
- **Zustand** para gerenciamento de estado
- **TanStack Query** para data fetching
- **Vite** como build tool
- **Axios** para requisições HTTP

### Princípios de Design

- **Clareza:** Interfaces limpas e intuitivas
- **Consistência:** Padrões visuais e de interação uniformes
- **Eficiência:** Workflows otimizados para operações logísticas
- **Responsividade:** Funcionamento em desktop, tablet e mobile
- **Acessibilidade:** Atender padrões WCAG 2.1

---

## 🏗️ Padrões de Layout

### Container Principal

```tsx
// Componentes envolvidos em container com max-width
import { Container, Box } from '@mui/material'

export default function MyPage() {
  return (
    <Container maxWidth="lg">
      <Box sx={{ py: 4 }}>
        {/* Conteúdo da página */}
      </Box>
    </Container>
  )
}
```

### Grid Responsivo

```tsx
import { Grid, Paper } from '@mui/material'

// Grid responsivo: 1 coluna mobile, 2 tablet, 4 desktop
export function GridLayout() {
  return (
    <Grid container spacing={3}>
      <Grid item xs={12} sm={6} md={3}>
        <Paper sx={{ p: 2 }}>Card 1</Paper>
      </Grid>
      <Grid item xs={12} sm={6} md={3}>
        <Paper sx={{ p: 2 }}>Card 2</Paper>
      </Grid>
      <Grid item xs={12} sm={6} md={3}>
        <Paper sx={{ p: 2 }}>Card 3</Paper>
      </Grid>
      <Grid item xs={12} sm={6} md={3}>
        <Paper sx={{ p: 2 }}>Card 4</Paper>
      </Grid>
    </Grid>
  )
}
```

### Flex com espaçamento

```tsx
import { Box, Button } from '@mui/material'

// Header com título e botão
export function HeaderLayout() {
  return (
    <Box sx={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center', mb: 3 }}>
      <h1 style={{ fontSize: '2.25rem', fontWeight: 'bold', margin: 0 }}>
        Título da Página
      </h1>
      <Button variant="contained" color="primary">
        Nova Ação
      </Button>
    </Box>
  )
}
```

### Card Padrão

```tsx
import { Paper, Box } from '@mui/material'

// Card com padding padrão
export function CardComponent() {
  return (
    <Paper sx={{ p: 3 }}>
      {/* Conteúdo do card */}
    </Paper>
  )
}
```

---

## 🧩 Componentes Reutilizáveis

### Button Variants

```tsx
import { Button, Stack } from '@mui/material'

export function ButtonExamples() {
  return (
    <Stack direction="row" spacing={2}>
      {/* Primary */}
      <Button variant="contained" color="primary">
        Salvar
      </Button>

      {/* Secondary */}
      <Button variant="outlined" color="primary">
        Cancelar
      </Button>

      {/* Danger */}
      <Button variant="contained" color="error">
        Excluir
      </Button>

      {/* Loading state */}
      <Button variant="contained" disabled>
        Processando...
      </Button>
    </Stack>
  )
}
```

### Status Badges

```tsx
import { Chip } from '@mui/material'
import CheckCircleIcon from '@mui/icons-material/CheckCircle'
import ErrorIcon from '@mui/icons-material/Error'
import HourglassTopIcon from '@mui/icons-material/HourglassTop'
import InfoIcon from '@mui/icons-material/Info'

export function StatusBadges() {
  return (
    <>
      {/* Ativo */}
      <Chip
        icon={<CheckCircleIcon />}
        label="Ativo"
        color="success"
        variant="outlined"
      />

      {/* Inativo */}
      <Chip
        icon={<ErrorIcon />}
        label="Inativo"
        color="error"
        variant="outlined"
      />

      {/* Pendente */}
      <Chip
        icon={<HourglassTopIcon />}
        label="Pendente"
        color="warning"
        variant="outlined"
      />

      {/* Info */}
      <Chip
        icon={<InfoIcon />}
        label="Informação"
        color="info"
        variant="outlined"
      />
    </>
  )
}
```

### Loading Skeleton

```tsx
import { Skeleton, Stack, Paper } from '@mui/material'

export function LoadingSkeleton() {
  return (
    <Stack spacing={2}>
      <Paper sx={{ p: 2 }}>
        <Skeleton variant="text" width="100%" height={40} />
        <Skeleton variant="rectangular" width="100%" height={60} sx={{ mt: 1 }} />
        <Skeleton variant="circular" width={40} height={40} sx={{ mt: 1 }} />
      </Paper>
    </Stack>
  )
}
```

### Alert Components

```tsx
import { Alert, AlertTitle } from '@mui/material'

export function AlertExamples() {
  return (
    <>
      {/* Success */}
      <Alert severity="success">
        <AlertTitle>Sucesso</AlertTitle>
        Operação realizada com sucesso!
      </Alert>

      {/* Error */}
      <Alert severity="error">
        <AlertTitle>Erro</AlertTitle>
        Ocorreu um erro ao processar a solicitação.
      </Alert>

      {/* Warning */}
      <Alert severity="warning">
        <AlertTitle>Aviso</AlertTitle>
        Esta ação não pode ser desfeita.
      </Alert>

      {/* Info */}
      <Alert severity="info">
        <AlertTitle>Informação</AlertTitle>
        Dados carregados com sucesso.
      </Alert>
    </>
  )
}
```

---

## 📝 Formulários

### Estrutura de Formulário Padrão

```tsx
import React, { useState } from 'react'
import { Container, Paper, Box, TextField, Button, Grid, CircularProgress } from '@mui/material'
import { useNavigate } from 'react-router-dom'

interface FormData {
  nome: string
  descricao: string
  codigoSKU: string
  categoria: string
  preco: number
  estoque: number
}

interface FormProps {
  id?: string
  isEdit?: boolean
}

export function ProdutoForm({ id, isEdit = false }: FormProps) {
  const navigate = useNavigate()
  const [loading, setLoading] = useState(false)
  const [errors, setErrors] = useState<Record<string, string>>({})
  const [form, setForm] = useState<FormData>({
    nome: '',
    descricao: '',
    codigoSKU: '',
    categoria: '',
    preco: 0,
    estoque: 0
  })

  const handleChange = (field: keyof FormData) => (
    event: React.ChangeEvent<HTMLInputElement | HTMLTextAreaElement>
  ) => {
    setForm({
      ...form,
      [field]: event.target.value
    })
    // Limpar erro do campo ao editar
    if (errors[field]) {
      setErrors({
        ...errors,
        [field]: ''
      })
    }
  }

  const validateForm = (): boolean => {
    const newErrors: Record<string, string> = {}

    if (!form.nome.trim()) {
      newErrors.nome = 'Nome é obrigatório'
    }
    if (!form.codigoSKU.trim()) {
      newErrors.codigoSKU = 'Código SKU é obrigatório'
    }
    if (!form.categoria) {
      newErrors.categoria = 'Categoria é obrigatória'
    }
    if (form.preco <= 0) {
      newErrors.preco = 'Preço deve ser maior que 0'
    }
    if (form.estoque < 0) {
      newErrors.estoque = 'Estoque não pode ser negativo'
    }

    setErrors(newErrors)
    return Object.keys(newErrors).length === 0
  }

  const handleSubmit = async (e: React.FormEvent<HTMLFormElement>) => {
    e.preventDefault()

    if (!validateForm()) {
      return
    }

    setLoading(true)
    try {
      if (isEdit && id) {
        // await productService.update(id, form)
        // toast.success('Produto atualizado com sucesso!')
      } else {
        // await productService.create(form)
        // toast.success('Produto criado com sucesso!')
      }
      navigate('/inventory')
    } catch (error: any) {
      // toast.error(error.response?.data?.message || 'Erro ao salvar')
      console.error('Erro ao salvar:', error)
    } finally {
      setLoading(false)
    }
  }

  return (
    <Container maxWidth="sm">
      <Box sx={{ py: 4 }}>
        <h1 style={{ fontSize: '2.25rem', fontWeight: 'bold', marginBottom: '2rem' }}>
          {isEdit ? 'Editar Produto' : 'Novo Produto'}
        </h1>

        <Paper sx={{ p: 3 }}>
          <form onSubmit={handleSubmit}>
            <Grid container spacing={3}>
              {/* Campo de largura completa */}
              <Grid item xs={12}>
                <TextField
                  fullWidth
                  label="Nome do Produto *"
                  placeholder="Digite o nome do produto"
                  value={form.nome}
                  onChange={handleChange('nome')}
                  error={!!errors.nome}
                  helperText={errors.nome}
                  required
                />
              </Grid>

              {/* Campo de largura completa */}
              <Grid item xs={12}>
                <TextField
                  fullWidth
                  label="Descrição"
                  placeholder="Descrição detalhada do produto"
                  value={form.descricao}
                  onChange={handleChange('descricao')}
                  multiline
                  rows={4}
                />
              </Grid>

              {/* Campo de meia largura */}
              <Grid item xs={12} sm={6}>
                <TextField
                  fullWidth
                  label="Código SKU *"
                  placeholder="SKU-000000"
                  value={form.codigoSKU}
                  onChange={handleChange('codigoSKU')}
                  error={!!errors.codigoSKU}
                  helperText={errors.codigoSKU}
                  required
                />
              </Grid>

              {/* Campo de meia largura */}
              <Grid item xs={12} sm={6}>
                <TextField
                  fullWidth
                  label="Categoria *"
                  placeholder="Selecione uma categoria"
                  value={form.categoria}
                  onChange={handleChange('categoria')}
                  error={!!errors.categoria}
                  helperText={errors.categoria}
                  select
                  required
                >
                  <option value="">Selecione</option>
                  <option value="eletronica">Eletrônica</option>
                  <option value="vestuario">Vestiário</option>
                  <option value="alimentos">Alimentos</option>
                </TextField>
              </Grid>

              {/* Campo de meia largura */}
              <Grid item xs={12} sm={6}>
                <TextField
                  fullWidth
                  label="Preço (R$) *"
                  type="number"
                  inputProps={{ step: '0.01', min: '0' }}
                  value={form.preco}
                  onChange={handleChange('preco')}
                  error={!!errors.preco}
                  helperText={errors.preco}
                  required
                />
              </Grid>

              {/* Campo de meia largura */}
              <Grid item xs={12} sm={6}>
                <TextField
                  fullWidth
                  label="Estoque *"
                  type="number"
                  inputProps={{ min: '0' }}
                  value={form.estoque}
                  onChange={handleChange('estoque')}
                  error={!!errors.estoque}
                  helperText={errors.estoque}
                  required
                />
              </Grid>
            </Grid>

            {/* Botões de ação */}
            <Box sx={{ display: 'flex', justifyContent: 'flex-end', gap: 2, mt: 4 }}>
              <Button
                variant="outlined"
                color="primary"
                onClick={() => navigate('/inventory')}
              >
                Cancelar
              </Button>
              <Button
                type="submit"
                variant="contained"
                color="primary"
                disabled={loading}
              >
                {loading ? <CircularProgress size={24} /> : isEdit ? 'Atualizar' : 'Salvar'}
              </Button>
            </Box>
          </form>
        </Paper>
      </Box>
    </Container>
  )
}
```

### Convenções de Formulário

1. **Título:**
   - Usar tag `h1` com `fontSize: '2.25rem'`, `fontWeight: 'bold'`
   - Texto dinâmico: `{{ isEdit ? 'Editar X' : 'Novo X' }}`

2. **Container do Formulário:**
   - Envolver em `<Paper sx={{ p: 3 }}>`
   - Usar `Container maxWidth="sm"` para limitar largura

3. **Grid de Campos:**
   - Usar `<Grid container spacing={3}>`
   - Campos completos: `xs={12}`
   - Campos de meia largura: `xs={12} sm={6}`

4. **Labels e Placeholders:**
   - Asterisco (*) para campos obrigatórios
   - Placeholder descritivo e curto
   - Use `helperText` para erros de validação

5. **Botões de Ação:**
   - Cancelar: `Button variant="outlined"`
   - Salvar/Atualizar: `Button variant="contained"`
   - Estado de loading: `:disabled={loading}`

---

## 📊 Tabelas e Listas

### Tabela Padrão

```tsx
import React, { useState } from 'react'
import {
  Paper,
  Table,
  TableBody,
  TableCell,
  TableContainer,
  TableHead,
  TableRow,
  TablePagination,
  Button,
  Stack,
  TextField,
  Box
} from '@mui/material'
import EditIcon from '@mui/icons-material/Edit'
import DeleteIcon from '@mui/icons-material/Delete'

interface Produto {
  id: string
  nome: string
  codigoSKU: string
  estoque: number
  preco: number
}

const mockProducts: Produto[] = [
  { id: '1', nome: 'Notebook', codigoSKU: 'SKU-001', estoque: 50, preco: 3000 },
  { id: '2', nome: 'Mouse', codigoSKU: 'SKU-002', estoque: 200, preco: 50 },
  { id: '3', nome: 'Teclado', codigoSKU: 'SKU-003', estoque: 150, preco: 150 }
]

export function ProdutosTable() {
  const [page, setPage] = useState(0)
  const [rowsPerPage, setRowsPerPage] = useState(10)
  const [search, setSearch] = useState('')

  const handleChangePage = (event: unknown, newPage: number) => {
    setPage(newPage)
  }

  const handleChangeRowsPerPage = (event: React.ChangeEvent<HTMLInputElement>) => {
    setRowsPerPage(parseInt(event.target.value, 10))
    setPage(0)
  }

  const filteredProducts = mockProducts.filter(
    product =>
      product.nome.toLowerCase().includes(search.toLowerCase()) ||
      product.codigoSKU.toLowerCase().includes(search.toLowerCase())
  )

  return (
    <>
      {/* Barra de busca */}
      <Box sx={{ mb: 3, display: 'flex', gap: 2, alignItems: 'center' }}>
        <TextField
          placeholder="Buscar por nome ou SKU..."
          value={search}
          onChange={(e) => setSearch(e.target.value)}
          size="small"
          sx={{ flex: 1 }}
        />
      </Box>

      {/* Tabela */}
      <TableContainer component={Paper}>
        <Table>
          <TableHead sx={{ backgroundColor: '#f5f5f5' }}>
            <TableRow>
              <TableCell sx={{ fontWeight: 'bold' }}>Nome</TableCell>
              <TableCell sx={{ fontWeight: 'bold' }}>Código SKU</TableCell>
              <TableCell align="right" sx={{ fontWeight: 'bold' }}>
                Estoque
              </TableCell>
              <TableCell align="right" sx={{ fontWeight: 'bold' }}>
                Preço
              </TableCell>
              <TableCell align="center" sx={{ fontWeight: 'bold' }}>
                Ações
              </TableCell>
            </TableRow>
          </TableHead>
          <TableBody>
            {filteredProducts
              .slice(page * rowsPerPage, page * rowsPerPage + rowsPerPage)
              .map((produto) => (
                <TableRow key={produto.id} hover>
                  <TableCell>{produto.nome}</TableCell>
                  <TableCell>{produto.codigoSKU}</TableCell>
                  <TableCell align="right">{produto.estoque} un.</TableCell>
                  <TableCell align="right">
                    R$ {produto.preco.toLocaleString('pt-BR', { minimumFractionDigits: 2 })}
                  </TableCell>
                  <TableCell align="center">
                    <Stack direction="row" spacing={1} justifyContent="center">
                      <Button
                        size="small"
                        variant="outlined"
                        startIcon={<EditIcon />}
                        onClick={() => console.log('Editar', produto.id)}
                      >
                        Editar
                      </Button>
                      <Button
                        size="small"
                        variant="outlined"
                        color="error"
                        startIcon={<DeleteIcon />}
                        onClick={() => console.log('Excluir', produto.id)}
                      >
                        Excluir
                      </Button>
                    </Stack>
                  </TableCell>
                </TableRow>
              ))}
          </TableBody>
        </Table>
      </TableContainer>

      {/* Paginação */}
      <TablePagination
        rowsPerPageOptions={[5, 10, 25]}
        component="div"
        count={filteredProducts.length}
        rowsPerPage={rowsPerPage}
        page={page}
        onPageChange={handleChangePage}
        onRowsPerPageChange={handleChangeRowsPerPage}
      />
    </>
  )
}
```

---

## 📈 Dashboards e KPIs

### Card KPI

```tsx
import { Paper, Box, Typography, Stack } from '@mui/material'
import TrendingUpIcon from '@mui/icons-material/TrendingUp'

interface KPICardProps {
  title: string
  value: string | number
  unit?: string
  trend?: number
  icon?: React.ReactNode
  color?: 'primary' | 'success' | 'warning' | 'error' | 'info'
}

export function KPICard({
  title,
  value,
  unit,
  trend,
  icon,
  color = 'primary'
}: KPICardProps) {
  return (
    <Paper sx={{ p: 3 }}>
      <Stack spacing={2}>
        <Box sx={{ display: 'flex', justifyContent: 'space-between', alignItems: 'start' }}>
          <Box>
            <Typography variant="subtitle2" color="textSecondary">
              {title}
            </Typography>
            <Typography variant="h4" sx={{ fontWeight: 'bold', mt: 1 }}>
              {value}
              {unit && <span style={{ fontSize: '0.6em', marginLeft: '4px' }}>{unit}</span>}
            </Typography>
          </Box>
          {icon && (
            <Box sx={{ fontSize: '2.5rem', color: `${color}.main` }}>
              {icon}
            </Box>
          )}
        </Box>

        {trend !== undefined && (
          <Box sx={{ display: 'flex', alignItems: 'center', gap: 0.5 }}>
            <TrendingUpIcon
              sx={{
                fontSize: '1rem',
                color: trend >= 0 ? 'success.main' : 'error.main'
              }}
            />
            <Typography
              variant="caption"
              sx={{
                color: trend >= 0 ? 'success.main' : 'error.main'
              }}
            >
              {trend >= 0 ? '+' : ''}{trend}% em relação ao mês anterior
            </Typography>
          </Box>
        )}
      </Stack>
    </Paper>
  )
}
```

### Dashboard de Exemplo

```tsx
import React from 'react'
import { Container, Box, Grid, Paper, Typography } from '@mui/material'
import StorageIcon from '@mui/icons-material/Storage'
import LocalShippingIcon from '@mui/icons-material/LocalShipping'
import CheckCircleIcon from '@mui/icons-material/CheckCircle'
import AlertIcon from '@mui/icons-material/Alert'
import { KPICard } from '@/components/KPICard'

export function DashboardPage() {
  return (
    <Container maxWidth="lg">
      <Box sx={{ py: 4 }}>
        {/* Header */}
        <Box sx={{ mb: 4 }}>
          <Typography variant="h4" sx={{ fontWeight: 'bold', mb: 1 }}>
            Dashboard
          </Typography>
          <Typography variant="body2" color="textSecondary">
            Visão geral das operações do armazém
          </Typography>
        </Box>

        {/* KPIs */}
        <Grid container spacing={3} sx={{ mb: 4 }}>
          <Grid item xs={12} sm={6} md={3}>
            <KPICard
              title="Itens em Estoque"
              value="15,480"
              unit="un."
              trend={5}
              icon={<StorageIcon />}
              color="primary"
            />
          </Grid>
          <Grid item xs={12} sm={6} md={3}>
            <KPICard
              title="Pedidos Pendentes"
              value="32"
              trend={-2}
              icon={<LocalShippingIcon />}
              color="warning"
            />
          </Grid>
          <Grid item xs={12} sm={6} md={3}>
            <KPICard
              title="Pedidos Concluídos"
              value="287"
              trend={8}
              icon={<CheckCircleIcon />}
              color="success"
            />
          </Grid>
          <Grid item xs={12} sm={6} md={3}>
            <KPICard
              title="Anomalias"
              value="5"
              trend={-1}
              icon={<AlertIcon />}
              color="error"
            />
          </Grid>
        </Grid>

        {/* Conteúdo adicional */}
        <Grid container spacing={3}>
          <Grid item xs={12} md={8}>
            <Paper sx={{ p: 3 }}>
              <Typography variant="h6" sx={{ fontWeight: 'bold', mb: 2 }}>
                Movimentações Recentes
              </Typography>
              {/* Gráfico ou lista */}
            </Paper>
          </Grid>
          <Grid item xs={12} md={4}>
            <Paper sx={{ p: 3 }}>
              <Typography variant="h6" sx={{ fontWeight: 'bold', mb: 2 }}>
                Alertas
              </Typography>
              {/* Lista de alertas */}
            </Paper>
          </Grid>
        </Grid>
      </Box>
    </Container>
  )
}
```

---

## 🔔 Modais e Alertas

### Modal de Confirmação

```tsx
import React from 'react'
import {
  Dialog,
  DialogTitle,
  DialogContent,
  DialogContentText,
  DialogActions,
  Button
} from '@mui/material'

interface ConfirmDialogProps {
  open: boolean
  title: string
  message: string
  confirmText?: string
  cancelText?: string
  onConfirm: () => void
  onCancel: () => void
  loading?: boolean
  severity?: 'error' | 'warning' | 'info'
}

export function ConfirmDialog({
  open,
  title,
  message,
  confirmText = 'Confirmar',
  cancelText = 'Cancelar',
  onConfirm,
  onCancel,
  loading = false,
  severity = 'warning'
}: ConfirmDialogProps) {
  return (
    <Dialog open={open} onClose={onCancel}>
      <DialogTitle>{title}</DialogTitle>
      <DialogContent>
        <DialogContentText>{message}</DialogContentText>
      </DialogContent>
      <DialogActions>
        <Button onClick={onCancel} disabled={loading}>
          {cancelText}
        </Button>
        <Button
          onClick={onConfirm}
          disabled={loading}
          color={severity}
          variant="contained"
        >
          {confirmText}
        </Button>
      </DialogActions>
    </Dialog>
  )
}
```

### Toast Notifications

```tsx
import { toast } from 'react-toastify'

// Sucesso
toast.success('Operação realizada com sucesso!')

// Erro
toast.error('Erro ao processar a solicitação')

// Aviso
toast.warning('Esta ação não pode ser desfeita')

// Info
toast.info('Dados carregados com sucesso')
```

---

## 💻 Padrões de Código Vue/React

### Estrutura de Componente React

```tsx
// Imports externos
import React, { useState, useEffect } from 'react'
import { useNavigate } from 'react-router-dom'

// Imports de bibliotecas de UI
import { Container, Box, Button } from '@mui/material'

// Imports de hooks customizados
import { useProductStore } from '@/hooks/useProductStore'

// Imports de types
import type { Product } from '@/types'

// Imports de services
import { productService } from '@/services/product.service'

// Imports de componentes
import { ProductForm } from '@/components/ProductForm'

interface ProductPageProps {
  id?: string
}

export function ProductPage({ id }: ProductPageProps) {
  // Hooks do React
  const navigate = useNavigate()

  // Stores
  const { products, setProducts } = useProductStore()

  // State
  const [loading, setLoading] = useState(false)
  const [product, setProduct] = useState<Product | null>(null)

  // Effects
  useEffect(() => {
    if (id) {
      loadProduct()
    }
  }, [id])

  // Methods
  async function loadProduct() {
    try {
      setLoading(true)
      const data = await productService.getById(id!)
      setProduct(data)
    } catch (error) {
      console.error('Erro ao carregar produto:', error)
    } finally {
      setLoading(false)
    }
  }

  // Render
  if (loading) {
    return <div>Carregando...</div>
  }

  return (
    <Container maxWidth="sm">
      <Box sx={{ py: 4 }}>
        <ProductForm product={product} />
      </Box>
    </Container>
  )
}

export default ProductPage
```

### Custom Hooks

```tsx
// hooks/useFormValidation.ts
import { useState, useCallback } from 'react'

interface ValidationErrors {
  [key: string]: string
}

export function useFormValidation<T extends Record<string, any>>(
  initialValues: T,
  onSubmit: (values: T) => Promise<void>
) {
  const [values, setValues] = useState<T>(initialValues)
  const [errors, setErrors] = useState<ValidationErrors>({})
  const [loading, setLoading] = useState(false)

  const handleChange = useCallback(
    (field: keyof T) => (event: React.ChangeEvent<HTMLInputElement>) => {
      setValues({
        ...values,
        [field]: event.target.value
      })
      // Limpar erro ao editar
      if (errors[field as string]) {
        setErrors({
          ...errors,
          [field as string]: ''
        })
      }
    },
    [values, errors]
  )

  const handleSubmit = useCallback(
    async (e: React.FormEvent<HTMLFormElement>) => {
      e.preventDefault()
      setLoading(true)
      try {
        await onSubmit(values)
      } catch (error) {
        console.error('Erro ao submeter formulário:', error)
      } finally {
        setLoading(false)
      }
    },
    [values, onSubmit]
  )

  return {
    values,
    errors,
    loading,
    handleChange,
    handleSubmit,
    setValues,
    setErrors
  }
}
```

---

## 🏪 Estado Global (Zustand)

### Estrutura de Store

```tsx
// stores/productStore.ts
import { create } from 'zustand'
import type { Product } from '@/types'

interface ProductStore {
  products: Product[]
  loading: boolean
  error: string | null
  // Actions
  setProducts: (products: Product[]) => void
  addProduct: (product: Product) => void
  updateProduct: (id: string, product: Partial<Product>) => void
  removeProduct: (id: string) => void
  setLoading: (loading: boolean) => void
  setError: (error: string | null) => void
}

export const useProductStore = create<ProductStore>((set) => ({
  products: [],
  loading: false,
  error: null,

  setProducts: (products) => set({ products }),
  addProduct: (product) =>
    set((state) => ({
      products: [...state.products, product]
    })),
  updateProduct: (id, updatedProduct) =>
    set((state) => ({
      products: state.products.map((p) =>
        p.id === id ? { ...p, ...updatedProduct } : p
      )
    })),
  removeProduct: (id) =>
    set((state) => ({
      products: state.products.filter((p) => p.id !== id)
    })),
  setLoading: (loading) => set({ loading }),
  setError: (error) => set({ error })
}))
```

---

## 🛣️ Roteamento

### Estrutura de Rotas

```tsx
// router/index.tsx
import React from 'react'
import { BrowserRouter as Router, Routes, Route, Navigate } from 'react-router-dom'

// Layouts
import MainLayout from '@/components/layout/MainLayout'

// Pages
import LoginPage from '@/pages/auth/LoginPage'
import DashboardPage from '@/pages/DashboardPage'
import InventoryPage from '@/pages/inventory/InventoryPage'
import InventoryFormPage from '@/pages/inventory/InventoryFormPage'
import ReceivingPage from '@/pages/receiving/ReceivingPage'
import PickingPage from '@/pages/picking/PickingPage'
import PackingPage from '@/pages/packing/PackingPage'
import ShippingPage from '@/pages/shipping/ShippingPage'

// Protected Route Wrapper
function ProtectedRoute({ element }: { element: React.ReactNode }) {
  const isAuthenticated = !!localStorage.getItem('token')
  return isAuthenticated ? element : <Navigate to="/login" replace />
}

export function AppRouter() {
  return (
    <Router>
      <Routes>
        {/* Public Routes */}
        <Route path="/login" element={<LoginPage />} />

        {/* Protected Routes */}
        <Route element={<MainLayout />}>
          <Route path="/" element={<ProtectedRoute element={<DashboardPage />} />} />
          <Route path="/inventory" element={<ProtectedRoute element={<InventoryPage />} />} />
          <Route path="/inventory/new" element={<ProtectedRoute element={<InventoryFormPage />} />} />
          <Route path="/inventory/:id" element={<ProtectedRoute element={<InventoryFormPage />} />} />
          <Route path="/receiving" element={<ProtectedRoute element={<ReceivingPage />} />} />
          <Route path="/picking" element={<ProtectedRoute element={<PickingPage />} />} />
          <Route path="/packing" element={<ProtectedRoute element={<PackingPage />} />} />
          <Route path="/shipping" element={<ProtectedRoute element={<ShippingPage />} />} />
        </Route>

        {/* 404 */}
        <Route path="*" element={<Navigate to="/" replace />} />
      </Routes>
    </Router>
  )
}
```

---

## 🌐 Integração com API

### Configuração Axios

```tsx
// services/api.ts
import axios, { AxiosError, AxiosInstance } from 'axios'
import { useAuthStore } from '@/stores/authStore'
import { toast } from 'react-toastify'

const api: AxiosInstance = axios.create({
  baseURL: import.meta.env.VITE_API_URL || 'http://localhost:8090/api/v1',
  headers: {
    'Content-Type': 'application/json'
  }
})

// Request interceptor
api.interceptors.request.use(
  (config) => {
    const token = localStorage.getItem('token')
    if (token) {
      config.headers.Authorization = `Bearer ${token}`
    }
    return config
  },
  (error) => Promise.reject(error)
)

// Response interceptor
api.interceptors.response.use(
  (response) => response,
  async (error: AxiosError) => {
    if (error.response?.status === 401) {
      const authStore = useAuthStore()
      authStore.setToken(null)
      localStorage.removeItem('token')
      window.location.href = '/login'
    }

    const message = (error.response?.data as any)?.message || 'Erro ao processar requisição'
    toast.error(message)

    return Promise.reject(error)
  }
)

export default api
```

### Padrão de Service

```tsx
// services/productService.ts
import api from './api'
import type { Product, PaginatedResponse, ApiResponse } from '@/types'

export interface ProductFilters {
  search?: string
  category?: string
  page?: number
  limit?: number
}

export const productService = {
  async list(filters: ProductFilters = {}): Promise<PaginatedResponse<Product>> {
    const { data } = await api.get<ApiResponse<PaginatedResponse<Product>>>('/inventory', {
      params: filters
    })
    return data.data
  },

  async getById(id: string): Promise<Product> {
    const { data } = await api.get<ApiResponse<Product>>(`/inventory/${id}`)
    return data.data
  },

  async create(product: Partial<Product>): Promise<Product> {
    const { data } = await api.post<ApiResponse<Product>>('/inventory', product)
    return data.data
  },

  async update(id: string, product: Partial<Product>): Promise<Product> {
    const { data } = await api.put<ApiResponse<Product>>(`/inventory/${id}`, product)
    return data.data
  },

  async delete(id: string): Promise<void> {
    await api.delete(`/inventory/${id}`)
  }
}
```

---

## ✅ Boas Práticas

### TypeScript

1. **Sempre tipar props e retornos de funções**
```tsx
interface ComponentProps {
  userId: string
  showDetails?: boolean
  onClose: () => void
}

export function MyComponent({ userId, showDetails = false, onClose }: ComponentProps) {
  // ...
}
```

2. **Usar types para responses da API**
```tsx
interface ApiResponse<T> {
  success: boolean
  data: T
  message?: string
  timestamp: string
}

interface PaginatedResponse<T> {
  items: T[]
  total: number
  page: number
  limit: number
}
```

3. **Evitar `any`** - Usar `unknown` se necessário
```tsx
// ❌ Evitar
const response: any = await fetch(url)

// ✅ Preferir
const response: unknown = await fetch(url)
```

### Performance

1. **Lazy loading de rotas**
```tsx
const InventoryPage = React.lazy(() => import('@/pages/inventory/InventoryPage'))

<Suspense fallback={<LoadingSkeleton />}>
  <Routes>
    <Route path="/inventory" element={<InventoryPage />} />
  </Routes>
</Suspense>
```

2. **Memoização de componentes**
```tsx
import { memo } from 'react'

export const ProductCard = memo(function ProductCard({ product }: ProductCardProps) {
  return (
    // Componente
  )
})
```

3. **useCallback para funções em listas**
```tsx
const handleEdit = useCallback(
  (id: string) => {
    navigate(`/products/${id}/edit`)
  },
  [navigate]
)
```

### Acessibilidade

1. **Labels em inputs**
```tsx
<label htmlFor="product-name">Nome do Produto</label>
<TextField id="product-name" />
```

2. **Alt em imagens**
```tsx
<img src={productImage} alt={`Foto do produto ${productName}`} />
```

3. **ARIA attributes quando necessário**
```tsx
<div role="alert" aria-live="polite">
  Erro ao processar
</div>
```

### Segurança

1. **Sanitizar HTML** - Evitar `dangerouslySetInnerHTML`
2. **Validar dados** antes de enviar para API
3. **HTTPS** em produção
4. **Tokens** em memória quando possível

---

## 📱 Responsividade

### Breakpoints MUI

```
xs: 0px       (mobile)
sm: 600px     (tablet pequeno)
md: 960px     (tablet)
lg: 1280px    (desktop)
xl: 1920px    (desktop grande)
```

### Padrão Mobile-First

```tsx
// 1 coluna mobile, 2 colunas tablet, 4 colunas desktop
<Grid container spacing={3}>
  <Grid item xs={12} sm={6} md={3}>
    {/* Card */}
  </Grid>
</Grid>
```

```tsx
// Texto responsivo
<Typography
  variant="h4"
  sx={{
    fontSize: { xs: '1.5rem', sm: '2rem', md: '2.5rem' }
  }}
>
  Título
</Typography>
```

---

## 🎯 Checklist de Desenvolvimento

Ao criar uma nova feature, verificar:

- [ ] Componente usa TypeScript com tipos adequados
- [ ] Props estão devidamente tipadas
- [ ] Material-UI segue os padrões definidos
- [ ] Responsividade implementada (mobile-first)
- [ ] Loading states implementados
- [ ] Error handling implementado
- [ ] Validação de formulários (se aplicável)
- [ ] Acessibilidade (labels, alt, roles)
- [ ] Toast notifications para feedback
- [ ] Lazy loading de rotas
- [ ] Código limpo e comentado
- [ ] Sem console.log em produção
- [ ] Testes unitários (se aplicável)

---

## 📚 Recursos

- [Material-UI Documentation](https://mui.com/)
- [React Documentation](https://react.dev/)
- [TypeScript Documentation](https://www.typescriptlang.org/)
- [React Router Documentation](https://reactrouter.com/)
- [Zustand Documentation](https://github.com/pmndrs/zustand)
- [TanStack Query Documentation](https://tanstack.com/query/latest)
- [Axios Documentation](https://axios-http.com/)
- [React Toastify Documentation](https://fkhadra.github.io/react-toastify/)

---

## 📝 Notas Importantes

### Estrutura de Pastas Recomendada

```
frontend/src/
├── components/
│   ├── common/
│   ├── layout/
│   ├── forms/
│   └── inventory/
├── pages/
│   ├── auth/
│   ├── inventory/
│   ├── receiving/
│   └── ...
├── services/
│   ├── api.ts
│   ├── productService.ts
│   └── ...
├── stores/
│   ├── authStore.ts
│   ├── productStore.ts
│   └── ...
├── hooks/
│   ├── useFormValidation.ts
│   └── ...
├── types/
│   ├── index.ts
│   └── ...
├── router/
│   └── index.tsx
├── App.tsx
└── main.tsx
```

### Padrão de Nomenclatura

- **Componentes**: PascalCase (`ProductCard.tsx`)
- **Pages**: PascalCase com sufixo Page (`InventoryPage.tsx`)
- **Hooks**: camelCase com prefixo `use` (`useFormValidation.ts`)
- **Services**: camelCase com sufixo Service (`productService.ts`)
- **Stores**: camelCase com sufixo Store (`productStore.ts`)
- **Types**: PascalCase (`Product.ts`)
- **Props interfaces**: PascalCase com sufixo Props (`ProductCardProps`)

---

**Última atualização:** 16 de novembro de 2025
**Versão do documento:** 1.0.0
**Mantido por:** Equipe WMS-Interprise
