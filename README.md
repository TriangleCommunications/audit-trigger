# Audit Trigger

A simple, customizable table audit system for PostgreSQL implemented using
triggers. This repo has the following changes:

* Merged with [/pull/32](https://github.com/2ndQuadrant/audit-trigger/pull/32) to use json instead of hstore
* Added script for use with PostGIS to convert GeoJSON back into WKB

> PostGIS 3.0 now [automatically converts geometry into GeoJSON](https://gis.stackexchange.com/a/343343/120481). We did not want that, so we created a script that automatically converts GeoJSON back into WKB.

## How to use

1. Install the auditing schema with the following command:
```sh
psql -h <host> -p <port> -U <user> -d <db> -f audit.sql --single-transaction
```

2. If auditing tables with PostGIS (3.0+) geometry, run the following command:
```sh
psql -h <host> -p <port> -U <user> -d <db> -f audit-postgis.sql --single-transaction
```

3. Run `SELECT audit.audit_table('schema.table')` to begin auditing a table

> Note: If inserts are taking too long, you can try to run the `audit.trim_table()` function to remove any audit logs older than one year

## Customization

The `audit.audit_table` function allows the user to pass various options to customize the behavior:

| argument | type | default | |
| --- | --- | --- | --- |
| `target_table` | regclass | | Table name, schema qualified if not on search_path |
| `audit_rows` | bool | True | Record each row change, or only audit at a statement level |
| `audit_query_text` | bool | True | Record the text of the client query that triggered the audit event? |
| `ignored_cols` | text[] | [] | Columns to exclude from update diffs, ignore updates that change only ignored cols. |

If using Postgres 9.5 or a similar older version, I have modified the audit script to work with that. You can find it on the [9.5 branch](https://github.com/TriangleCommunications/audit-trigger/tree/9.5).
