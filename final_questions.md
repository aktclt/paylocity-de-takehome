# Final questions

Short answers - assumptions are intentional; happy to go deeper in the follow-up session.

---

## 1. JSON payloads with different envelopes across source teams

Land raw JSON as-is (S3/Snowpipe/streaming > `VARIANT` column in Snowflake). Don't force one envelope upstream.

Per source team, a thin `stg_<team>_<entity>` model that:
- Parses their envelope (`resource.payload` vs `event_payload.<dynamic_key>`)
- Creates a **canonical event schema**: `entity_id`, `payload`, `event_type`, `source_ts`, `_de_ingested_datetime`
- Documents the envelope mapping in a config table or dbt YAML so new teams don't require core model changes

For dynamic keys like `<source_team_defined_key>`, use `OBJECT_KEYS()` or a team-specific mapping table - I'd push teams toward a stable key over time but won't block ingestion on it.

---

## 2. Standardizing phone numbers, addresses, etc.

**Medallion approach:** raw > staging > intermediate normalization > marts.

- Shared dbt macros or a `int_<field>_normalized` layer per domain (phone, address)
- Reference data where it helps (country codes, state abbreviations)
- `expect_column_values` / custom tests for regex and length
- Document accepted formats in a data contract, reject/quarantine rows that fail in staging rather than silently coercing

One canonical format in marts. Staging keeps the source value for audit.

---

## 3. Detecting missing changes before customers see them

Layered approach:

1. **Volume / freshness monitors** - expected row counts, max(`_de_ingested_datetime`) lag per source
2. **CDC completeness** - compare source change log counts to landed events
3. **Reconciliation jobs** - periodic hash/count compare between source snapshot and warehouse current state (sampled for large tables)
4. **Anomaly detection** on daily change volume per entity
5. **Quarantine + alert** rather than silently passing bad data to marts

When a source team misses changes, reconciliation catches drift before the report refresh. I'd start with freshness + daily reconciliation on high-value entities. Tools like Monte-Carlo can be helpful here.

---

## 4. Unified history across multiple SCD2 tables

Hard problem. Employee info and position history change on different cadences and keys.

Approaches:
- **Bridge / snapshot table** - periodic (daily/hourly) snapshot joining both dims at a point in time. Simple for reporting, not true event-level union.
- **Event bus canonical model** - normalize both sources into an `employee_lifecycle_events` stream, then build unified timeline.
- **Bi-temporal modeling** - track valid time + transaction time; powerful but heavy.

Complexities: different grains, overlapping validity windows, orphan position rows without employee match, late-arriving updates that reorder history, delete/rehire across both tables. I'd clarify with Product whether they need event-level union or periodic snapshots - snapshots ship faster.

---

## 5. Report keeps breaking - where to start

Triage before building:

1. **Classify the failure** - missing rows vs wrong values vs stale
2. **Trace lineage** - trace the flow source > staging > mart > report, find the first layer that's wrong
3. **Check freshness and volume** for that path on failure dates
4. **Talk to the source team** if it's CDC gaps (similar to Q3)
5. **Add tests at the mart** that would have caught this specific issue
6. **Stabilize, then prevent** - don't jump to re-architecture on the first incident

Start with one broken report and one failure mode. Fix the root cause, add one test, move on.

---

## 6. Queries suddenly slow - diagnosis and prevention

**Look at:**
- Snowflake query history (`QUERY_TAG`, user, warehouse) - new full scans? cartesian joins?
- Warehouse queuing / undersized warehouse
- New data volume without clustering changes
- Stats/cache invalidation after large loads
- BI tool change (lookback widened, filter removed)
- Recent deploy that changed join keys or dropped a filter

**Prevent customer impact:**
- Semantic layer / pre-aggregated marts for heavy reports
- Query timeouts and resource monitors on exploratory warehouses
- SLA dashboards on key report runtimes
- Clustering keys reviewed when tables grow rapidly
- Separate warehouses for ETL vs BI

---

## 7. What breaks first incrementally loading 1.6B rows (patterns from these exercises)

**Correctness first:** lookback window too small > late events missed, silent wrong answers.

**Then performance:**
1. Staging scan cost - even "affected employee" queries get expensive without `employee_id` clustering
2. Merge contention / long transactions on the dim during 30-min schedule overlap
3. Warehouse queuing when incremental job competes with BI
4. dbt merge generating wide scans on the 1.6B staging table if lookback logic is wrong

I'd monitor staging bytes scanned per incremental run before optimizing the merge itself.

---

## 8. Snowflake costs spike 3x - where to look first

1. **Query history** - top queries by credits last 7 days vs baseline, new queries showing up?
2. **Warehouse auto-suspend** - warehouses left running or scaled up?
3. **Large full-refresh jobs** - someone `--full-refresh` a big model?
4. **Storage** - Time Travel / Fail-safe growth, new large tables
5. **Serverless** - search optimization, automatic clustering, materialized views, Snowpipe
6. **Replication / sharing** egress

Usually it's a warehouse left on or a new full-scan query. I check query history and top queries before storage.

---

## 9. Validate correctness without full table scans

- **Aggregate checks** - `COUNT`, `SUM`, `COUNT DISTINCT` on keys vs source or prior run
- **Change-window validation** - only compare rows where `_de_ingested_datetime > last_watermark`
- **dbt tests** - uniqueness, not-null, relationships, accepted values on incremental batches
- **Cross-table reconciliation** - mart totals vs staging totals for the same filter
- **Source-provided control files** - row counts and checksums per batch

Full scan is a last resort. Most drift shows up in counts and key-level samples.

---

## 10. Near real-time - data needs

| Layer | Batch today | Near real-time |
|-------|-------------|----------------|
| Ingestion | Hourly/batch files | Streaming (Snowpipe Streaming, Kafka, SF Streams) |
| Staging | Append batch | Stream on landing table to micro-batch task |
| Transform | dbt every 30 min | Snowflake Task every 1-5 min on stream, or incremental merge triggered by stream |
| Serving | Dimension merge | Same merge logic, smaller batches. Consider maintaining current-state in task, dbt for validation |
| SLAs / ops | Daily checks | Lag alerts on minutes, idempotent merge, duplicate handling |

Core SQL patterns (latest event, SCD2 boundaries) stay similar - what changes is orchestration, ingestion, and how aggressively you incrementalize. I'd also separate a **hot path** (current state for product) from **cold path** (history, heavy tests).
