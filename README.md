# 📊 Dashboard Performance Salão - Evolução dos Lucros

Um projeto de **análise de performance em tempo real** que combina a potência do **MySQL**, lógica avançada em **SQL** e visualizações inteligentes em **Power BI**.

---

## 🎯 Diferencial

Este dashboard vai além de simples gráficos. Ele oferece uma **segmentação temporal inteligente** dos lucros com categorização automática de clientes, proporcionalizando cada transação no contexto geral do negócio.

### Visual Principal: "Evolução dos Lucros"

O gráfico de barras que você vê apresenta uma hierarquia temporal sofisticada:

- **Hoje** → Último dia completo
- **Ontem** → Dia anterior
- **Semana Atual** → De segunda-feira até hoje
- **Mês Atual** → Do primeiro dia do mês até hoje
- **Semana Passada** → Segunda a domingo da semana anterior
- **Mês Anterior** → Mês completo anterior
- **2 Meses Atrás** → Mês anterior ao anterior
- **3 Meses Atrás** → Três meses retroativos
- **Histórico Geral** → Todos os dados disponíveis

Isso permite análises comparativas naturais sem necessidade de filtros complexos.
```sql
CASE 
        WHEN v.Data = CURDATE() THEN 'Hoje'
        WHEN v.Data = DATE_SUB(CURDATE(), INTERVAL 1 DAY) THEN 'Ontem'
        WHEN v.Data >= DATE_SUB(CURDATE(), INTERVAL WEEKDAY(CURDATE()) DAY) THEN 'Semana Atual'
        WHEN v.Data >= DATE_FORMAT(CURDATE(), '%Y-%m-01') THEN 'Mês Atual'
        WHEN v.Data BETWEEN DATE_SUB(CURDATE(), INTERVAL (WEEKDAY(CURDATE()) + 7) DAY) 
             AND DATE_SUB(CURDATE(), INTERVAL (WEEKDAY(CURDATE()) + 1) DAY) THEN 'Semana Passada'
        WHEN v.Data BETWEEN DATE_FORMAT(DATE_SUB(CURDATE(), INTERVAL 1 MONTH), '%Y-%m-01') 
             AND LAST_DAY(DATE_SUB(CURDATE(), INTERVAL 1 MONTH)) THEN 'Mês Anterior'
        WHEN v.Data BETWEEN DATE_FORMAT(DATE_SUB(CURDATE(), INTERVAL 2 MONTH), '%Y-%m-01') 
             AND LAST_DAY(DATE_SUB(CURDATE(), INTERVAL 2 MONTH)) THEN '2 Meses Atrás'
        WHEN v.Data BETWEEN DATE_FORMAT(DATE_SUB(CURDATE(), INTERVAL 3 MONTH), '%Y-%m-01') 
             AND LAST_DAY(DATE_SUB(CURDATE(), INTERVAL 3 MONTH)) THEN '3 Meses Atrás'
        ELSE 'Histórico Geral'
    END AS periodo,
```
---

## 🏗️ Arquitetura

```
MySQL Database
    ↓
view_lucro_liquido (view base)
    ↓
vw_relatorio_performance_salao (view principal)
    ↓
Power BI (Conexão DirectQuery/Import)
    ↓
Dashboard com Visuais Inteligentes
```

---

## 💾 A View Principal: `vw_relatorio_performance_salao`

A view é o coração deste projeto. Ela realiza operações sofisticadas:

### ✨ Funcionalidades Principais

#### 1. **CTEs (Common Table Expressions) para Agregações**

```sql
WITH TicketMedio AS (
    -- Calcula o ticket médio por cliente (lucro total / número de clientes)
)
TotalLucro AS (
    -- Soma total de todos os lucros (referência para proporções)
)
```

Essas CTEs servem como benchmarks para categorização e cálculos percentuais.

#### 2. **Segmentação Temporal Inteligente (Hierarquia)**

A view classifica automaticamente cada registro em períodos:

- Usa funções MySQL como `CURDATE()`, `WEEKDAY()`, `DATE_FORMAT()`, `LAST_DAY()`
- Cria um campo `ordem_periodo` (1-9) para ordenação automática no Power BI
- Campo `periodo` com labels formatados em português

#### 3. **Categorização de Clientes (Window Functions)**

```sql
CASE
    WHEN COUNT(v.Cliente) OVER (PARTITION BY v.Cliente) < 2 THEN 'REGULAR'
    WHEN SUM(v.lucroliquido) OVER (PARTITION BY v.Cliente) > ticket_medio 
         AND COUNT(v.Cliente) OVER (PARTITION BY v.Cliente) > 2 THEN 'VIP'
    WHEN COUNT(v.Cliente) OVER (PARTITION BY v.Cliente) > 1 THEN 'PREMIUM'
    ELSE 'REGULAR'
END AS categoria_cliente
```

Classificação automática baseada em:
- Frequência de atendimentos (janelas)
- Lucro acumulado por cliente
- Comparação com o ticket médio

#### 4. **Proporcionalizações (Percentual do Total)**

```sql
ROUND(
    (v.LucroLiquido / (SELECT lucro_total FROM TotalLucro)) * 100,
    2
) AS percentual_do_total
```

Cada transação é contextualizada no volume total do período.

---

## 🔌 Configuração - MySQL + Power BI

### Passo 1: Criar a View no MySQL

1. Acesse seu banco de dados MySQL via client (MySQL Workbench, DBeaver, etc.)
2. Execute o script SQL fornecido
3. A view será criada em seu banco `Atendimentos`

### Passo 2: Conectar Power BI ao MySQL

#### Via Power BI Desktop:

1. **Obter dados** → **Banco de dados MySQL**
2. Preencha as informações:
   - **Servidor**: `localhost` (ou IP do seu servidor)
   - **Banco de dados**: `Atendimentos`
3. **Instrução SQL** (copie e cole):
   ```sql
   SELECT * FROM vw_relatorio_performance_salao
   ```
4. Clique em **Adicionar colunas de relação** ✓ (para joins automáticos)
5. Clique em **OK**

#### Modo de carregamento recomendado:

- **Import**: Se você quer performance máxima e dados em cache local
- **DirectQuery**: Se você precisa de dados sempre atualizados em tempo real

### Passo 3: Configurar o Visual

No Power BI:

1. Crie um **gráfico de barras**
2. **Eixo X**: Arraste o campo `periodo`
3. **Eixo Y**: Arraste `lucro_liquido` (agregado por SUM)
4. **Legenda/Série**: (opcional) `categoria_cliente` ou `Tipo_Atendimento`
5. Na aba **Dados**, ordene por `ordem_periodo` (hierarquia automática)

---

## 📈 O Que Você Obtém

###  **🎯 Análise Temporal Sem Filtros Manuais**

**Problema Tradicional:**
Você precisa criar filtros, selecionar períodos, clicar em botões... tudo para comparar "Hoje vs Ontem" ou "Este mês vs Mês passado".

**Solução:**
A view já estrutura os dados em períodos pré-definidos e inteligentes. Você não precisa fazer nada - o gráfico já está pronto com todas as comparações que você precisa.
Na Prática:

Vê o lucro de hoje (R$ 1.200) instantaneamente
Compara com ontem (R$ 600) na barra ao lado
Vê a semana atual versus semana passada sem fazer nada
Entende a evolução em 3 meses em um único olhar

**Resultado:** Decisões mais rápidas. Você não fica perdido em filtros - os dados falam sozinhos.

---

## 🎨 Campos Disponíveis na View

| Campo | Tipo | Descrição |
|-------|------|-----------|
| `Data` | DATE | Data do atendimento |
| `id_cliente` | INT | ID do cliente |
| `id_servico` | INT | ID do serviço |
| `SaoClientes` | VARCHAR | Classificação especial (sim/não) |
| `ordem_periodo` | INT | Ordem hierárquica (1-9) |
| `periodo` | VARCHAR | Rótulo do período (ex: "Mês Atual") |
| `categoria_cliente` | VARCHAR | VIP / PREMIUM / REGULAR |
| `percentual_do_total` | DECIMAL | Proporção do lucro total (%) |
| `Tipo_Atendimento` | VARCHAR | Tipo de serviço |
| `TipoPagamento` | VARCHAR | Forma de pagamento |
| `valor_atendimento` | DECIMAL | Valor bruto |
| `receita_liquida` | DECIMAL | Receita após descontos |
| `lucro_liquido` | DECIMAL | Lucro efetivo |
| `repasse` | DECIMAL | Diferença (Receita - Lucro) |

---

## 🚀 Uso Avançado

### Segmentar por Categoria de Cliente

No Power BI, você pode criar visuals adicionais:

```
Visual: Lucro por Categoria
- VIP → R$ 7.925 (Histórico)
- PREMIUM → R$ 2.980 (2 Meses Atrás)
- REGULAR → R$ 1.200 (Hoje)
```

### Comparar Períodos

```
Comparação Automática:
- Mês Atual: R$ 1.954
- Mês Anterior: R$ 6.798 (↓ 71%)
- Crescimento em relação a 3 meses atrás: +187%
```

### Análise por Tipo de Atendimento

Adapte o visual para mostrar qual tipo de atendimento (presencial, online, etc.) é mais lucrativo em cada período.

---

## 🖼️ Visual

O design priorizou uma interface **limpa, elegante e objetiva**, destacando o essencial para decisões rápidas e eficazes.

![Gráfico](https://imgur.com/m7Q11NG.png)

Exemplo ao conectar no **banco de dados - Mysql**

![Banco](https://imgur.com/65mqxJQ.png)  


---

## ⚙️ Requisitos

- **MySQL 5.7+** (ou MariaDB)
- **Power BI Desktop** (versão recente recomendada)
- **MySQL Connector for Power BI** instalado
- Acesso ao banco `Atendimentos` com permissão de **SELECT**

---

## 📌 Conclusão

Este dashboard transforma dados brutos em **inteligência visual** através de:

✅ SQL inteligente (CTEs, Window Functions, CASE statements)  
✅ Hierarquias temporais automáticas  
✅ Categorização dinâmica de clientes  
✅ Proporcionalizações contextuais  
✅ Integração seamless MySQL → Power BI  

O resultado? Um visual simples mas **poderoso**, que conta a história completa da performance do seu salão.

---