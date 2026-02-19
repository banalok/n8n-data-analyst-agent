WITH r AS (
  SELECT
    section,
    COALESCE(metric,'') AS metric,
    COALESCE(value::text,'') AS value,
    COALESCE(notes,'') AS notes,
    COALESCE(insight_type,'') AS insight_type,
    COALESCE(rank::text,'') AS rank,
    COALESCE(entity_name, entity_id, '') AS entity,
    COALESCE(n_lines::text,'') AS n_lines
  FROM (
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
  ) x
),
txt AS (
  SELECT string_agg(
    CASE
      WHEN section = 'qc_summary' THEN
        '[QC] ' || metric || ' = ' || value || ' (' || notes || ')'
      WHEN section = 'insights_summary' THEN
        '[KPI] ' || metric || ' = ' || value || ' (' || notes || ')'
      ELSE
        '[DETAIL] ' || insight_type || ' #' || rank || ': ' || entity ||
        ' | value=' || value ||
        ' | n_lines=' || n_lines ||
        ' | ' || notes
    END,
    E'\n'
    ORDER BY section, insight_type, rank, metric
  ) AS data_text
  FROM r
)
SELECT
  'You are a senior supply chain analytics assistant.

Your task is to interpret operational metrics and provide a concise executive summary.

Write in the follwoing format with sentence gaps between each point:

1) Key takeaways (5 bullets)
2) Risks or anomalies (bullet list)
3) Recommended actions (3–6 bullets)
4) Questions leadership should investigate (3–5 bullets)

Guidelines:
- Use only the data provided
- Highlight if OTIF is low
- Mention open orders if delivery dates are missing
- Mention data quality concerns if QC shows issues
- Reference worst customers/products when relevant
- Be clear, concise, and business-friendly

DATA:
' || data_text AS prompt
FROM txt;
