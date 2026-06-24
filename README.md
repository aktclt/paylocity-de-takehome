# paylocity-de-takehome

Staff Data Engineer take-home - Ashish

Tech Stack: **dbt + Snowflake**

## How to read this repo

| Path | What it is |
|------|------------|
| `exercise_xx/` | Original prompts and sample data |
| `submission/exercise_xx/` | My solutions |
| `final_questions.md` | System design answers (Q1-Q10) |

Each solution folder has an approach note, business query SQL, dbt model (for NFRs), and expected output where applicable. Exercise 3 is a PR review only.

## Assumptions

Where the prompt is unclear, I made following assumptions:

1. **`stg_employee`** - is an append-only staging table (`ref('stg_employee')`) that stores parsed JSON upstream.
2. **`_de_ingested_datetime`** - event arrival timestamp on each event. This is not in the sample data; I'd add it in ingestion. Used for incremental lookback (out-of-order events). **`_de_source_datetime`** stays the source event time for ordering.
3. **Soft delete** - `delete` sets `is_active = false` and row stays. Reactivation happens when non-delete event later with newer source timestamp arrives.
4. **Active employee** - `is_active = true` on the current record.
5. **1.6B rows** - event volume in staging, not dimension row count.
6. **Exercise 1b** - `NULL` in partial updates means *unchanged*. Extension of 1a.
7. **Audit columns** - `inserted_datetime` / `inserted_by` preserved on merge. `updated_datetime` / `updated_by` refreshed on each run.
8. **Q3 highest salary (1a)** - prompt doesn't say active-only. My sample query includes a commented `where is_active` option.
