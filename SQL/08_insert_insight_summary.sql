TRUNCATE insights_summary;

INSERT INTO insights_summary (metric, value, notes)
SELECT metric, value, notes
FROM (
  SELECT 'on_time_rate_pct' AS metric,
         (100.0 * AVG(CASE WHEN on_time IS TRUE THEN 1 ELSE 0 END))::numeric AS value,
         'line-level' AS notes
  FROM fact_order_line

  UNION ALL
  SELECT 'in_full_rate_pct',
         (100.0 * AVG(CASE WHEN in_full IS TRUE THEN 1 ELSE 0 END))::numeric,
         'line-level'
  FROM fact_order_line

  UNION ALL
  SELECT 'otif_rate_pct',
         (100.0 * AVG(CASE WHEN on_time_in_full IS TRUE THEN 1 ELSE 0 END))::numeric,
         'line-level'
  FROM fact_order_line

  UNION ALL
  SELECT 'open_lines_missing_actual_delivery_date',
         SUM(CASE WHEN actual_delivery_date IS NULL THEN 1 ELSE 0 END)::numeric,
         'likely open/not delivered'
  FROM fact_order_line
) t;
