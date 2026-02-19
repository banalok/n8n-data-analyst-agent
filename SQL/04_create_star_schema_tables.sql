BEGIN;

CREATE TABLE IF NOT EXISTS public.dim_customers (
  customer_id TEXT PRIMARY KEY,
  customer_name TEXT,
  state TEXT,
  currency TEXT
);

CREATE TABLE IF NOT EXISTS public.dim_products (
  product_id TEXT PRIMARY KEY,
  product_name TEXT,
  category TEXT,
  price_usd NUMERIC
);

CREATE TABLE IF NOT EXISTS public.dim_targets_orders (
  customer_id TEXT,
  ontime_target NUMERIC,
  infull_target NUMERIC,
  otif_target NUMERIC
);

CREATE TABLE IF NOT EXISTS public.fact_order_line (
  order_id TEXT,
  customer_id TEXT,
  product_id TEXT,
  order_qty NUMERIC,
  delivery_qty NUMERIC,
  order_placement_date DATE,
  agreed_delivery_date DATE,
  actual_delivery_date DATE,
  on_time BOOLEAN,
  in_full BOOLEAN,
  on_time_in_full BOOLEAN
);

CREATE TABLE IF NOT EXISTS public.fact_aggregate (
  order_id TEXT,
  on_time BOOLEAN,
  in_full BOOLEAN,
  on_time_in_full BOOLEAN
);

COMMIT;
