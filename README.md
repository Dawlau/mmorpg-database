# MMORPG Database

This is a relational database prototype that can be further used for MMORPG games development.

The languages used for this projects are Python and SQL.

Note: This project has been specifically designed for Oracle databases.

## Features

This project has 3 main parts: the database schemas, the scripts used to generate SQL inserts for database population and the SQL features for database interaction.

### Schemas

These can be found in the Schemas directory which contains the ERD and Conceptual diagrams.
In the Contents folder you can find the data used by the scripts for generating SQL inserts.

### Scripts for generating SQL inserts

In the genScripts directory you can find the Python scripts used for populating the database. There are 2 scripts, one for generating the data for many-to-many tables and one for generating the SQL insert statements.

### SQL features

The createDB and sqlInsert files contain statements for creating and populating the database. In the dbInteraction file you can find stored functions and procedures, triggers and packages that facilitate an easier interaction with the database. There is a detailed description for each item in the dbInteraction file.

## Final notes

I hope you find this prototype useful. If you find any bugs, feel free to submit them to blahoviciandrei1@gmail.com
