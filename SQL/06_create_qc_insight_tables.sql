BEGIN;
CREATE TABLE IF NOT EXISTS qc_summary (
  metric text PRIMARY KEY,
  value numeric,
  notes text,
  run_ts timestamptz DEFAULT now()
);

CREATE TABLE IF NOT EXISTS insights_summary (
  metric text PRIMARY KEY,
  value numeric,
  notes text,
  run_ts timestamptz DEFAULT now()
);

CREATE TABLE IF NOT EXISTS insights_detail (
  insight_type text,
  rank int,
  entity_id text,
  entity_name text,
  value numeric,
  n_lines int,
  notes text,
  run_ts timestamptz DEFAULT now(),
  PRIMARY KEY (insight_type, rank, run_ts)
);
COMMIT;