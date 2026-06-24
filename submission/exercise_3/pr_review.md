# Exercise 3 - PR review

Reviewing `exercise_3/dim_employee.sql` against Exercise 1a requirements (SCD1, same NFRs). Ordered the way I'd leave comments on a real PR: correctness first, then standards, then scale.

---

## Blockers (won't compile or wrong result)

### 1. `target_data` doesn't exist - typo for `target_table`

```sql
LEFT JOIN target_data AS target   -- CTE is named target_table
```

dbt compile will fail here.

### 2. `source('stg_employee')` should be `ref('stg_employee')`

Per the prompt, `stg_employee` is a dbt model upstream. `source()` is for raw landing tables.

### 3. No "latest event per employee" logic

After dedupe the model still emits multiple rows per `employee_id`. SCD1 needs exactly one current row. Missing:

```sql
qualify row_number() over (
    partition by employee_id
    order by _de_source_datetime desc, ...
) = 1
```

### 4. Dedupe partition is wrong

```sql
partition by employee_id, _de_source_operation
```

An employee can have many `update` events. This keeps one row per operation **type**, not one row per employee. Events 3, 4, 5 for employee 101 would collapse incorrectly.

Dedupe should target exact redeliveries (employee + timestamp + operation + payload hash), not operation type.

### 5. No soft-delete handling

NFR: don't hard-delete but mark inactive. Model passes `delete` through with no `is_active` column. Business question #2 ("active employees") can't be answered correctly.

### 6. Incremental branch doesn't merge

`joined_data` reads from target but never uses it - no timestamp comparison, no `COALESCE` of attributes, no `is_active` derivation. The incremental path is incomplete scaffolding.

### 7. `_de_record_hash is not null` drops valid rows

Would filter out any event with null attributes - exactly what Exercise 1b sends on partial updates.

---

## Standards / maintainability

| Issue | Notes |
|-------|-------|
| Hash without delimiters | `MD5(UPPER(full_name) \|\| UPPER(department) \|\| salary)` can collide across field boundaries. Prefer `MD5(CONCAT_WS('\|', ...))` or `HASH(*)`. |
| Hash omits `employee_id` | Low collision risk but sloppy; include business key. |
| `_de_is_current` in target CTE | Never defined in model output. |
| No audit columns | Add `updated_datetime`, `updated_by` at minimum, optionally preserve `inserted_*` on merge. |
| No tests | At least a unit test on the six sample events > two rows. |
| No comments on tie-breaking | Same-timestamp events need a documented order. |

---

## Performance (1.6B events, 200K/day, 30-min SLA)

1. **Full scan of staging every run** - no `_de_ingested_datetime` lookback filter on incremental.
2. **No clustering** - add `cluster_by=['employee_id']` on staging and dim.
3. **`unique_key` merge without one-row-per-key guarantee** - merge behavior is undefined when source returns multiple rows per `employee_id`.
4. **No merge guard** - even with a lookback, need `WHERE batch.last_source_datetime >= dim.last_source_datetime` (or equivalent) so late old events don't overwrite newer dim state incorrectly.

---

## Suggested direction (not a full rewrite)

Point the engineer at the 1a solution pattern:

1. `ref('stg_employee')` with `_de_ingested_datetime` lookback - process **batch events only** (not full history per employee)
2. Dedupe redeliveries; hydrate partials if needed (1b)
3. `QUALIFY ROW_NUMBER()` for latest event per employee in the batch, also handle deletes i.e. `is_active = false`
4. Merge on `employee_id` only when batch `last_source_datetime >=` dim (or new key), with audit columns
5. Daily **reconciliation** - compare staging `max(_de_source_datetime)` to dim; backfill any drifted `employee_id`s (optional)
6. Add unit tests

---

## Summary for the review session

The PR reads like an incremental merge was started but SCD1 semantics weren't finished. Biggest issues: won't compile (`target_data`), wrong dedupe grain, multiple rows per employee, no soft delete. I'd request changes before merge, not nits-only approval.
