# Automated Inventory / OTIF Analytics Pipeline (n8n + Postgres + OpenAI)

An **end-to-end analytics automation** that:
1) listens for an email with a CSV attachment,
2) loads raw operational data into **PostgreSQL**,
3) builds a **star schema** (dimensions + facts),
4) computes **data quality (QC)** + **business KPIs** + **root-cause rankings**,
5) generates an **executive summary using an LLM**,
6) emails the report automatically.

This is a reproducible pipeline designed for demonstrating automation to deliver business insights.

---

## What problem this solves

Teams often receive operational data (orders, deliveries, targets) as spreadsheets/CSVs. Manually analyzing and summarizing these files is time-consuming and inconsistent.

This project automates that workflow:
- **ELT** (Extract → Load → Transform) into Postgres
- **Quality checks** to detect missingness/anomalies
- **Service-level KPIs** (On-Time, In-Full, OTIF)
- **Actionable rankings**: worst customers/products + gaps vs target
- **LLM summary** for decision-makers
- **Email delivery** of insights

---

## Tech stack

- **n8n** (workflow orchestration, email trigger, DB steps, email delivery)
- **PostgreSQL** (warehouse + analytics SQL)
- **OpenAI API** (LLM-generated executive report)

---
## Demo

**Workflow Demo:**
![Demo](https://github.com/banalok/n8n-data-analyst-agent/blob/main/demo/demo.gif)

**Database:**
![PostgreSQL Screenshot](https://github.com/banalok/n8n-data-analyst-agent/blob/main/demo/PostgreSQL.PNG)

## Data model (Star Schema)

### Staging
- `stg_order_lines_raw`  
  Raw table that stores the original CSV rows exactly in the database.

### Dimensions
- `dim_customers`  
  Customer master: `customer_id`, `customer_name`, `state`, `currency`

- `dim_products`  
  Product catalog: `product_id`, `product_name`, `category`, `price_usd`

- `dim_targets_orders`  
  Customer service targets: `customer_id`, `ontime_target`, `infull_target`, `otif_target`

### Facts
- `fact_order_line`  
  Line-level operational events: order_qty, delivery_qty, order/delivery dates, flags

- `fact_aggregate`  
  Order-level rollup: aggregates line flags to a single order summary

---

## Domain knowledge (simple definitions)

### On-Time (OT)
A line/order is **on time** if the actual delivery happened **on or before the agreed delivery date**.

### In-Full (IF)
A line/order is **in full** if the **delivered quantity meets the ordered quantity** (often `delivery_qty >= order_qty`).

### OTIF (On-Time In-Full)
A line/order is **OTIF** only if **both** are true:
- on-time = true  
- in-full = true

**Why OTIF matters:** It’s a core service-level metric for supply chain performance. Low OTIF usually means customer dissatisfaction, churn risk, and operational bottlenecks.

### Targets
Targets represent expected performance (e.g., OTIF target = 90%). Comparing actual vs target highlights where performance is below expectation.

---

## What the pipeline produces

### QC tables
- `qc_summary`  
  Counts + percentages of missing data and anomalies (e.g., missing dates, negative qty, over-delivery)

### Insights tables
- `insights_summary`  
  Top-level KPIs such as:
  - on_time_rate_pct
  - in_full_rate_pct
  - otif_rate_pct
  - open_lines_missing_actual_delivery_date

- `insights_detail`  
  Ranked diagnostics, such as:
  - worst customers by OTIF
  - worst products by OTIF
  - customer OTIF gap vs target

---

## Workflow: step-by-step (n8n)

### 1) Trigger + parse
1. **Gmail Trigger1**
   - Watches the inbox and triggers the workflow when an email matching the filter arrives (subject/sender) and downloads the attachment.

2. **Extract from File1 (Extract From CSV)**
   - Reads the CSV attachment and converts it into row items (one item per order line).

---

### 2) Load “original/raw” table
3. **Limit to avoid overload1**
   - Safety guard to cap the number of CSV rows processed into the table creation nodes.

4. **Create a table in the DB that stores original data**
   - Creates the raw/staging table (if it doesn’t exist) to hold the CSV rows.

5. **Clear table contents before inserting**
   - Deletes the raw/staging table so each run starts clean (prevents duplicates).

6. **Data passthrough (chooseBranch)**
   - Pass original data through to be inserted into the DB table.

7. **Insert original rows in the main table in the DB**
   - Inserts all extracted CSV rows into the raw/staging table.

---

### 3) Build warehouse model (star schema)
8. **Create star schema (Fact and Dim) tables in the DB**
   - Creates dimension and fact tables.

9. **Insert corresponding data into the star schema**
   - Transforms raw rows into the star schema:
     - Loads `dim_customers`
     - Loads `dim_products`
     - Loads `dim_targets_orders`
     - Loads `fact_order_line`
     - Loads `fact_aggregate`

---

### 4) QC + analytics tables
10. **Create qc summary, insights summary and details tables**
   - Creates analytics tables for QC and KPI metrics.

11. **Insert qc summary into the table**
   - Computes and stores data quality checks (counts, missing values, anomalies).

12. **Insert insights summary into the table**
   - Computes KPI metrics such as OTIF, on-time %, in-full %.

13. **Insert insights details into the table**
   - Stores ranked diagnostics (worst customers, worst products, gaps vs targets).

14. **Compute root cause rankings**
   - Generates deeper diagnostics for performance issues.

15. **Create consolidate metrics: QC + Insights**
   - Combines QC + KPI + detail rows into one dataset for reporting.

---

### 5) LLM + Email
16. **Feed consolidated metrics to LLM**
   - Sends consolidated metrics to OpenAI to generate an executive summary.

17. **Convert summary to email html**
   - Formats the summary into readable HTML (headings, lists, spacing).

18. **Limit to 1 email to avoid overload**
   - Ensures only one email is sent per workflow run.

19. **Send an email with summary and insights**
   - Sends the executive report to stakeholders.

---

## Outcome

When a CSV is emailed:

- Data is ingested
- Warehouse tables are rebuilt
- QC and KPIs are computed
- Root causes are analyzed
- An AI executive summary is generated
- A formatted report is emailed automatically


## Typical executive output

The email contains:
- **Key takeaways** (5 bullets)
- **Risks/Anomalies**
- **Recommended actions**
- **Questions leadership should investigate**

Example insights:
- OTIF is low (service performance issue)
- Many open lines missing actual delivery date (backlog risk)
- Worst customers/products by OTIF (root cause ranking)
- Largest negative gap vs target (priority accounts)

---

## How to run (high-level)

1) Deploy **n8n** (cloud or self-hosted).
2) Connect credentials:
   - Gmail Trigger credentials
   - Postgres credentials
   - OpenAI API credentials
3) Create a Gmail filter (optional) so “Inventory Data” emails are easy to match.
4) Send an email to the trigger inbox with a CSV attachment.
5) Workflow runs automatically and emails the report.

---

## Notes on reliability

- This pipeline **recreates/truncates tables** each run to avoid duplicates.
- “One email per run” requires ensuring the final report path is collapsed to a single item (e.g., Limit(1) before Send Email), so it doesn’t send one email per row.

---

## Repo contents (suggested)

