
BEGIN;
SELECT
  'qc_summary' AS section,
  metric,
  value,
  notes,
  NULL::text AS insight_type,
  NULL::int  AS rank,
  NULL::text AS entity_id,
  NULL::text AS entity_name,
  NULL::int  AS n_lines
FROM qc_summary

UNION ALL

SELECT
  'insights_summary' AS section,
  metric,
  value,
  notes,
  NULL::text AS insight_type,
  NULL::int  AS rank,
  NULL::text AS entity_id,
  NULL::text AS entity_name,
  NULL::int  AS n_lines
FROM insights_summary

UNION ALL

SELECT
  'insights_detail' AS section,
  NULL::text AS metric,
  value,
  notes,
  insight_type,
  rank,
  entity_id,
  entity_name,
  n_lines
FROM insights_detail

ORDER BY section, insight_type, rank, metric;
COMMIT;
