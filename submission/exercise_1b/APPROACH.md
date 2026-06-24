# Exercise 1b - extension from 1a

Same model shape and incremental pattern as 1a. One addition: **hydrate partial events before dedupe/latest-event logic**.

## What changed in the source

Updates and deletes now arrive sparse - unchanged fields are `NULL`, not repeated. Deletes may only carry `employee_id`.

## What changed in the model

Insert a `hydrated_events` CTE between `source_events` and `deduped_events` to bring the missing values from the previous event row.

`NULL` means *unchanged*, not *cleared*. `is_active` still comes from the operation on the latest hydrated event.

## Key output difference vs 1a

Event 6 for employee 102 only updates `department`. Salary stays **65000** (not 72000 like the full-payload sample in 1a).
