# Exercise 2 - expected output

Traced from `exercise_2/sample_data.sql` (full payloads). Partial hydration included in model per NFR but doesn't change this sample.

## `dim_employee_history`

| employee_id | full_name | department | salary | valid_from | valid_to | is_current |
|-------------|-----------|------------|--------|------------|----------|------------|
| 101 | Alice Johnson | Engineering | 75000 | 2024-01-10 09:00 | 2024-02-15 14:00 | false |
| 101 | Alice Johnson | Engineering | 85000 | 2024-02-15 14:00 | 2024-03-01 08:00 | false |
| 101 | Alice Johnson | Platform | 95000 | 2024-03-20 11:00 | null | true |
| 102 | Bob Smith | Sales | 65000 | 2024-01-12 10:00 | 2024-04-05 16:00 | false |
| 102 | Bob Smith | Marketing | 72000 | 2024-04-05 16:00 | null | true |

Gap for 101 between Mar 1 (delete) and Mar 20 (reactivation) - no row, which is intentional.

## Business answers

1. **101 salary over time** → 75000 → 85000 → (inactive gap) → 95000
2. **Active at end of 2024** → 101 and 102 (both have a current version before year-end)
3. **Alice's starting department** → Engineering
4. **102 salary on 2024-01-12 3 PM** → 65000 (created at 10 AM that day, no later change yet)
