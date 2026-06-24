{{ config(
    materialized='incremental',
    unique_key='employee_id',
    incremental_strategy='merge',
    cluster_by=['employee_id']
) }}

-- SCD1: one row per employee, latest event wins.
-- Incremental: process lookback window only; merge if batch event is newer than dim.
-- See APPROACH.md ("With more time") for optional reconciliation job.

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

deduped_events as (
    select *
    from source_events
    qualify row_number() over (
        partition by
            employee_id,
            _de_source_datetime,
            _de_source_operation,
            coalesce(full_name, '~'), -- Using '~' as placeholder for null values
            coalesce(department, '~'), -- Using '~' as placeholder for null values
            coalesce(salary, -1) -- Using -1 as placeholder for null values
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
