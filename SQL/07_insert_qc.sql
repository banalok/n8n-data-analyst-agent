TRUNCATE qc_summary;

INSERT INTO qc_summary (metric, value, notes)
SELECT metric, value, notes
FROM (
  SELECT 'order_lines_count' AS metric, COUNT(*)::numeric AS value, 'post-load' AS notes
  FROM fact_order_line

  UNION ALL
  SELECT 'customers_count', COUNT(*)::numeric, 'post-load'
  FROM dim_customers

  UNION ALL
  SELECT 'products_count', COUNT(*)::numeric, 'post-load'
  FROM dim_products

  UNION ALL
  SELECT 'targets_count', COUNT(*)::numeric, 'post-load'
  FROM dim_targets_orders

  UNION ALL
  SELECT 'missing_order_date', SUM(CASE WHEN order_placement_date IS NULL THEN 1 ELSE 0 END)::numeric, 'post-load'
  FROM fact_order_line

  UNION ALL
  SELECT 'missing_delivery_date', SUM(CASE WHEN actual_delivery_date IS NULL THEN 1 ELSE 0 END)::numeric, 'post-load'
  FROM fact_order_line

  UNION ALL
  SELECT 'negative_order_qty', SUM(CASE WHEN order_qty < 0 THEN 1 ELSE 0 END)::numeric, 'post-load'
  FROM fact_order_line

  UNION ALL
  SELECT 'negative_delivery_qty', SUM(CASE WHEN delivery_qty < 0 THEN 1 ELSE 0 END)::numeric, 'post-load'
  FROM fact_order_line

  UNION ALL
  SELECT 'delivery_gt_order', SUM(CASE WHEN delivery_qty > order_qty THEN 1 ELSE 0 END)::numeric, 'post-load'
  FROM fact_order_line

  UNION ALL
  SELECT 'pct_missing_order_date',
         (100.0 * SUM(CASE WHEN order_placement_date IS NULL THEN 1 ELSE 0 END) / NULLIF(COUNT(*),0))::numeric,
         'post-load'
  FROM fact_order_line

  UNION ALL
  SELECT 'pct_missing_delivery_date',
         (100.0 * SUM(CASE WHEN actual_delivery_date IS NULL THEN 1 ELSE 0 END) / NULLIF(COUNT(*),0))::numeric,
         'post-load'
  FROM fact_order_line

  UNION ALL
  SELECT 'otif_true_count',
         SUM(CASE WHEN on_time_in_full IS TRUE THEN 1 ELSE 0 END)::numeric,
         'post-load'
  FROM fact_order_line

  UNION ALL
  SELECT 'otif_null_count',
         SUM(CASE WHEN on_time_in_full IS NULL THEN 1 ELSE 0 END)::numeric,
         'post-load'
  FROM fact_order_line
) t;
