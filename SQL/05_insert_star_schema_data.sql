BEGIN;
-- dims
TRUNCATE dim_customers, dim_products, dim_targets_orders, fact_order_line, fact_aggregate;
  
INSERT INTO dim_customers (customer_id, customer_name, state, currency)
SELECT DISTINCT
  customer_id,
  customer_name,
  state,
  COALESCE(NULLIF(currency,''), 'USD') AS currency
FROM stg_order_lines_raw
WHERE customer_id IS NOT NULL;

INSERT INTO dim_products (product_id, product_name, category, price_usd)
SELECT DISTINCT
  product_id,
  product_name,
  category,
  price_usd
FROM stg_order_lines_raw
WHERE product_id IS NOT NULL;

INSERT INTO dim_targets_orders (customer_id, ontime_target, infull_target, otif_target)
SELECT DISTINCT
  customer_id,
  ontime_target_pct,
  infull_target_pct,
  otif_target_pct
FROM stg_order_lines_raw
WHERE customer_id IS NOT NULL;

-- facts
INSERT INTO fact_order_line (
  order_id, customer_id, product_id, order_qty, delivery_qty,
  order_placement_date, agreed_delivery_date, actual_delivery_date,
  on_time, in_full, on_time_in_full
)
SELECT
  order_id,
  customer_id,
  product_id,
  order_qty,
  delivery_qty,
  CASE
    WHEN NULLIF(order_placement_date,'') IS NULL THEN NULL
    ELSE to_date(order_placement_date, 'DD-MM-YYYY')
  END AS order_placement_date,
  CASE
    WHEN NULLIF(agreed_delivery_date,'') IS NULL THEN NULL
    ELSE to_date(agreed_delivery_date, 'DD-MM-YYYY')
  END AS agreed_delivery_date,
  CASE
    WHEN NULLIF(actual_delivery_date,'') IS NULL THEN NULL
    ELSE to_date(actual_delivery_date, 'DD-MM-YYYY')
  END AS actual_delivery_date,
  on_time,
  in_full,
  on_time_in_full
FROM stg_order_lines_raw;

-- order-level aggregate
INSERT INTO fact_aggregate (order_id, on_time, in_full, on_time_in_full)
SELECT
  order_id,
  bool_and(on_time) AS on_time,
  bool_and(in_full) AS in_full,
  bool_and(on_time_in_full) AS on_time_in_full
FROM stg_order_lines_raw
GROUP BY order_id;
COMMIT;
