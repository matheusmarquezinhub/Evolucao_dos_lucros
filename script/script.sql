
CREATE OR REPLACE VIEW vw_relatorio_performance_salao AS
WITH TicketMedio AS (
    -- Mantido o cálculo de média do lucro total por cliente.
    SELECT AVG(total_lucro) AS ticket_medio
    FROM (
        SELECT SUM(lucroliquido) AS total_lucro
        FROM view_lucro_liquido
        GROUP BY Cliente
    ) AS sub
),
TotalLucro AS (
    SELECT SUM(lucroliquido) AS lucro_total
    FROM view_lucro_liquido
)
SELECT
	v.Data,
    -- CLIENTE
    v.Cliente AS id_cliente,
    -- SERVIÇO
    v.Servico AS id_servico,
    -- SAO CLIENTES
    d.SaoClientes AS SaoClientes,
    -- ORDEM DOS PERÍODOS (Hierarquia de Power BI)
    CASE 
        WHEN v.Data = CURDATE() THEN 1                                                                -- Hoje
        WHEN v.Data = DATE_SUB(CURDATE(), INTERVAL 1 DAY) THEN 2                                      -- Ontem
        -- Semana Atual (Início na Segunda-feira)
        WHEN v.Data >= DATE_SUB(CURDATE(), INTERVAL WEEKDAY(CURDATE()) DAY) THEN 3
        -- Mês Atual
        WHEN v.Data >= DATE_FORMAT(CURDATE(), '%Y-%m-01') THEN 4
        -- Semana Passada (Segunda-feira passada até Domingo passado)
        WHEN v.Data BETWEEN DATE_SUB(CURDATE(), INTERVAL (WEEKDAY(CURDATE()) + 7) DAY) 
             AND DATE_SUB(CURDATE(), INTERVAL (WEEKDAY(CURDATE()) + 1) DAY) THEN 5
        -- Mês Anterior
        WHEN v.Data BETWEEN DATE_FORMAT(DATE_SUB(CURDATE(), INTERVAL 1 MONTH), '%Y-%m-01') 
             AND LAST_DAY(DATE_SUB(CURDATE(), INTERVAL 1 MONTH)) THEN 6
        -- 2 Meses Atrás
        WHEN v.Data BETWEEN DATE_FORMAT(DATE_SUB(CURDATE(), INTERVAL 2 MONTH), '%Y-%m-01') 
             AND LAST_DAY(DATE_SUB(CURDATE(), INTERVAL 2 MONTH)) THEN 7
        -- 3 Meses Atrás
        WHEN v.Data BETWEEN DATE_FORMAT(DATE_SUB(CURDATE(), INTERVAL 3 MONTH), '%Y-%m-01') 
             AND LAST_DAY(DATE_SUB(CURDATE(), INTERVAL 3 MONTH)) THEN 8
        ELSE 9                                                                                        -- Histórico Geral
    END AS ordem_periodo,

    -- PERÍODO FORMATADO
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

    -- Categoria Cliente (Window Functions usadas corretamente aqui)
    CASE
        WHEN COUNT(v.Cliente) OVER (PARTITION BY v.Cliente) < 2 THEN 'REGULAR'
        WHEN SUM(v.lucroliquido) OVER (PARTITION BY v.Cliente) > (SELECT ticket_medio FROM TicketMedio) 
             AND COUNT(v.Cliente) OVER (PARTITION BY v.Cliente) > 2 THEN 'VIP'
        WHEN COUNT(v.Cliente) OVER (PARTITION BY v.Cliente) > 1 THEN 'PREMIUM'
        ELSE 'REGULAR'
    END AS categoria_cliente,

    -- CÁLCULO CORRIGIDO: Usa o LucroLiquido da linha atual dividido pelo Lucro Total (da CTE)
    ROUND(
        (v.LucroLiquido / (SELECT lucro_total FROM TotalLucro)) * 100,
        2
    ) AS percentual_do_total,

    -- ATENDIMENTO
    v.Tipo_Atendimento,

    -- PAGAMENTO
    v.TipoPagamento,

    -- VALORES
    v.Valores AS valor_atendimento,
    v.ReceitaLiquida AS receita_liquida,
    v.LucroLiquido AS lucro_liquido,
    (v.ReceitaLiquida - v.LucroLiquido) AS repasse
FROM view_lucro_liquido v
LEFT JOIN Cliente c ON c.IdCliente = v.Cliente
LEFT JOIN Servico s ON s.IDServico = v.Servico
LEFT JOIN Dados d ON d.ID_dados = v.Id_Dados
ORDER BY v.Data DESC, v.Cliente, v.Servico;