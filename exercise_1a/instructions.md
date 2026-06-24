# Exercise 1a

## Functional Requirements

The business wants to ask the following questions about employee data

1. What is the salary of employee 102.
2. Give me all active employees.
3. Show me who has the highest Salary.

They indicated they only care about the latest state of the employee.

Write SQL to transform the sample data into a Snowflake table in order to answer the above questions. 

DBT macros and functions can be used where it seems appropriate.

Please come prepared with what the table output would look like based on the sample data provided

The **minimum** columns must be: `employee_id`, `full_name`, `department`, `salary`

## Non Functional Requirements

- Total volume is 1.6B records with ~200K coming in per day.
- Table must be updated every 30 minutes with new data for the business to see.
- Records can arrive out of order
- The same update can be received more than once
- We do not want to hard-delete any employees but they can be marked inactive
