# Data Engineering Take Home - 90 Minutes

This is a take home assignment. Assume you are a Data Engineer with the following stack:

- DBT for transformations
- Snowflake for a Data Warehouse

## Exercises

There are 3 exercises which have both a business ask and
multiple follow up questions. You are expected to solve these how you see best, 
and present it to the team. In which you will have 90 minutes and be probed with questions.

Exercise 1 & 2 you will be writing SQL to answer business questions given sample data.
These have both functional and non functional requirements.

In these exercises you should really think about the SQL you are writing, and also how it impact the final table. Things like performance, standards, how this join into on a fact etc.

Exercise 3 you are tasked with a PR review of a junior engineer. 
There is both sample data and the SQL the engineer committed. Review it for accuracy, standards and performance.

Complete these now.

## Final questions

After completing the exercises. 
Here are more general issues that your team has run into, please provide your approach to solve each one.

1. Source teams now send data in JSON format where each payload is a new record, and different teams may have different payload envelopes. How would you handle this? Example let's say you receive some data in JSON that follows this format for one source team:

```json
{
    "resource": {
        "payload": {...}
    }
}
```

Compared to this from another where the envelope is different and the source team controls the key in which the JSON payload is present in.

```json
{
    "event_version": "v2",
    "event_payload": {
        "unique_key": 123,
        "<source_team_defined_key>": { ... }
    }
}
```

2. Different source teams store certain things, such as phone numbers, addresses, etc. In different formats. How would you make sure that our models all adhere to a specific format?

3. Customers keep reporting that missing rows are showing up in various reports. It always stems from a source team issue not sending changes. How would you go about detecting these sorts of issues before they reach the customer?

4. Product wants to see a fully unified history of multiple SCD2 tables (E.G Employee Info history + Position History) in one unified report. How would you approach this? What are the complexities?

5. A particular report keeps having data issues (records missing, incorrect values, stale data). You were assigned to reduce these data issues, where do you start?

6. Customers report that queries are taking much longer than normal. What do you look at to identify the problem? How would you prevent this impacting the customer in the future?

7. What breaks first when incrementally loading a large amount of data into a 1.6B row table using the patterns in these exercises?

8. If Snowflake costs spike 3x, where do you look first to identify the cause?

9. How would you validate data correctness without doing full table scans?

10. If Product now wants near real-time updates to the data, what changes have to be made?
