{{ config(
    materialized='incremental',
    unique_key='scd2_key',
    incremental_strategy='delete+insert',
    cluster_by=['employee_id']
) }}

-- SCD2 employee history. See APPROACH.md.

{% set lookback_hours = 24 %}

with

{% if is_incremental() %}
recently_touched as (
    select distinct employee_id
    from {{ ref('stg_employee') }}
    where _de_ingested_datetime >= dateadd(hour, -{{ lookback_hours }}, current_timestamp())
),

source_events as (
    select e.*
    from {{ ref('stg_employee') }} as e
    inner join recently_touched as t
        on e.employee_id = t.employee_id
),
{% else %}
source_events as (
    select *
    from {{ ref('stg_employee') }}
),
{% endif %}

deduped_events as (
    select *
    from source_events
    qualify row_number() over (
        partition by
            employee_id,
            _de_source_datetime,
            _de_source_operation,
            coalesce(full_name, '~'),
            coalesce(department, '~'),
            coalesce(salary, -1)
        order by _de_ingested_datetime desc
    ) = 1
),

hydrated_events as (
    select
        employee_id,
        _de_source_operation,
        _de_source_datetime,
        _de_ingested_datetime,
        last_value(full_name ignore nulls) over w as full_name,
        last_value(department ignore nulls) over w as department,
        last_value(salary ignore nulls) over w as salary
    from deduped_events
    window w as (
        partition by employee_id
        order by _de_source_datetime, _de_ingested_datetime
        rows between unbounded preceding and current row
    )
),

ordered_events as (
    select
        *,
        row_number() over (
            partition by employee_id
            order by
                _de_source_datetime,
                -- same-timestamp tie-break - see APPROACH.md
                case _de_source_operation
                    when 'delete' then 1
                    when 'update' then 2
                    when 'create' then 3
                    else 4
                end,
                _de_ingested_datetime
        ) as event_seq,
        md5(concat_ws('|',
            coalesce(full_name, ''),
            coalesce(department, ''),
            coalesce(salary::varchar, '')
        )) as attr_hash
    from hydrated_events
),

marked_events as (
    select
        *,
        lag(attr_hash) over (
            partition by employee_id order by event_seq
        ) as prev_attr_hash,
        lag(_de_source_operation) over (
            partition by employee_id order by event_seq
        ) as prev_operation,
        case
            when _de_source_operation = 'delete' then 'close'
            when event_seq = 1 then 'open'
            when attr_hash is distinct from lag(attr_hash) over (
                partition by employee_id order by event_seq
            ) then 'open'
            when lag(_de_source_operation) over (
                partition by employee_id order by event_seq
            ) = 'delete' then 'open'
        end as scd_action
    from ordered_events
),

boundaries as (
    select
        employee_id,
        event_seq,
        _de_source_datetime as boundary_ts
    from marked_events
    where scd_action in ('open', 'close')
),

version_starts as (
    select
        employee_id,
        full_name,
        department,
        salary,
        _de_source_datetime as valid_from,
        event_seq
    from marked_events
    where scd_action = 'open'
),

scd2_rows as (
    select
        v.employee_id,
        v.full_name,
        v.department,
        v.salary,
        v.valid_from,
        (
            select min(b.boundary_ts)
            from boundaries as b
            where b.employee_id = v.employee_id
                and b.event_seq > v.event_seq
        ) as valid_to
    from version_starts as v
)

select
    md5(employee_id::varchar || '|' || valid_from::varchar) as scd2_key,
    employee_id,
    full_name,
    department,
    salary,
    valid_from,
    valid_to,
    valid_to is null as is_current,
    valid_to is null as is_active,
    current_timestamp() as inserted_datetime,
    'dbt-etl' as inserted_by,
    current_timestamp() as updated_datetime,
    'dbt-etl' as updated_by
from scd2_rows
