Comprehensive list of PostgreSQL's meta-commands (backslash commands)

# **User and DB based cmds**

| Action                 | Command                                           |
| ---------------------- | ------------------------------------------------- |
| **Login**              | `psql -U username -d dbname`                      |
| **Switch DB/User**     | `\c dbname username`                              |
| **Logout**             | `\q`                                              |
| **Create User**        | `CREATE USER username WITH PASSWORD 'pass';`      |
| **List Users**         | `\du`                                             |
| **Change Password**    | `\password username`                              |
| **Grant Permissions**  | `GRANT ALL ON DATABASE dbname TO username;`       |
| **Revoke Permissions** | `REVOKE DELETE ON TABLE tablename FROM username;` |
| **Delete User**        | `DROP USER username;`                             |

# Login or Connect

```sh
psql -U username -d database_name -h hostname -p port
```

- `-U`: Specify username
- `-d`: Specify database name
- `-h`: Specify host (default: `localhost`)
- `-p`: Specify port (default: `5432`)

**Inside `psql`, you can switch connections using:**

```sql
\c dbname username
```

Example:

```sql
\c mydb admin
```

---

# **Logout/Quit PostgreSQL**

```sql
\q
```

or press `Ctrl + D`.

These commands allow you to manage PostgreSQL users and sessions entirely from the `psql` client without writing full SQL queries. Let me know if you need more details! 🚀

# Connection Commands

- `\c` or `\connect` - Connect to a new database
- `\conninfo` - Display current connection information
- `\password [USERNAME]` - Change password for a user
- `\q` - Quit psql

# Informational Commands

- `\l` - List all databases
- `\l+` - List databases with more details
- `\dn` - List schemas
- `\dn+` - List schemas with more details
- `\dt` - List tables
- `\dt+` - List tables with more details
- `\di` - List indexes
- `\di+` - List indexes with more details
- `\dv` - List views
- `\dv+` - List views with more details
- `\ds` - List sequences
- `\ds+` - List sequences with more details
- `\df` - List functions
- `\df+` - List functions with more details
- `\dT` - List data types
- `\dT+` - List data types with more details
- `\du` - List roles
- `\du+` - List roles with more details
- `\d` - List tables, views, and sequences
- `\d+` - List with more details
- `\d NAME` - Describe table, view, sequence, or index
- `\d+ NAME` - Describe with more details
- `\da` - List aggregates
- `\da+` - List aggregates with more details
- `\db` - List tablespaces
- `\db+` - List tablespaces with more details
- `\dc` - List conversions
- `\dc+` - List conversions with more details
- `\dC` - List casts
- `\dD` - List domains
- `\dD+` - List domains with more details
- `\dd` - Show object descriptions
- `\ddp` - List default privileges
- `\dE` - List foreign tables
- `\des` - List foreign servers
- `\det` - List foreign tables
- `\deu` - List user mappings
- `\dew` - List foreign-data wrappers
- `\dx` - List extensions
- `\dx+` - List extensions with more details
- `\dy` - List event triggers
- `\dF` - List text search configurations
- `\dFd` - List text search dictionaries
- `\dFp` - List text search parsers
- `\dFt` - List text search templates

# **Getting Columns of a Table in PostgreSQL**

## **1. Using Meta-Commands (psql)**

### **List All Columns of a Table**

```sql
\d table_name
```

Example:

```sql
\d employees
```

**Output:**

```
                          Table "public.employees"
   Column   |         Type          | Collation | Nullable | Default
------------+-----------------------+-----------+----------+---------
 id         | integer               |           | not null |
 name       | character varying(50) |           | not null |
 salary     | numeric(10,2)         |           |          |
 hire_date  | date                  |           |          |
Indexes:
    "employees_pkey" PRIMARY KEY, btree (id)
```

### **Get More Detailed Column Info**

```sql
\d+ table_name
```

Example:

```sql
\d+ employees
```

**Output:** _(Includes storage, compression, and description)_

---

# **Using SQL Queries**

### **Method 1: `information_schema.columns` (Standard SQL)**

```sql
SELECT column_name, data_type, is_nullable, column_default
FROM information_schema.columns
WHERE table_name = 'table_name';
```

Example:

```sql
SELECT column_name, data_type, is_nullable, column_default
FROM information_schema.columns
WHERE table_name = 'employees';
```

**Output:**

```
 column_name |     data_type      | is_nullable | column_default
-------------+--------------------+-------------+----------------
 id          | integer            | NO          |
 name        | character varying  | NO          |
 salary      | numeric            | YES         |
 hire_date   | date               | YES         |
```

### **Method 3: `SELECT * FROM table LIMIT 0` (Quick Hack)**

Example:

```sql
SELECT * FROM employees LIMIT 0;
```

**Output:** _(Shows column names but no data)_
**Quick Hack** | `SELECT * FROM table_name LIMIT 0;` | Fast column name check |

# Formatting Commands

- `\a` - Toggle between unaligned and aligned output mode
- `\C [TITLE]` - Set table title
- `\f [STRING]` - Set field separator for unaligned output
- `\H` - Toggle HTML output mode
- `\pset NAME [VALUE]` - Set table output option
- `\t` - Toggle display of output column name and row count footer
- `\T [STRING]` - Set HTML <table> tag attributes
- `\x` - Toggle expanded output

# Input/Output Commands

- `\copy ...` - Perform SQL COPY with stdin/stdout
- `\echo [STRING]` - Write string to standard output
- `\i FILE` - Execute commands from file
- `\ir FILE` - Execute commands from file (relative to current script)
- `\o [FILE]` - Send all query results to file
- `\p` - Print current query buffer
- `\r` - Reset (clear) query buffer
- `\w FILE` - Write current query buffer to file

# Operating System Commands

- `\! [COMMAND]` - Execute command in shell or start interactive shell
- `\cd [DIR]` - Change current working directory
- `\setenv NAME [VALUE]` - Set or unset environment variable
- `\timing` - Toggle timing of commands

# Variables

- `\prompt [TEXT] NAME` - Prompt user to set variable
- `\set [NAME [VALUE]]` - Set internal variable
- `\unset NAME` - Unset (delete) internal variable

# Help Commands

- `\?` - Show help on psql commands
- `\h` - Show help on SQL commands
- `\h NAME` - Show help on specific SQL command

# Transaction Control

- `\echo` - Print text to output
- `\g` - Execute query (or send to file if \o is active)
- `\g [FILE]` - Execute query and send results to file
- `\gx` - Execute query with expanded output
- `\gset [PREFIX]` - Execute query and store results in variables
- `\watch [SEC]` - Execute query every SEC seconds

# Conditional

- `\if EXPR` - Begin conditional block
- `\elif EXPR` - Alternative conditional block
- `\else` - Final conditional block
- `\endif` - End conditional block

These commands are specific to the psql client and don't include actual SQL statements that would be sent to the PostgreSQL server.
