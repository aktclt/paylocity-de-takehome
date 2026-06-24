# Exercise 1a - expected output

## Table output for `dim_employee` will look like below:

| employee_id | full_name | department | salary | is_active | last_source_operation | last_source_datetime |
|-------------|-----------|------------|--------|-----------|----------------------|----------------------|
| 101 | Alice Johnson | Platform | 95000 | true | update | 2024-03-20 11:00 +0000 |
| 102 | Bob Smith | Marketing | 72000 | true | update | 2024-04-05 16:00 +0000 |

Audit columns (`inserted_datetime`, `inserted_by`, `updated_datetime`, `updated_by`) depend on run time - omitted here.

## Business answers

1. Employee 102 salary → **72000**
2. Active employees → **101, 102**
3. Highest salary → **101 at 95000**
