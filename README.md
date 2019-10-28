# Audit Trigger

A simple, customizable table audit system for PostgreSQL implemented using
triggers.

Uses changes from 2ndQuadrant/audit-trigger/pull/32 to use json instead of hstore. 

## How to use

1. Run `audit.sql` file on database
2. Run `SELECT audit.audit_table('table_name')` to begin auditing a table


> Note: If inserts are taking too long, you can try to run the `audit.trim_table()` function to remove 
