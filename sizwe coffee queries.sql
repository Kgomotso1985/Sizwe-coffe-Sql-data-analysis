-- Task 1: Channel performance
SELECT
    so.channel,
    SUM(CASE WHEN so.order_date <= '2024-06-30' THEN sl.line_revenue ELSE 0 END) AS fy2024_revenue,
    SUM(CASE WHEN so.order_date > '2024-06-30' AND so.order_date <= '2025-06-30' THEN sl.line_revenue ELSE 0 END) AS fy2025_revenue,
    ROUND(
        (SUM(CASE WHEN so.order_date > '2024-06-30' AND so.order_date <= '2025-06-30' THEN sl.line_revenue ELSE 0 END) 
         - SUM(CASE WHEN so.order_date <= '2024-06-30' THEN sl.line_revenue ELSE 0 END)) * 1.0
        / NULLIF(SUM(CASE WHEN so.order_date <= '2024-06-30' THEN sl.line_revenue ELSE 0 END), 0) * 100, 2) AS growth_pct
FROM sales_orders so
JOIN sales_lines sl ON sl.order_id = so.order_id
GROUP BY so.channel;

-- Answer: The Wholesale channel is still the biggest part of the business. It made about R335.4 million in FY2025, which is an 8.85% increase from the previous year. The Subscription channel also grew by 8.84%, bringing in R144.5 million. Both channels grew at almost the exact same rate.


-- Task 2: Where the profit actually comes from
SELECT
    p.product_line,
    SUM(sl.line_revenue) AS revenue,
    SUM(sl.cogs) AS cost_of_goods,
    SUM(sl.line_revenue) - SUM(sl.cogs) AS gross_profit,
    ROUND((SUM(sl.line_revenue) - SUM(sl.cogs)) * 1.0 / NULLIF(SUM(sl.line_revenue), 0) * 100, 2) AS gross_margin_pct
FROM sales_lines sl
JOIN products p ON p.sku = sl.sku
GROUP BY p.product_line
ORDER BY gross_profit DESC;

-- Answer: House Blend brought in the most total profit (about R10.7 million). However, Single Origin is the most profitable per item, with a 44.27% margin. Bulk Commercial is the complete opposite: it sells a lot (R27.1 million), but the margin is very low at only 19.9%.


-- Task 3: The collections problem
SELECT
    c.channel,
    COUNT(*) AS invoice_count,
    COUNT(*) FILTER (WHERE al.amount_settled >= al.invoice_amount) AS settled_invoices,
    COUNT(*) FILTER (WHERE al.amount_settled < al.invoice_amount OR al.amount_settled IS NULL) AS open_invoices,
    ROUND(AVG(CASE WHEN al.settlement_date IS NOT NULL THEN datediff(al.settlement_date, al.due_date) END) * 1.0, 1) AS avg_days_to_settle,
    SUM(CASE WHEN al.amount_settled < al.invoice_amount OR al.amount_settled IS NULL 
             THEN GREATEST(al.invoice_amount - COALESCE(al.amount_settled, 0), 0) ELSE 0 END) AS total_outstanding
FROM ar_ledger al
JOIN customers c ON c.customer_id = al.customer_id
GROUP BY c.channel
ORDER BY total_outstanding DESC;

-- Answer: The Wholesale channel has a big collections problem. There is roughly R878.4 million still owed to the company, and on average, wholesale customers pay 17.2 days late. Subscription is totally different: there are only 44 open invoices, and they usually pay about 26 days before the due date.


-- Task 4: The ten accounts that matter most
SELECT
    c.trading_name,
    c.segment,
    c.province,
    COALESCE(r.rep_name, 'Unassigned') AS sales_representative,
    SUM(sl.line_revenue) AS fy2025_revenue
FROM customers c
JOIN sales_orders so ON so.customer_id = c.customer_id
JOIN sales_lines sl ON sl.order_id = so.order_id
LEFT JOIN reps r ON r.rep_id = c.rep_id
WHERE so.order_date > '2024-06-30' AND so.order_date <= '2025-06-30'
GROUP BY c.customer_id, c.trading_name, c.segment, c.province, r.rep_name
ORDER BY fy2025_revenue DESC
LIMIT 10;

-- Answer: The top customer is Halvane Retail Group, bringing in R3.8 million. Most of the top 10 list is made up of Independent Cafes. The revenue for the top 10 is quite close, ranging from R3.8 million down to R1.9 million. Reps Chantal Ismail and Karabo Zwane each handle two of these top accounts.


-- Task 5: A commercial gap
SELECT
    c.trading_name AS customer_name,
    c.segment,
    c.province,
    SUM(sl.line_revenue) AS revenue
FROM customers c
JOIN sales_orders so ON so.customer_id = c.customer_id
JOIN sales_lines sl ON sl.order_id = so.order_id
WHERE c.channel = 'Wholesale'
  AND NOT EXISTS (SELECT 1 FROM trade_promotions tp WHERE tp.customer_id = c.customer_id)
GROUP BY c.customer_id, c.trading_name, c.segment, c.province
ORDER BY revenue DESC
LIMIT 15;

-- Answer: Umhlanga Fresh 108 is the biggest wholesale customer (R6.2 million) that doesn't have a trade promotion. Looking at the rest of the list, most of the accounts missing promotions are Independent Cafes and Restaurant Groups. This shows a good opportunity to sign them up for deals.


-- Task 6: Are the sales representatives hitting target?
SELECT
    r.rep_name AS sales_representative,
    r.territory,
    ROUND(COALESCE(SUM(sl.line_revenue), 0) / 12.0, 2) AS fy2025_monthly_avg,
    SUM(sl.line_revenue) AS total_fy2025_revenue
FROM reps r
LEFT JOIN sales_orders so ON so.rep_id = r.rep_id AND so.order_date > '2024-06-30' AND so.order_date <= '2025-06-30'
LEFT JOIN sales_lines sl ON sl.order_id = so.order_id
GROUP BY r.rep_id, r.rep_name, r.territory
ORDER BY total_fy2025_revenue DESC;

-- Answer: There was no target column in the data, so I just ranked them by total revenue. Kagiso Mkhize sold the most (R59.9 million). Karabo Zwane came second with R30.1 million, followed by Nomsa Botha with R28.5 million.


-- Task 7: The shape of the year
WITH monthly AS (
    SELECT
        DATE_TRUNC('month', so.order_date) AS month_start,
        SUM(sl.line_revenue) AS revenue
    FROM sales_orders so
    JOIN sales_lines sl ON sl.order_id = so.order_id
    GROUP BY DATE_TRUNC('month', so.order_date)
)
SELECT
    month_start,
    revenue,
    ROUND((revenue - LAG(revenue) OVER (ORDER BY month_start)) * 1.0 / NULLIF(LAG(revenue) OVER (ORDER BY month_start), 0) * 100, 2) AS mom_pct_change,
    ROUND(AVG(revenue) OVER (ORDER BY month_start ROWS BETWEEN 2 PRECEDING AND CURRENT ROW), 2) AS rolling_3m_avg
FROM monthly
ORDER BY month_start;

-- Answer: Sales clearly drop in December. December 2023 was the lowest month (R29.8 million). But then sales bounce back really strongly in January and February. Overall, the business is growing steadily, ending with the best month in June 2025 (R45.1 million).


-- Task 8: Why has the margin moved?
WITH line_fy AS (
    SELECT
        p.product_line,
        CASE WHEN so.order_date <= '2024-06-30' THEN 'FY2024' ELSE 'FY2025' END AS fy,
        SUM(sl.line_revenue) AS revenue,
        SUM(sl.cogs) AS cogs
    FROM sales_orders so
    JOIN sales_lines sl ON sl.order_id = so.order_id
    JOIN products p ON p.sku = sl.sku
    GROUP BY p.product_line, CASE WHEN so.order_date <= '2024-06-30' THEN 'FY2024' ELSE 'FY2025' END
),
with_share AS (
    SELECT
        product_line, fy, revenue, cogs,
        ROUND((revenue - cogs) * 1.0 / NULLIF(revenue, 0) * 100, 2) AS gm_pct,
        ROUND(revenue * 1.0 / SUM(revenue) OVER (PARTITION BY fy) * 100, 2) AS revenue_share_pct
    FROM line_fy
)
SELECT
    product_line,
    MAX(CASE WHEN fy = 'FY2024' THEN revenue END) AS fy2024_revenue,
    MAX(CASE WHEN fy = 'FY2024' THEN gm_pct END) AS fy2024_gm_pct,
    MAX(CASE WHEN fy = 'FY2024' THEN revenue_share_pct END) AS fy2024_share_pct,
    MAX(CASE WHEN fy = 'FY2025' THEN revenue END) AS fy2025_revenue,
    MAX(CASE WHEN fy = 'FY2025' THEN gm_pct END) AS fy2025_gm_pct,
    MAX(CASE WHEN fy = 'FY2025' THEN revenue_share_pct END) AS fy2025_share_pct
FROM with_share
GROUP BY product_line
ORDER BY fy2025_revenue DESC NULLS LAST;

-- Answer: The overall margin dropped because Bulk Commercial sales exploded from R110 million to R161 million. Because Bulk Commercial has a very low margin (19.9%), selling so much of it dragged the whole company's margin down. Meanwhile, high-margin products like Single Origin actually saw their sales decrease.