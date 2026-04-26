# Library Management System

This project focuses on designing and implementing SQL functions to manage the daily operations of a library.

It aims to demonstrate database design, data manipulation, and procedural logic using PostgreSQL, with an emphasis on real-world use cases such as catalog management, borrowing processes, and data integrity.

## Overview

The project covers:

* Database initialization and schema creation
* Data insertion for testing scenarios
* Implementation of custom SQL functions
* Validation through structured test scripts

It provides a practical approach to working with relational databases and server-side logic.

## Getting Started

Below is an example workflow to set up and run the project:

```bash
$ ls
README.md  ressources  scripts

$ sudo -u postgres psql
psql (14.9)
Type "help" for help.

# Create and connect to the database
postgres=# create database biblio_traore;
postgres=# \c biblio_traore

# Initialize schema and data
postgres=# \i ./ressources/bibliotheque.sql
postgres=# \i ./ressources/insert-bibliotheque.sql

# Create custom functions
postgres=# \i ./scripts/mesFctsBiblio.sql

# Run test suite
postgres=# \i ./scripts/testMesFctsBiblio.sql
```

## Tech Stack

* [SQL](https://sql.sh/) — Query language for database operations
* [PostgreSQL](https://www.postgresql.org/) — Relational database management system
* [psql](https://docs.postgresql.fr/13/app-psql.html) — Command-line interface for PostgreSQL
