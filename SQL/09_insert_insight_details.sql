BEGIN;
TRUNCATE insights_detail;

-- Worst customers by OTIF
INSERT INTO insights_detail (insight_type, rank, entity_id, entity_name, value, n_lines, notes)
SELECT
  'worst_customers_otif' AS insight_type,
  ROW_NUMBER() OVER (ORDER BY otif_pct ASC) AS rank,
  customer_id AS entity_id,
  customer_name AS entity_name,
  otif_pct AS value,
  n_lines,
  'OTIF% (lower is worse)' AS notes
FROM (
  SELECT
    c.customer_id,
    c.customer_name,
    (100.0 * AVG(CASE WHEN f.on_time_in_full IS TRUE THEN 1 ELSE 0 END))::numeric AS otif_pct,
    COUNT(*)::int AS n_lines
  FROM fact_order_line f
  JOIN dim_customers c ON c.customer_id = f.customer_id
  GROUP BY c.customer_id, c.customer_name
) x
ORDER BY otif_pct ASC
LIMIT 10;

-- Worst products by OTIF
INSERT INTO insights_detail (insight_type, rank, entity_id, entity_name, value, n_lines, notes)
SELECT
  'worst_products_otif',
  ROW_NUMBER() OVER (ORDER BY otif_pct ASC),
  product_id,
  product_name,
  otif_pct,
  n_lines,
  'OTIF% (lower is worse)'
FROM (
  SELECT
    p.product_id,
    p.product_name,
    (100.0 * AVG(CASE WHEN f.on_time_in_full IS TRUE THEN 1 ELSE 0 END))::numeric AS otif_pct,
    COUNT(*)::int AS n_lines
  FROM fact_order_line f
  JOIN dim_products p ON p.product_id = f.product_id
  GROUP BY p.product_id, p.product_name
) x
ORDER BY otif_pct ASC
LIMIT 10;

-- Customer OTIF gap vs target (actual - target; more negative = worse)
INSERT INTO insights_detail (insight_type, rank, entity_id, entity_name, value, n_lines, notes)
SELECT
  'customer_otif_gap_vs_target',
  ROW_NUMBER() OVER (ORDER BY (actual_otif_pct - target_otif_pct) ASC),
  customer_id,
  customer_name,
  (actual_otif_pct - target_otif_pct)::numeric AS value,
  n_lines,
  'Actual OTIF% - Target OTIF% (more negative = worse)'
FROM (
  SELECT
    c.customer_id,
    c.customer_name,
    (100.0 * AVG(CASE WHEN f.on_time_in_full IS TRUE THEN 1 ELSE 0 END))::numeric AS actual_otif_pct,
    COALESCE(t.otif_target, 0)::numeric AS target_otif_pct,
    COUNT(*)::int AS n_lines
  FROM fact_order_line f
  JOIN dim_customers c ON c.customer_id = f.customer_id
  LEFT JOIN dim_targets_orders t ON t.customer_id = c.customer_id
  GROUP BY c.customer_id, c.customer_name, t.otif_target
) x
ORDER BY (actual_otif_pct - target_otif_pct) ASC
LIMIT 10;
COMMIT;