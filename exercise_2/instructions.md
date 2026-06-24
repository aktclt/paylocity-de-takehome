# Exercise 2

## Functional Requirements

The business wants to ask the following questions about employee data

1. What is the change in salary over time of Employee 101?
2. Give me all active employees at the end of 2024.
3. What department was Alice in when she started?
4. What was 102's Salary on 2024-01-12 at 3 PM?

They indicated they want the full history of the employee over time.

Write SQL to transform the sample data into a Snowflake table in order to answer the above questions. 

DBT macros and functions can be used where it seems appropriate.

Please come prepared with what the table output would look like based on the sample data provided

The **minimum** columns must be: `employee_id`, `full_name`, `department`, `salary`

## Non Functional Requirements

- Total volume is 1.6B records with ~200K coming in per day.
- Table must be updated every 30 minutes with new data for the business to see.
- Some updates are partial and only update a single field in a row (e.g. department but not salary)
- There may be multiple updates with the same timestamp
