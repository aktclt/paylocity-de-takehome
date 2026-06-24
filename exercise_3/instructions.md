## Exercise 3 - PR Review

A junior engineer just picked up a ticket "Create an SCD1 model for Employee Data", the requirements are the same as exercise 1a. They just submitted the following PR. Please review the SQL, pointing out potential issues, guidance or performance concerns.

You should keep all the same functional and non functional requirements of exercise 1a in mind.

You should point out any bugs, any standards that are not in place, any performance issues with the volume of data, etc.

## Assumptions

Assume `stg_employee` is another DBT model that needs to run before `dim_employee`. It just parses the JSON into a table format.

You can assume the columns in the SQL file are the **minimum** required.
