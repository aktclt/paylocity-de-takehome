-- Business questions from the prompt. Run against dim_employee.

-- 1) Salary of employee 102
select salary
from dim_employee
where employee_id = 102;

-- 2) Active employees
select employee_id, full_name, department, salary
from dim_employee
where is_active = true
order by employee_id;

-- 3) Highest salary among employees
select employee_id, full_name, department, salary
from dim_employee
-- where is_active = true -- If business wants from only active employees
qualify row_number() over (order by salary desc, employee_id) = 1;
