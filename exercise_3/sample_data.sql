-- Sample event stream for the employee entity
-- Events arrive in this order from the source system
-- Business key: employee_id

-- Event #1: Employee 101 created
SELECT
    101 AS employee_id,
    'Alice Johnson' AS full_name,
    'Engineering' AS department,
    75000 AS salary,
    'create' AS _de_source_operation,
    '2024-01-10 09:00:00.000000 +0000'::TIMESTAMP_LTZ AS _de_source_datetime
UNION ALL

-- Event #2: Employee 102 created
SELECT
    102 AS employee_id,
    'Bob Smith' AS full_name,
    'Sales' AS department,
    65000 AS salary,
    'create' AS _de_source_operation,
    '2024-01-12 10:00:00.000000 +0000'::TIMESTAMP_LTZ AS _de_source_datetime
UNION ALL

-- Event #3: Employee 101 gets a raise (update)
SELECT
    101 AS employee_id,
    'Alice Johnson' AS full_name,
    'Engineering' AS department,
    85000 AS salary,
    'update' AS _de_source_operation,
    '2024-02-15 14:00:00.000000 +0000'::TIMESTAMP_LTZ AS _de_source_datetime
UNION ALL

-- Event #4: Employee 101 is deleted
SELECT
    101 AS employee_id,
    'Alice Johnson' AS full_name,
    'Engineering' AS department,
    85000 AS salary,
    'delete' AS _de_source_operation,
    '2024-03-01 08:00:00.000000 +0000'::TIMESTAMP_LTZ AS _de_source_datetime
UNION ALL
-- Event #5: Employee 101 re-activated with a new department (update after delete)
SELECT
    101 AS employee_id,
    'Alice Johnson' AS full_name,
    'Platform' AS department,
    95000 AS salary,
    'update' AS _de_source_operation,
    '2024-03-20 11:00:00.000000 +0000'::TIMESTAMP_LTZ AS _de_source_datetime
UNION ALL
-- Event #6: Employee 102 changes department (update)
SELECT
    102 AS employee_id,
    'Bob Smith' AS full_name,
    'Marketing' AS department,
    72000 AS salary,
    'update' AS _de_source_operation,
    '2024-04-05 16:00:00.000000 +0000'::TIMESTAMP_LTZ AS _de_source_datetime
