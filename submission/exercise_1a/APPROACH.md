# Exercise 1a - approach

## dbt Model

SCD type 1: one current row per `employee_id` as business only cares about latest state.

## Logic

1. Dedupe exact re-deliveries (same employee, timestamp, operation, and payload).
2. Pick the latest event per employee in the batch by `_de_source_datetime` (`_de_ingested_datetime` as final tie-break).
3. Map `delete` → `is_active = false`. Row stays - no hard deletes.
4. **Incremental (batch only):** read events where `_de_ingested_datetime` is in the lookback window. Compute latest per employee in that batch. Merge to dim only if `last_source_datetime` is newer than what's already there (or employee is new).

Out-of-order events are handled because a late-arriving old event has an older `_de_source_datetime` - the `>=` check skips it and dim keeps the current row.

## Assumptions

- `stg_employee` is append-only; `ref('stg_employee')` runs upstream.
- `_de_ingested_datetime` is when the event landed in the warehouse (not in the sample SQL - I'd add it in ingestion).
- `_de_source_datetime` is the source event time; used for ordering and merge comparison.

## Audit columns

| Column | Behavior |
|--------|----------|
| `inserted_datetime` / `inserted_by` | Set on first insert; preserved on merge via `COALESCE` from existing row |
| `updated_datetime` / `updated_by` | Refreshed every run (`current_timestamp()`, `'dbt-etl'`) |

## Scale (1.6B events, 200K/day, 30-min refresh)

- **Staging** holds 1.6B events. **Dim** is one row per employee - large but much smaller than staging.
- Batch-only scans just the lookback window (~200K events/day spread across 30-min runs), not full history per employee.
- `CLUSTER BY (employee_id)` on staging and dim.
- 24h lookback is a starting point - tune after measuring max pipeline outage.

## With more time

- dbt unit test on the six sample events
- dbt tests: `unique` + `not_null` on `employee_id`
- Job health alert if dbt hasn't succeeded in > N hours
- Reconciliation job to ensure self-heal if dim drifts behind staging (e.g. dim stuck at event 2, staging has through event 5, nothing new in lookback)
