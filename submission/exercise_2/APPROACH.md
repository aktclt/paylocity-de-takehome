# Exercise 2 - approach

## How to track history

SCD Type 2 dimension: full attribute history with `valid_from` / `valid_to`. Facts and dims join on `employee_id` + point-in-time (`event_ts between valid_from and coalesce(valid_to, '9999-12-31')`).

## Logic

Same staging prep as 1a/1b (dedupe, hydrate partials), then:

1. Walk events in order per employee.
2. **Open** a new version when: first event, attributes change, or reactivation after delete.
3. **Close** on delete - no new version row just end the current period.
4. `valid_to` = timestamp of the next open or close boundary.

Delete handling is the tricky part. Alice disappears from Mar 1-Mar 20, she doesn't have a "deleted" row with stale attributes - there's simply a gap.

## Incremental strategy

`delete+insert` on `scd2_key` (= hash of `employee_id` + `valid_from`). Each run re-derives **all** versions for employees touched in the lookback window, replaces their keys, leaves everyone else alone.

That's heavier than row-by-row merge but much easier to reason about when versions can shift after late-arriving events. I'd start here; optimize if profiling says we need to.

## Timestamp collisions

Exercise 2 NFR: *"There may be multiple updates with the same timestamp."* Sample data doesn't hit this - all timestamps are unique.

When they do collide, `ordered_events` breaks ties deterministically:

1. `_de_source_datetime` - business time
2. **Operation precedence** (ascending): `delete`, then `update`, then `create`
3. `_de_ingested_datetime` - ingest order

```sql
order by
    _de_source_datetime,
    case _de_source_operation
        when 'delete' then 1
        when 'update' then 2
        when 'create' then 3
        else 4
    end,
    _de_ingested_datetime
```

Delete before update at the same clock tick means we close the current version before opening a new one. 

## Joining to facts

```sql
from fact_payroll f
join dim_employee_history d
  on f.employee_id = d.employee_id
 and f.payroll_ts >= d.valid_from
 and f.payroll_ts < coalesce(d.valid_to, '9999-12-31'::timestamp_ltz)
```

For current-state only, filter `is_current` - but most payroll facts need the point-in-time join above.


## With more time

- dbt snapshot as an alternative if source CDC is reliable
- Integration test: six sample events > five history rows
- Surrogate `employee_sk` if multiple source systems feed the same dim
