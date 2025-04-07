# DMDD Group 02 – P5 SQL Scripts

This repository contains the SQL scripts needed to set up and manage the project database. *It is crucial to execute the scripts in the order specified below* to avoid dependency issues.

## Execution Order

1. *DDL Commands:*  
   - *File(s):* create_tables.sql  
   - *Action:* Creates the database schema (tables, relationships, constraints).

2. *Insert Commands:*  
   - *File(s):* insert_script.sql  
   - *Action:* Inserts initial data into the tables.

3. *Encryption:*  
   - *File(s):* encryption_script.sql  
   - *Action:* Implements encryption for sensitive data.

4. *Non-Clustered Indexes:*  
   - *File(s):* indexes_script.sql  
   - *Action:* Creates non-clustered indexes to optimize performance.

5. *User-Defined Functions (UDF):*  
   - *File(s):* psm_script.sql  
   - *Action:* Defines custom functions for data processing.

6. *Views:*  
   - *File(s):* psm_script.sql  
   - *Action:* Creates views for simplified data retrieval.

7. *Triggers:*  
   - *File(s):* psm_script.sql  
   - *Action:* Sets up triggers to automate tasks upon data changes.

8. *Stored Procedures:*  
   - *File(s):* psm_script.sql  
   - *Action:* Defines stored procedures to encapsulate business logic.