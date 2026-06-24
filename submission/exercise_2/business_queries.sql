-- Business questions from the exercise. Run against dim_employee_history.

-- 1) Salary change over time for employee 101
select
    employee_id,
    valid_from,
    valid_to,
    salary
from dim_employee_history
where employee_id = 101
order by valid_from;

-- 2) Active employees at end of 2024
select distinct
    employee_id,
    full_name,
    department,
    salary
from dim_employee_history
where valid_from <= '2024-12-31 23:59:59'::timestamp_ltz
    and (valid_to > '2024-12-31 23:59:59'::timestamp_ltz or valid_to is null)
    and is_active
order by employee_id;

-- 3) Department Alice was in when she started
select department
from dim_employee_history
where employee_id = 101
qualify row_number() over (order by valid_from) = 1;

-- 4) Employee 102's salary on 2024-01-12 at 3 PM
select salary
from dim_employee_history
where employee_id = 102
    and valid_from <= '2024-01-12 15:00:00'::timestamp_ltz
    and (valid_to > '2024-01-12 15:00:00'::timestamp_ltz or valid_to is null);
