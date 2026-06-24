{{ config(
    materialized='incremental',
    unique_key='employee_id',
    incremental_strategy='merge',
    cluster_by=['employee_id']
) }}

-- SCD1 with partial event hydration. Delta from exercise_1a - see APPROACH.md for details.

{% set lookback_hours = 24 %}

with

{% if is_incremental() %}
source_events as (
    select *
    from {{ ref('stg_employee') }}
    where _de_ingested_datetime >= dateadd(hour, -{{ lookback_hours }}, current_timestamp())
),
{% else %}
source_events as (
    select *
    from {{ ref('stg_employee') }}
),
{% endif %}

hydrated_events as (
    -- NULL in an update/delete means "field did not change", not "field is blank"
    select
        employee_id,
        _de_source_operation,
        _de_source_datetime,
        _de_ingested_datetime,
        last_value(full_name ignore nulls) over w as full_name,
        last_value(department ignore nulls) over w as department,
        last_value(salary ignore nulls) over w as salary
    from source_events
    window w as (
        partition by employee_id
        order by _de_source_datetime, _de_ingested_datetime
        rows between unbounded preceding and current row
    )
),

deduped_events as (
    select *
    from hydrated_events
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

batch_latest as (
    select
        employee_id,
        full_name,
        department,
        salary,
        _de_source_operation as last_source_operation,
        _de_source_datetime as last_source_datetime,
        case
            when _de_source_operation in ('create', 'update') then true
            else false
        end as is_active
    from deduped_events
    qualify row_number() over (
        partition by employee_id
        order by _de_source_datetime desc, _de_ingested_datetime desc
    ) = 1
)

select
    bl.employee_id,
    bl.full_name,
    bl.department,
    bl.salary,
    bl.is_active,
    bl.last_source_operation,
    bl.last_source_datetime,
    {% if is_incremental() %}
    coalesce(existing.inserted_datetime, current_timestamp()) as inserted_datetime,
    coalesce(existing.inserted_by, 'dbt-etl') as inserted_by,
    {% else %}
    current_timestamp() as inserted_datetime,
    'dbt-etl' as inserted_by,
    {% endif %}
    current_timestamp() as updated_datetime,
    'dbt-etl' as updated_by
from batch_latest as bl
{% if is_incremental() %}
left join {{ this }} as existing
    on bl.employee_id = existing.employee_id
where existing.employee_id is null
    or bl.last_source_datetime >= existing.last_source_datetime
{% endif %}
