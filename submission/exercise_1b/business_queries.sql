-- Same business questions as 1a. Expected answers differ for employee 102 salary - see expected_output.md.

select salary 
from dim_employee
where employee_id = 102;

select employee_id, full_name, department, salary
from dim_employee
where is_active = true
order by employee_id;

select employee_id, full_name, department, salary
from dim_employee
where is_active = true -- If business wants from only active employees
qualify row_number() over (order by salary desc, employee_id) = 1;
