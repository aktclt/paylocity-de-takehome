{{ config(
    materialized="incremental",
    unique_key="employee_id"
) }}

WITH prepared_columns AS (
    SELECT
        employee_id,
        full_name,
        department,
        salary,
        _de_source_operation,
        _de_source_datetime,
        MD5(UPPER(full_name) || UPPER(department) || salary) as _de_record_hash
    FROM {{ source('stg_employee') }}
),
prepared_deduped AS (
    SELECT
        employee_id,
        full_name,
        department,
        salary,
        _de_source_operation,
        _de_source_datetime,
        _de_record_hash
    FROM prepared_columns
    QUALIFY ROW_NUMBER() OVER (
        PARTITION BY employee_id, _de_source_operation
        ORDER BY _de_source_datetime DESC
    ) = 1
)
{% if is_incremental() %}
,
target_table AS (
    SELECT
        employee_id,
        _de_source_datetime,
        _de_is_current
    FROM {{ this }}
),
joined_data AS (
    SELECT
        employee_id,
        full_name,
        department,
        salary,
        _de_source_operation,
        _de_source_datetime,
        _de_record_hash
    FROM prepared_deduped AS source
        LEFT JOIN target_data AS target
        ON source.employee_id = target.employee_id
    WHERE source._de_record_hash IS NOT NULL
)
{% endif %}
SELECT
    employee_id,
    full_name,
    department,
    salary,
    _de_source_operation,
    _de_source_datetime,
    _de_record_hash
{% if is_incremental() %}
    FROM joined_data
{% else %}
    FROM prepared_deduped
{% endif %}
