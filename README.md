# Musoq CLI Cookbook

[![GitHub license](https://img.shields.io/badge/license-MIT-blue.svg)](https://github.com/Puchaczov/Musoq.CLI/blob/main/LICENSE)

Musoq.CLI is a powerful command-line interface that brings the magic of [Musoq](https://github.com/Puchaczov/Musoq) to your fingertips. Query various data sources with ease, wherever they reside!

## 🌟 Features

- 🖥️ Spin up a Musoq server
- 🔍 Query diverse data sources
- 🔄 Seamless server-client interaction
- 📊 Multiple output formats (Raw, CSV, JSON, Interpreted JSON, Yaml, Interpreted Yaml)
- 🚫 No additional dependencies required

## 🚀 Easy Install / Update / Remove

### Install / Update

Powershell:

```powershell
irm https://raw.githubusercontent.com/Puchaczov/Musoq.CLI/refs/heads/main/scripts/powershell/install.ps1 | iex
```

Shell using curl:

```shell
curl -fsSL https://raw.githubusercontent.com/Puchaczov/Musoq.CLI/refs/heads/main/scripts/bash/install.sh | sudo bash
```

Shell using wget:

```shell
wget -qO- https://raw.githubusercontent.com/Puchaczov/Musoq.CLI/refs/heads/main/scripts/bash/install.sh | sudo bash
```

### Remove

Powershell:

```powershell
irm https://raw.githubusercontent.com/Puchaczov/Musoq.CLI/refs/heads/main/scripts/powershell/remove.ps1 | iex
```

Shell using curl:

```shell
curl -fsSL https://raw.githubusercontent.com/Puchaczov/Musoq.CLI/refs/heads/main/scripts/bash/remove.sh | sudo bash
```

Shell using wget:

```shell
wget -qO- https://raw.githubusercontent.com/Puchaczov/Musoq.CLI/refs/heads/main/scripts/bash/remove.sh | sudo sh
```

## 🏃 Quick Start

### With Server In Background

1. 📥 Install Musoq.CLI using the easy installation script above
2. 🖥️ Open any terminal
3. 🏃‍♂️ Run the server in background:
   - Windows & Linux: `Musoq serve`
4. 🔍 Run queries as needed
5. 🛑 To quit the server: `Musoq quit`

### With Server In Foreground

1. 📥 Install Musoq.CLI using the easy installation script above
2. 🖥️ Open one terminal and run the server:
   - Windows & Linux: `Musoq serve --wait-until-exit`
3. 🖥️ Open another terminal
4. 🔍 Run a query:
   - Windows & Linux: `Musoq run query "select 1 from #system.dual()"`
5. 🛑 To quit the server: `Musoq quit`

---

## Table of Contents

- [Query Execution](#query-execution)
  - [Basic Query Execution](#basic-query-execution)
  - [Output Formats](#output-formats)
  - [Query Debugging](#query-debugging)
  - [Query with Bucket Storage](#query-with-bucket-storage)
  - [Expression-Only Queries](#expression-only-queries)
  - [Post-Processing with --execute](#post-processing-with---execute)
  - [Running Queries from Files](#running-queries-from-files)
  - [Piped Text Processing](#piped-text-processing)
  - [Regex Pattern Matching](#regex-pattern-matching)
  - [JSON Flattening and Processing](#json-flattening-and-processing)
  - [YAML Flattening and Processing](#yaml-flattening-and-processing)
- [Local Configuration](#local-configuration)
  - [Setting Environment Variables](#setting-environment-variables)
  - [Setting Agent Configuration](#setting-agent-configuration)
  - [Clearing Configuration Values](#clearing-configuration-values)
- [Python Plugin Management](#python-plugin-management)
  - [List Python Plugins](#list-python-plugins)
  - [Read Python Plugin](#read-python-plugin)
  - [Create Python Plugin](#create-python-plugin)
  - [Rename Python Plugin](#rename-python-plugin)
  - [Delete Python Plugin](#delete-python-plugin)
  - [Show Plugin Directory](#show-plugin-directory)
  - [Using Python Plugins in Queries](#using-python-plugins-in-queries)
- [Information Retrieval](#information-retrieval)
  - [Get Data Sources](#get-data-sources)
  - [Get Server Version](#get-server-version)
  - [Get Environment Variables](#get-environment-variables)
  - [Get Environment Variables File Path](#get-environment-variables-file-path)
  - [Check Server Status](#check-server-status)
  - [Get Server Port](#get-server-port)
  - [Get Licenses](#get-licenses)
- [Bucket Management](#bucket-management)
  - [Create Bucket](#create-bucket)
  - [Delete Bucket](#delete-bucket)
  - [Using Buckets in Queries](#using-buckets-in-queries)
- [Tool Management](#tool-management)
  - [List Tools](#list-tools)
  - [Show Tool Details](#show-tool-details)
  - [Execute Tool](#execute-tool)
  - [Tool YAML File Format](#tool-yaml-file-format)
- [Logging and History](#logging-and-history)
  - [View Query History](#view-query-history)
  - [Limit Log Output](#limit-log-output)
  - [View Timestamps and Duration](#view-timestamps-and-duration)
- [Base64 Encoding](#base64-encoding)
  - [Encode Image to Base64](#encode-image-to-base64)
- [Server Management](#server-management)
  - [Start Server](#start-server)
  - [Stop Server](#stop-server)
- [Quick Reference](#quick-reference)
- [Troubleshooting](#troubleshooting)

---

## Query Execution

<details open>
<summary><h3>Basic Query Execution</h3></summary>

Execute SQL queries directly from the command line.

**Command:**
```bash
musoq run "select 20001 from #system.dual()"
```

**Expected Output:**
```
┌───────┐
│ 20001 │
├───────┤
│ 20001 │
└───────┘
```

**What it does:** Executes a simple SQL query using the `#system.dual()` data source, which returns a single row. The output is formatted as a table by default.

</details>

<details>
<summary><h3>Output Formats</h3></summary>

Musoq supports multiple output formats for different use cases.

#### JSON Format

**Command:**
```bash
musoq run "select 20002 from #system.dual()" --format json
```

**Expected Output:**
```json
[{"20002":20002}]
```

**What it does:** Returns query results as a JSON array, making it easy to pipe into other tools or parse programmatically.

---

#### CSV Format

**Command:**
```bash
musoq run "select 20003 from #system.dual()" --format csv
```

**Expected Output:**
```
20003
20003
```

**What it does:** Returns results as comma-separated values (header row + data rows).

**CSV Options:**
```bash
# Unquoted output (no quotes around string values)
musoq run "select 'text' from #system.dual()" --format csv --unquoted

# No header row
musoq run "select 20003 from #system.dual()" --format csv --no-header
```

---

#### Raw Format

**Command:**
```bash
musoq run "select 20004 from #system.dual()" --format raw
```

**Expected Output:**
```
Columns:
[{"name":"20004","type":"System.Int32","order":0}]
Rows:
[[{"value":20004}]]
```

**What it does:** Returns the raw internal representation including column metadata and row data with full type information.

---

#### Interpreted JSON Format

**Command:**
```bash
echo '{"name":"Alice","age":30}' | musoq run "
  SELECT j.Path, j.Value 
  FROM #stdin.JsonFlat() j
" --format interpreted_json
```

**Expected Output:**
```json
[{"name":"Alice","age":30}]
```

---

#### Reconstructed JSON Format

**Command:**
```bash
echo '{"user":{"name":"Alice"}}' | musoq run "
  SELECT j.Path as Path, j.Value as Value
  FROM #stdin.JsonFlat() j
" --format reconstructed_json
```

**Expected Output:**
```json
{"user":{"name":"Alice"}}
```

---

#### Interpreted YAML Format

**Command:**
```bash
echo '{"name":"Alice","age":30}' | musoq run "
  SELECT j.Path, j.Value 
  FROM #stdin.JsonFlat() j
" --format interpreted_yaml
```

**Expected Output:**
```yaml
- name: Alice
  age: 30
```

---

#### Reconstructed YAML Format

**Command:**
```bash
echo '[{"name":"Alice"},{"name":"Bob"}]' | musoq run "
  SELECT j.Path as Path, j.Value as Value
  FROM #stdin.JsonFlat() j
" --format reconstructed_yaml
```

**Expected Output:**
```yaml
- name: Alice
- name: Bob
```

</details>

<details>
<summary><h3>Query Debugging</h3></summary>

Enable debug mode to see detailed query execution information.

**Command:**
```bash
musoq run "select 1 from #system.dual()" --debug
```

**What it does:** Enables verbose logging and debug output during query execution, helpful for troubleshooting query issues or understanding execution flow.

</details>

<details>
<summary><h3>Query with Bucket Storage</h3></summary>

Store query results in a named bucket for later retrieval or reuse.

**Command:**
```bash
musoq run "select 20005 from #system.dual()" --bucket test-bucket
```

**Expected Output:**
```
┌───────┐
│ 20005 │
├───────┤
│ 20005 │
└───────┘
```

**What it does:** Executes the query based on data loaded to bucket named "test-bucket".

</details>

<details>
<summary><h3>Expression-Only Queries</h3></summary>

Execute simple expressions without requiring FROM clause syntax.

**Command:**
```bash
musoq run "1 + 2"
```

**Expected Output:**
```
┌───────┐
│ 1 + 2 │
├───────┤
│ 3     │
└───────┘
```

**What it does:** Evaluates expression in a single column mode (uses #system.dual()).

</details>

<details>
<summary><h3>Post-Processing with --execute</h3></summary>

Execute shell commands for each row of query results using template variables. The `--execute` option allows you to process query output with external commands or scripts.

#### Basic Command Execution

**Command:**
```bash
musoq run "select 1 as Test from #system.dual()" --execute "powershell -command 1+2"
```

**What it does:** Executes the PowerShell command `1+2` for each result row. The command output is added as `Expression` and `Result` columns to the output.

---

#### Using Template Variables

Template variables use the `{{ column_name }}` syntax to access values from query result columns.

**Command:**
```bash
musoq run "select 'John' as name, 30 as age from #system.dual()" --execute "echo Hello {{ name }}, you are {{ age }} years old" --format json
```

**Expected Output:**
```json
[{
  "name": "John",
  "age": 30,
  "Expression": "echo Hello John, you are 30 years old",
  "Result": "Hello John, you are 30 years old"
}]
```

**What it does:** 
- Executes a command template for each row
- Replaces `{{ name }}` with "John" and `{{ age }}` with "30"
- Adds the evaluated expression and its result as new columns

---

#### File System Operations

**Command (Windows):**
```bash
musoq run "select 'test.txt' as filename from #system.dual()" --execute "powershell -command Test-Path {{ filename }}" --format json
```

**Command (Linux/macOS):**
```bash
musoq run "select 'test.txt' as filename from #system.dual()" --execute "test -f {{ filename }} && echo true || echo false" --format json
```

**What it does:** Checks if a file exists for each row, using the filename column value.

---

#### Processing Multiple Rows

**Command:**
```bash
musoq run "
  select s.Value as line 
  from #stdin.TextBlock() t 
  cross apply t.SplitByNewLines(t.Value) s
" --execute "echo Processing: {{ line }}" --format csv < input.txt
```

**What it does:** 
- Reads lines from stdin
- Executes the echo command for each line
- Shows both original data and execution results

---

#### Nested Object Properties

When working with JSON output, you can access nested properties using dot notation.

**Example with nested data:**
```bash
musoq run "
  select j.Path, j.Value 
  from #stdin.JsonFlat() j 
  where j.Path = 'user.name'
" --execute "echo User is {{ j.Value }}" --format json < data.json
```

**What it does:** Accesses nested JSON properties and uses them in command templates.

---

#### Case-Insensitive Variable Matching

Template variables are **case-insensitive** - `{{ Name }}`, `{{ name }}`, and `{{ NAME }}` all reference the same column.

**Command:**
```bash
musoq run "select 'Alice' as Name from #system.dual()" --execute "echo Hello {{ name }}" --format json
```

**What it does:** Matches `{{ name }}` template to the `Name` column regardless of case differences.

---

#### Working with Different Output Formats

The `--execute` option works with all output formats:

**JSON Format:**
```bash
musoq run "select 'test' as value from #system.dual()" --execute "echo {{ value }}" --format json
```

**CSV Format:**
```bash
musoq run "select 'test' as value from #system.dual()" --execute "echo {{ value }}" --format csv
```

**Table Format:**
```bash
musoq run "select 'test' as value from #system.dual()" --execute "echo {{ value }}"
```

**Raw Format:**
```bash
musoq run "select 'test' as value from #system.dual()" --execute "echo {{ value }}" --format raw
```

---

#### Platform-Specific Commands

Commands are executed using the appropriate shell for your platform:

**Windows (PowerShell):**
```bash
musoq run "select 'C:\temp' as path from #system.dual()" --execute "powershell -command Get-ChildItem {{ path }}"
```

**Linux/macOS (sh):**
```bash
musoq run "select '/tmp' as path from #system.dual()" --execute "ls -la {{ path }}"
```

---

#### Practical Examples

**Check file sizes:**
```bash
musoq run "
  select Name as filename 
  from #system.files('C:\temp', false)
" --execute "powershell -command (Get-Item {{ filename }}).Length" --format csv
```

**Convert text to uppercase:**
```bash
echo -e "hello\nworld" | musoq run "
  select s.Value as text 
  from #stdin.TextBlock() t 
  cross apply t.SplitByNewLines(t.Value) s
" --execute "echo {{ text }} | tr '[:lower:]' '[:upper:]'" --format csv
```

**Validate email addresses:**
```bash
musoq run "
  select 'test@example.com' as email 
  from #system.dual()
" --execute "echo {{ email }} | grep -E '^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$'" --format json
```

---

#### Important Notes

1. **Variable Substitution**: Missing variables in templates remain as `{{ variable_name }}` in the output
2. **Error Handling**: Command execution errors are captured in the `Result` column
3. **Performance**: Commands execute sequentially for each row - consider performance for large datasets
4. **Shell Syntax**: Commands use the native shell syntax for your platform (cmd.exe on Windows, /bin/sh on Linux/macOS)
5. **Escaping**: Values are substituted as-is - be careful with special characters in shell commands

</details>

<details>
<summary><h3>Running Queries from Files</h3></summary>

Execute SQL queries stored in files for better organization and reusability.

**Command:**
```bash
musoq run path/to/query.sql
```

**Example query.sql:**
```sql
select 20006 from #system.dual()
```

**Expected Output:**
```
┌───────┐
│ 20006 │
├───────┤
│ 20006 │
└───────┘
```

**What it does:** Reads the SQL query from the specified file and executes it.

</details>

<details>
<summary><h3>Piped Text Processing</h3></summary>

Process text data piped from stdin using Musoq queries.

#### Read and Split Text by Lines

**Command:**
```bash
echo "Line 1
Line 2
Line 3" | musoq run "select s.Value from #stdin.TextBlock() t cross apply t.SplitByNewLines(t.Value) s" --format csv
```

**Expected Output:**
```
s.Value
"Line 1"
"Line 2"
"Line 3"
```

**What it does:** Reads text from stdin, splits it by newlines, and outputs each line as a row in CSV format (or whatever transformation is required).

---

#### Filter Text by Length

**Command:**
```bash
echo "Short
This is a much longer line of text
Medium line here" | musoq run "select s.Value, Length(s.Value) as Len from #stdin.TextBlock() t cross apply t.SplitByNewLines(t.Value) s where Length(s.Value) > 20" --format csv
```

**Expected Output:**
```
s.Value,Len
"This is a much longer line of text",34
```

**What it does:** Filters piped text to only show lines longer than 20 characters, displaying both the line and its length.

---

#### Count Lines

**Command:**
```bash
echo "Line 1
Line 2
Line 3" | musoq run "select Count(*) as LineCount from #stdin.TextBlock() t cross apply t.SplitByNewLines(t.Value) s" --format csv
```

**Expected Output:**
```
LineCount
3
```

**What it does:** Counts the number of lines in the piped text.

</details>

---

## Regex Pattern Matching

<details>
<summary><h3>Extract with Named Capture Groups</h3></summary>

Extract structured data from text using regex patterns with named capture groups.

**Command:**
```bash
echo "John 30
Alice 25
Bob 35" | musoq run "select r.name, r.age from #stdin.Regex('(?<name>\w+)\s+(?<age>\d+)') r" --format csv
```

**Expected Output:**
```
r.name,r.age
John,30
Alice,25
Bob,35
```

**What it does:** Applies a regex pattern to stdin text. Named capture groups (like `(?<name>...)`) become column names. Each match creates a new row with the captured values.

</details>

<details>
<summary><h3>Extract with Unnamed Groups</h3></summary>

Use unnamed capture groups when you don't need custom column names.

**Command:**
```bash
echo "John 30
Alice 25" | musoq run "select r.column1, r.column2 from #stdin.Regex('(\w+)\s+(\d+)') r" --format csv
```

**Expected Output:**
```
r.column1,r.column2
John,30
Alice,25
```

**What it does:** Unnamed capture groups are automatically named as `column1`, `column2`, etc., based on their position in the regex pattern.

</details>

<details>
<summary><h3>Extract Email Addresses</h3></summary>

Find and extract email addresses from text.

**Command:**
```bash
echo "Contact john@example.com for details
Reach out to alice@test.org
Email bob@company.net" | musoq run "select r.email from #stdin.Regex('(?<email>[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,})') r" --format csv
```

**Expected Output:**
```
r.email
john@example.com
alice@test.org
bob@company.net
```

**What it does:** Extracts all email addresses from the input text using a standard email regex pattern.

</details>

<details>
<summary><h3>Parse Log Files</h3></summary>

Extract structured information from log file entries.

**Command:**
```bash
echo "2024-01-01 10:30:00 ERROR Something went wrong
2024-01-01 10:31:00 INFO Process started
2024-01-01 10:32:00 WARN Memory low" | musoq run "select r.timestamp, r.level, r.message from #stdin.Regex('(?<timestamp>\d{4}-\d{2}-\d{2}\s+\d{2}:\d{2}:\d{2})\s+(?<level>\w+)\s+(?<message>.+)') r" --format csv
```

**Expected Output:**
```
r.timestamp,r.level,r.message
"2024-01-01 10:30:00",ERROR,Something went wrong
"2024-01-01 10:31:00",INFO,Process started
"2024-01-01 10:32:00",WARN,Memory low
```

**What it does:** Parses log entries into structured columns for timestamp, log level, and message content.

</details>

<details>
<summary><h3>Filter Regex Results</h3></summary>

Combine regex extraction with SQL filtering.

**Command:**
```bash
echo "John 30
Alice 25
Bob 35
Charlie 28" | musoq run "select r.name, r.age from #stdin.Regex('(?<name>\w+)\s+(?<age>\d+)') r where ToInt32(r.age) > 28" --format csv
```

**Expected Output:**
```
r.name,r.age
John,30
Bob,35
```

**What it does:** Extracts name and age pairs, then filters to show only people older than 28. Use conversion functions like `ToInt32()` to convert string values for comparison.

</details>

<details>
<summary><h3>Extract Multiple Matches Per Line</h3></summary>

Find all occurrences of a pattern within text, even multiple matches on the same line.

**Command:**
```bash
echo "The prices are $10.50 and $25.99 today" | musoq run "select r.price from #stdin.Regex('\$(?<price>\d+\.\d+)') r" --format csv
```

**Expected Output:**
```
r.price
10.50
25.99
```

**What it does:** Extracts all price values from the text, creating a separate row for each match found.

</details>

<details>
<summary><h3>Parse URLs</h3></summary>

Extract components from URLs using regex.

**Command:**
```bash
echo "Visit https://www.example.com/path
Check http://test.org/page
See https://github.com/user/repo" | musoq run "select r.protocol, r.domain from #stdin.Regex('(?<protocol>https?)://(?<domain>[^/]+)') r" --format csv
```

**Expected Output:**
```
r.protocol,r.domain
https,www.example.com
http,test.org
https,github.com
```

**What it does:** Parses URLs to extract the protocol (http/https) and domain name separately.

</details>

<details>
<summary><h3>Aggregate Regex Results</h3></summary>

Perform SQL aggregations on extracted data.

**Command:**
```bash
echo "John 30
Alice 25
Bob 35
Charlie 28" | musoq run "select Count(r.name) as TotalCount from #stdin.Regex('(?<name>\w+)\s+(?<age>\d+)') r" --format csv
```

**Expected Output:**
```
TotalCount
4
```

**What it does:** Counts the total number of matches found by the regex pattern.

</details>

<details>
<summary><h3>Mix Named and Unnamed Groups</h3></summary>

Combine named and unnamed capture groups in the same pattern.

**Command:**
```bash
echo "John 30 Developer
Alice 25 Manager" | musoq run "select r.name, r.column2, r.role from #stdin.Regex('(?<name>\w+)\s+(\d+)\s+(?<role>\w+)') r" --format csv
```

**Expected Output:**
```
r.name,r.column2,r.role
John,30,Developer
Alice,25,Manager
```

**What it does:** Named groups use their specified names (`name`, `role`), while unnamed groups get automatic names (`column2`).

**Note:** All extracted values are strings. Use conversion functions like `ToInt32()`, `ToDateTime()`, etc., when you need to perform operations requiring specific types.

</details>

---

## JSON Flattening and Processing

<details>
<summary><h3>Basic JSON Flattening</h3></summary>

Flatten JSON structures into path/value pairs for easy querying and manipulation.

**Command:**
```bash
echo '{"user": {"name": "Alice", "age": 30}, "tags": ["dev", "ops"]}' | musoq run "SELECT Path, Value FROM #stdin.JsonFlat() j" --format csv
```

**Expected Output:**
```
j.Path,j.Value
"user.name","Alice"
"user.age","30"
"tags[0]","dev"
"tags[1]","ops"
```

**What it does:** Flattens nested JSON into a table with two columns: `Path` (the JSON path using dot notation for objects and bracket notation for arrays) and `Value` (the corresponding value).

</details>

<details>
<summary><h3>Filter Object Properties</h3></summary>

Select specific properties from JSON objects while excluding others.

**Command:**
```bash
echo '{"id":123,"name":"Alice","password":"secret","email":"alice@example.com"}' | musoq run "
  SELECT j.Path, j.Value 
  FROM #stdin.JsonFlat() j 
  WHERE j.Path LIKE 'id' OR j.Path LIKE 'name' OR j.Path LIKE 'email'
" --format interpreted_json
```

**Expected Output:**
```json
[{"id":123,"name":"Alice","email":"alice@example.com"}]
```

**What it does:** Filters JSON to keep only specific properties (id, name, email) while excluding sensitive data (password). The `interpreted_json` format reconstructs the filtered data back into proper JSON.

</details>

<details>
<summary><h3>Filter Array Elements</h3></summary>

Filter elements from JSON arrays based on conditions.

**Command:**
```bash
echo '{"items":[0,5,10]}' | musoq run "
  SELECT j.Path, j.Value 
  FROM #stdin.JsonFlat() j 
  WHERE j.Value <> '5'
" --format interpreted_json
```

**Expected Output:**
```json
[{"items":[0,10]}]
```

**What it does:** Filters out array elements with value 5, keeping only 0 and 10. The array is automatically re-indexed in the output.

</details>

<details>
<summary><h3>Modify JSON Values</h3></summary>

Transform values while maintaining JSON structure.

**Command:**
```bash
echo '{"name":"Alice","age":30,"city":"New York"}' | musoq run "
  SELECT j.Path, 
    CASE WHEN j.Path = 'age' THEN '35' ELSE j.Value END as Value
  FROM #stdin.JsonFlat() j
" --format interpreted_json
```

**Expected Output:**
```json
[{"name":"Alice","age":35,"city":"New York"}]
```

**What it does:** Modifies the age value from 30 to 35 while keeping other properties unchanged. The `interpreted_json` format reconstructs the complete JSON with modifications.

</details>

<details>
<summary><h3>Filter Nested Object Properties</h3></summary>

Remove sensitive data from nested JSON structures.

**Command:**
```bash
echo '{"user":{"name":"Bob","email":"bob@example.com","password":"secret123"},"timestamp":"2024-01-01"}' | musoq run "
  SELECT j.Path, j.Value
  FROM #stdin.JsonFlat() j
  WHERE j.Path LIKE '%name%' OR j.Path LIKE '%email%' OR j.Path LIKE 'timestamp'
" --format interpreted_json
```

**Expected Output:**
```json
[{"user":{"name":"Bob","email":"bob@example.com"},"timestamp":"2024-01-01"}]
```

**What it does:** Filters out the password field from nested user object while preserving name, email, and timestamp.

</details>

<details>
<summary><h3>Modify Array Elements</h3></summary>

Transform values within arrays.

**Command:**
```bash
echo '{"numbers":[10,20,30]}' | musoq run "
  SELECT j.Path,
    CASE 
      WHEN Contains(j.Path, 'numbers[') THEN ToString(ToInt32(j.Value) * 2)
      ELSE j.Value
    END as Value
  FROM #stdin.JsonFlat() j
" --format interpreted_json
```

**Expected Output:**
```json
[{"numbers":[20,40,60]}]
```

**What it does:** Doubles each number in the array (10→20, 20→40, 30→60) while maintaining the array structure.

</details>

<details>
<summary><h3>Query Nested Arrays</h3></summary>

Work with complex nested structures containing arrays.

**Command:**
```bash
echo '{"users":[{"name":"Alice","scores":[85,90,95]},{"name":"Bob","scores":[70,75,80]}]}' | musoq run "
  SELECT j.Path, j.Value
  FROM #stdin.JsonFlat() j
  WHERE j.Path LIKE '%scores%'
" --format csv
```

**Expected Output:**
```
j.Path,j.Value
"users[0].scores[0]","85"
"users[0].scores[1]","90"
"users[0].scores[2]","95"
"users[1].scores[0]","70"
"users[1].scores[1]","75"
"users[1].scores[2]","80"
```

**What it does:** Extracts all score values from a nested array structure, showing the full path to each value.

</details>

<details>
<summary><h3>Property Renaming</h3></summary>

Rename properties while filtering.

**Command:**
```bash
echo '{"user_name":"Alice","user_email":"alice@example.com","user_age":30}' | musoq run "
  SELECT 
    CASE 
      WHEN j.Path = 'user_name' THEN 'name'
      WHEN j.Path = 'user_email' THEN 'email'
      ELSE j.Path
    END as Path,
    j.Value
  FROM #stdin.JsonFlat() j
  WHERE j.Path LIKE 'user_name' OR j.Path LIKE 'user_email'
" --format interpreted_json
```

**Expected Output:**
```json
[{"name":"Alice","email":"alice@example.com"}]
```

**What it does:** Transforms property names from `user_*` prefix to simple names while filtering out the age property.

</details>

<details>
<summary><h3>Count and Aggregate JSON Data</h3></summary>

Perform aggregate operations on flattened JSON.

**Command:**
```bash
echo '{"name":"Alice","age":30,"city":"New York"}' | musoq run "
  SELECT Count(j.Path) as PropertyCount 
  FROM #stdin.JsonFlat() j
" --format csv
```

**Expected Output:**
```
PropertyCount
3
```

**What it does:** Counts the number of properties in the JSON object.

</details>

</details>

---

## YAML Flattening and Processing

<details>
<summary><h3>Basic YAML Flattening</h3></summary>

Flatten YAML structures into path/value pairs for easy querying and manipulation.

**Command:**
```bash
echo 'user:
  name: Alice
  age: 30
tags:
  - dev
  - ops' | musoq run "SELECT y.Path, y.Value FROM #stdin.YamlFlat() y" --format csv
```

**Expected Output:**
```
y.Path,y.Value
"user.name",Alice
"user.age",30
"tags[0]",dev
"tags[1]",ops
```

**What it does:** Flattens nested YAML into a table with two columns: `Path` (the YAML path using dot notation for objects and bracket notation for arrays) and `Value` (the corresponding value).

</details>

<details>
<summary><h3>Convert YAML to JSON</h3></summary>

Transform YAML data into JSON format using interpreted_json output.

**Command:**
```bash
echo 'user:
  name: Alice
  age: 30
  email: alice@example.com
active: true' | musoq run "
  SELECT y.Path, y.Value 
  FROM #stdin.YamlFlat() y
" --format interpreted_json
```

**Expected Output:**
```json
[{"user":{"name":"Alice","age":30,"email":"alice@example.com"},"active":true}]
```

**What it does:** Reads YAML from stdin, flattens it to path/value pairs, then reconstructs it as JSON using the `interpreted_json` format.

</details>

<details>
<summary><h3>Convert JSON to YAML</h3></summary>

Transform JSON data into YAML format.

**Command:**
```bash
echo '{"user":{"name":"Bob","age":25,"email":"bob@example.com"},"active":false}' | musoq run "
  SELECT j.Path, j.Value
  FROM #stdin.JsonFlat() j
" --format yaml
```

**Expected Output:**
```yaml
- j.Path: user.name
  j.Value: Bob
- j.Path: user.age
  j.Value: 25
- j.Path: user.email
  j.Value: bob@example.com
- j.Path: active
  j.Value: false
```

**What it does:** Reads JSON from stdin, flattens it to path/value pairs, then outputs as YAML format.

</details>

<details>
<summary><h3>Filter YAML Properties</h3></summary>

Select specific properties from YAML objects while excluding others.

**Command:**
```bash
echo 'id: 123
name: Alice
password: secret
email: alice@example.com' | musoq run "
  SELECT y.Path, y.Value 
  FROM #stdin.YamlFlat() y 
  WHERE y.Path LIKE 'id' OR y.Path LIKE 'name' OR y.Path LIKE 'email'
" --format interpreted_json
```

**Expected Output:**
```json
[{"id":123,"name":"Alice","email":"alice@example.com"}]
```

**What it does:** Filters YAML to keep only specific properties (id, name, email) while excluding sensitive data (password).

</details>

<details>
<summary><h3>Modify YAML Array Values</h3></summary>

Transform values within YAML arrays.

**Command:**
```bash
echo 'numbers:
  - 10
  - 20
  - 30' | musoq run "
  SELECT y.Path,
    CASE 
      WHEN Contains(y.Path, 'numbers[') THEN ToString(ToInt32(y.Value) * 2)
      ELSE y.Value
    END as Value
  FROM #stdin.YamlFlat() y
" --format interpreted_json
```

**Expected Output:**
```json
[{"numbers":[20,40,60]}]
```

**What it does:** Doubles each number in the YAML array (10→20, 20→40, 30→60) while maintaining the structure.

</details>

<details>
<summary><h3>Query Nested YAML Arrays</h3></summary>

Work with complex nested YAML structures containing arrays.

**Command:**
```bash
echo 'users:
  - name: Alice
    scores:
      - 85
      - 90
      - 95
  - name: Bob
    scores:
      - 70
      - 75
      - 80' | musoq run "
  SELECT y.Path, y.Value
  FROM #stdin.YamlFlat() y
  WHERE y.Path LIKE '%scores%'
" --format csv
```

**Expected Output:**
```
y.Path,y.Value
"users[0].scores[0]",85
"users[0].scores[1]",90
"users[0].scores[2]",95
"users[1].scores[0]",70
"users[1].scores[1]",75
"users[1].scores[2]",80
```

**What it does:** Extracts all score values from a nested YAML array structure, showing the full path to each value.

</details>

<details>
<summary><h3>Convert YAML Arrays to JSON</h3></summary>

Transform YAML arrays containing objects into JSON format.

**Command:**
```bash
echo 'users:
  - name: Alice
    role: Developer
  - name: Bob
    role: Manager' | musoq run "
  SELECT y.Path, y.Value
  FROM #stdin.YamlFlat() y
" --format interpreted_json
```

**Expected Output:**
```json
[{"users":[{"name":"Alice","role":"Developer"},{"name":"Bob","role":"Manager"}]}]
```

**What it does:** Converts a YAML array with nested objects into equivalent JSON structure.

</details>

<details>
<summary><h3>Count YAML Properties</h3></summary>

Perform aggregate operations on flattened YAML.

**Command:**
```bash
echo 'name: Alice
age: 30
city: New York' | musoq run "
  SELECT Count(y.Path) as PropertyCount 
  FROM #stdin.YamlFlat() y
" --format csv
```

**Expected Output:**
```
PropertyCount
3
```

**What it does:** Counts the number of top-level properties in the YAML document.

</details>

<details>
<summary><h3>Convert YAML to JSON (Reconstructed Format)</h3></summary>

Convert YAML to JSON preserving exact structure using `reconstructed_json` format.

**Command:**
```bash
echo 'user:
  name: Alice
  age: 30
  email: alice@example.com
active: true' | musoq run "
  SELECT y.Path as Path, y.Value as Value
  FROM #stdin.YamlFlat() y
" --format reconstructed_json
```

**Expected Output:**
```json
{"user":{"name":"Alice","age":30,"email":"alice@example.com"},"active":true}
```

</details>

<details>
<summary><h3>Convert JSON to YAML (Reconstructed Format)</h3></summary>

Convert JSON to YAML preserving exact structure using `reconstructed_yaml` format.

**Command:**
```bash
echo '{"user":{"name":"Bob","age":25,"email":"bob@example.com"},"active":false}' | musoq run "
  SELECT j.Path as Path, j.Value as Value
  FROM #stdin.JsonFlat() j
" --format reconstructed_yaml
```

**Expected Output:**
```yaml
user:
  name: Bob
  age: 25
  email: bob@example.com
active: false
```

</details>

<details>
<summary><h3>Convert Root-Level JSON Array to YAML</h3></summary>

Convert JSON arrays at root level to YAML, preserving array structure.

**Command:**
```bash
echo '[{"name":"Alice","age":30},{"name":"Bob","age":25}]' | musoq run "
  SELECT j.Path as Path, j.Value as Value
  FROM #stdin.JsonFlat() j
" --format reconstructed_yaml
```

**Expected Output:**
```yaml
- name: Alice
  age: 30
- name: Bob
  age: 25
```

</details>

<details>
<summary><h3>Convert Root-Level YAML Array to JSON</h3></summary>

Convert YAML arrays at root level to JSON, preserving array structure.

**Command:**
```bash
echo '- name: Alice
  age: 30
- name: Bob
  age: 25' | musoq run "
  SELECT y.Path as Path, y.Value as Value
  FROM #stdin.YamlFlat() y
" --format reconstructed_json
```

**Expected Output:**
```json
[{"name":"Alice","age":30},{"name":"Bob","age":25}]
```

</details>

<details>
<summary><h3>Round-Trip JSON Array Conversion</h3></summary>

Verify that JSON arrays can be flattened and reconstructed without loss.

**Command:**
```bash
echo '[{"name":"Alice","age":30},{"name":"Bob","age":25}]' | musoq run "
  SELECT j.Path as Path, j.Value as Value
  FROM #stdin.JsonFlat() j
" --format reconstructed_json
```

**Expected Output:**
```json
[{"name":"Alice","age":30},{"name":"Bob","age":25}]
```

</details>

---

## Local Configuration

<details>
<summary><h3>Setting Environment Variables</h3></summary>

Set environment variables for data source plugins and tools.

**Command:**
```bash
musoq set environment-variable "API_TOKEN" "secret-token-value"
```

**Expected Output:**
```
Environment variable set successfully
```

**What it does:** Stores an environment variable that can be accessed by data source plugins (e.g., for API authentication).

---

## Python Plugin Management

> **Note:** Python plugins use project-based architecture. Each plugin is a directory containing `main.py` and optional supporting files like `requirements.txt`.

<details>
<summary><h3>List Python Plugins</h3></summary>

View all available Python data source plugin projects.

**Command:**
```bash
musoq python list
```

**Expected Output (when no plugins exist):**
```
Name,Description,Created,Modified
```

**Expected Output (with plugins):**
```
Name,Description,Created,Modified
alpha-script,Alpha script for testing,2024-10-21 10:30:00,2024-10-21 10:30:00
beta-script,Beta script for testing,2024-10-21 10:35:00,2024-10-21 10:35:00
```

**What it does:** Lists all Python plugin projects in the `~/.musoq/Python/Scripts/` directory with their metadata including name, description, and timestamps.

</details>

<details>
<summary><h3>Read Python Plugin</h3></summary>

Display the contents of a Python plugin project's main.py file.

**Command:**
```bash
musoq python read my_plugin
```

**Expected Output:**
```
# Project: my_plugin
# Description: My plugin description
# Created: 2024-10-21 10:30:00
# Modified: 2024-10-21 10:30:00

class DataPlugin:
    def schema_name(self):
        return "mydata"
    # ... rest of plugin code
```

**What it does:** Reads and displays the content of the specified plugin project's main.py file along with metadata.

</details>

<details>
<summary><h3>Create Python Plugin</h3></summary>

Create a new Python plugin project from a template.

**Command:**
```bash
musoq python create my_plugin
```

**With specific template:**
```bash
musoq python create my_plugin basic
musoq python create my_plugin api
```

**Expected Output:**
```
Project 'my_plugin' created successfully from template 'basic'.
```

**What it does:** Creates a new Python plugin project directory with the following structure:
```
~/.musoq/Python/Scripts/my_plugin/
├── main.py          # Plugin implementation (from template)
├── requirements.txt # Optional: Python dependencies
└── project.json     # Optional: Project metadata
```

The project folder is automatically opened in your system's default file explorer.

**Available templates:**
- `basic` (default): Simple data source template
- `api`: Template for API-based data sources
- `database`: Template for database connections

**Plugin structure example (v.2):**
```python
class DataPlugin:
    def schema_name(self):
        return "mydata"
    
    def data_sources(self):
        return ["items"]
    
    def schemas(self):
        return [{"id": "int", "name": "str", "value": "float"}]
    
    def initialize(self):
        pass
    
    def get_required_env_vars(self, method_name):
        return {}
    
    def get_required_execute_arguments(self, method_name):
        return []
    
    def execute(self, method_name, environment_variables, *args):
        if method_name == "items":
            yield {"id": 1, "name": "Item 1", "value": 10.5}
    
    def dispose(self):
        pass

plugin = DataPlugin()
```

</details>

<details>
<summary><h3>Rename Python Plugin</h3></summary>

Rename an existing Python plugin project.

**Command:**
```bash
musoq python update old_name new_name
```

**Expected Output:**
```
Python project renamed from 'old_name' to 'new_name' successfully
```

**What it does:** Renames the plugin project directory and opens the new location in your file explorer. The plugin's schema_name in the code must be updated manually to match the new name.

</details>

<details>
<summary><h3>Delete Python Plugin</h3></summary>

Remove a Python plugin project from the system.

**Command:**
```bash
musoq python delete my_plugin
```

**Expected Output:**
```
Python plugin 'my_plugin' deleted successfully
```

**What it does:** Removes the entire plugin project directory from `~/.musoq/Python/Scripts/`.

</details>

<details>
<summary><h3>Show Plugin Directory</h3></summary>

Display or open the Python plugins directory.

**Command:**
```bash
musoq python folder
```

**Expected Output:**
```
~/.musoq/Python/Scripts/
```

**Open in file explorer:**
```bash
musoq python folder --open
```

**Open specific project:**
```bash
musoq python folder my_plugin --open
```

**What it does:** Shows the path to the plugins directory or opens it (or a specific project) in your system's default file explorer.

</details>

<details>
<summary><h3>Using Python Plugins in Queries</h3></summary>

Execute queries using your custom Python plugins as data sources.

**Prerequisite:** Create a Python plugin with schema name "mydata" and data sources ["items", "summary"]

**Command:**
```bash
musoq run "select id, name, value from #mydata.items()" --format csv
```

**With parameters:**
```bash
musoq run "select * from #mydata.items(100)" --format csv
```

**Multiple data sources:**
```bash
musoq run "select * from #mydata.summary()" --format csv
```

**Expected Output:**
```
id,name,value
42,"Answer","Meaning"
```

**What it does:** Queries data from your custom Python plugin, treating it like any other data source. Single plugin can provide multiple data sources (methods).

**Note:** The server must be restarted after creating a plugin for it to be discovered, or the plugin must exist before server startup.

</details>

---

## Information Retrieval

<details>
<summary><h3>Get Data Sources</h3></summary>

List all available data sources and their versions.

**Command:**
```bash
musoq get data-sources
```

**Expected Output:**
```
Name,Version,FullName
api,1.1.0.0,Musoq.Cloud.DataSources.ExternalApi
memorymapped,1.1.0.0,Musoq.Cloud.DataSources.MemoryMapped
system,6.2.15.0,Musoq.DataSources.System
```

**What it does:** Displays all loaded data source plugins with their names, versions, and full assembly names.

</details>

<details>
<summary><h3>Get Server Version</h3></summary>

Check the version of the running Musoq server.

**Command:**
```bash
musoq get server-version
```

**Expected Output:**
```
Server version: 1.0.0
```

**What it does:** Queries the local agent server and returns its version number.

</details>

<details>
<summary><h3>Get Environment Variables</h3></summary>

List all configured environment variables used by plugins.

#### Show Masked Values (default)

**Command:**
```bash
musoq get environment-variables
```

**Expected Output:**
```
Name,Value,Assemblies
TEST_VAR,***cretValue42,"Sample.Tools.Assembly"
API_KEY,***123,"Musoq.Cloud.DataSources.ExternalApi"
```

---

#### Show Sensitive Values

**Command:**
```bash
musoq get environment-variables --show-sensitive true
```

**Expected Output:**
```
Name,Value,Assemblies
TEST_VAR,SecretValue42,"Sample.Tools.Assembly"
API_KEY,sk-abc123,"Musoq.Cloud.DataSources.ExternalApi"
```

**What it does:** Displays all environment variables with masked or unmasked values and the assemblies that use them.

</details>

<details>
<summary><h3>Get Environment Variables File Path</h3></summary>

Display the path to the environment variables configuration file.

**Command:**
```bash
musoq get environment-variables-file-path
```

**Expected Output:**
```
~/.musoq/environment-variables.json
```

**What it does:** Returns the full path to the file where environment variables are stored.

</details>

<details>
<summary><h3>Check Server Status</h3></summary>

Verify if the Musoq server is currently running.

**Command:**
```bash
musoq get is-running
```

**Expected Output (when running):**
```
Server is up and running
```

**Expected Output (when not running):**
```
Server is not running
```

**Exit codes:**
- `0` - Server is running
- `1` - Server is not running

**What it does:** Checks the health endpoint of the local agent server.

</details>

<details>
<summary><h3>Get Server Port</h3></summary>

Retrieve the port number the server is listening on.

**Command:**
```bash
musoq get server-port
```

**Expected Output:**
```
5000
```

**What it does:** Returns the TCP port number where the local agent server is accepting connections.

</details>

<details>
<summary><h3>Get Licenses</h3></summary>

Display license information for dependencies.

**Command:**
```bash
musoq get licenses
```

**What it does:** Returns license information for all third-party dependencies used by Musoq.

</details>

---

## Bucket Management

<details>
<summary><h3>Create Bucket</h3></summary>

Create a named storage bucket for query results.

**Command:**
```bash
musoq bucket create my-bucket
```

**Expected Output:**
```
Bucket 'my-bucket' created successfully
```

**What it does:** Creates a new bucket in the local storage that can be used to store query results.

</details>

<details>
<summary><h3>Delete Bucket</h3></summary>

Remove a bucket and its contents.

**Command:**
```bash
musoq bucket delete my-bucket
```

**Expected Output:**
```
Bucket 'my-bucket' deleted successfully
```

**What it does:** Removes the specified bucket and all data stored within it.

</details>

<details>
<summary><h3>Using Buckets in Queries</h3></summary>

Store query results in a bucket for later retrieval.

**Step 1: Create the bucket**
```bash
musoq bucket create my-results
```

**Step 2: Run query with bucket**
```bash
musoq run "select 30001 from #system.dual()" --bucket my-results
```

**Expected Output:**
```
┌───────┐
│ 30001 │
├───────┤
│ 30001 │
└───────┘
```

**What it does:** Executes the query, stores results in the specified bucket, and displays them immediately.

</details>

---

## Tool Management

<details>
<summary><h3>List Tools</h3></summary>

View all available tools with their metadata.

#### List All Tools

**Command:**
```bash
musoq tool list
```

**Expected Output:**
```
Name,Description,ParameterCount
alpha-tool,Tool for alpha scenarios,2
beta-tool,Secondary analyzer,0
```

---

#### Filter Tools by Search Term

**Command:**
```bash
musoq tool list --search "alpha"
```

**Expected Output:**
```
Name,Description,ParameterCount
alpha-tool,Tool for alpha scenarios,2
```

**What it does:** Lists all registered tools with their names, descriptions, and parameter counts. Can be filtered by search term.

</details>

<details>
<summary><h3>Show Tool Details</h3></summary>

Display detailed information about a specific tool.

**Command:**
```bash
musoq tool show alpha-tool
```

**Expected Output:**
```
Name: alpha-tool
Description: Tool for alpha scenarios
Query: SELECT 10001 FROM #system.dual()
Output Format: json

Parameters:
  - firstParam (string) [Required]
    Description: Primary value to process
  - optionalFlag (bool)
    Description: Optional flag controlling execution
    Default: enabled
```

**What it does:** Shows complete details about a tool including its query template, parameters, and output format.

</details>

<details>
<summary><h3>Execute Tool</h3></summary>

Run a tool with specified parameters.

#### Execute with Debug Output

**Command:**
```bash
musoq tool execute my-tool --debug
```

**Expected Output:**
```
Executing query: SELECT 'debug-output' as Result FROM #system.dual()

┌──────────────┐
│ Result       │
├──────────────┤
│ debug-output │
└──────────────┘
```

---

#### Execute with Parameters

**Command:**
```bash
musoq tool execute data-processor --param1 "value1" --param2 "value2"
```

**What it does:** Executes the tool's query template with the provided parameters. In debug mode, shows the actual query being executed.

**Parameter formats:**
- `--param value` - Named parameter with value
- `--flag` - Boolean flag (sets to true)
- `param value` - Positional parameter

---

#### Parameter Types and Syntax

Different parameter types require different syntax in the query template:

| Type     | Query Syntax      | Example              |
|----------|-------------------|----------------------|
| `string` | `'{{ param }}'`   | `'{{ path }}'`       |
| `int`    | `{{ param }}`     | `{{ count }}`        |
| `long`   | `{{ param }}`     | `{{ size }}`         |
| `bool`   | `{{ param }}`     | `{{ recursive }}`    |
| `float`  | `{{ param }}`     | `{{ threshold }}`    |

**Key Rule:** String parameters need quotes in SQL, numeric/boolean parameters don't.

</details>

<details>
<summary><h3>Tool YAML File Format</h3></summary>

Tools are defined as YAML files stored in `~/.musoq/Tools/` directory (e.g., `C:\Users\<YourUser>\.musoq\Tools\` on Windows).

#### Complete YAML Structure

**File:** `~/.musoq/Tools/example-tool.yaml`

```yaml
name: tool-name
description: Brief description of what the tool does
query: |
  SELECT
    Column1,
    '{{ string_param }}' as Text,
    {{ numeric_param }} as Number
  FROM #datasource.method('{{ path }}', {{ boolean_param }})
  WHERE SomeCondition = {{ value }}
  ORDER BY Column1 DESC
parameters:
  - name: param1
    type: string
    required: true
    description: Description of parameter 1
  - name: param2
    type: int
    required: false
    default: 100
    description: Description of parameter 2
  - name: param3
    type: bool
    required: false
    default: true
    description: Description of parameter 3
output:
  format: table
```

---

#### YAML Field Specifications

| Field | Required | Type | Description | Example |
|-------|----------|------|-------------|---------|
| `name` | ✅ Yes | string | Unique tool identifier (no spaces) | `disk-usage` |
| `description` | ✅ Yes | string | Brief explanation of tool purpose | `Analyze disk usage by file extension` |
| `query` | ✅ Yes | string | SQL query with parameter placeholders | See examples below |
| `parameters` | ✅ Yes | array | List of parameter definitions | See parameter format |
| `output.format` | ✅ Yes | string | Output format (`table`, `json`, `csv`) | `table` |

---

#### Parameter Definition Format

Each parameter in the `parameters` array must have:

```yaml
- name: parameter_name        # Parameter identifier
  type: parameter_type        # string, int, long, bool, float
  required: true/false        # Is this parameter mandatory?
  default: default_value      # Default value (optional params only)
  description: help_text      # What this parameter does
```

**Parameter Types:**
- `string` - Text values (use quotes in query: `'{{ param }}'`)
- `int` - Integer numbers (no quotes: `{{ param }}`)
- `long` - Long integers (no quotes: `{{ param }}`)
- `bool` - Boolean values (no quotes: `{{ param }}`)
- `float` - Floating point numbers (no quotes: `{{ param }}`)

---

#### Example 1: Simple Greeting Tool

**File:** `~/.musoq/Tools/greeting.yaml`

```yaml
name: greeting
description: Display a personalized greeting
query: |
  SELECT
    '{{ name }}' as Name,
    'Hello, {{ name }}!' as Greeting,
    {{ age }} as Age
  FROM #system.dual()
parameters:
  - name: name
    type: string
    required: true
    description: Your name
  - name: age
    type: int
    required: false
    default: 0
    description: Your age
output:
  format: table
```

**Usage:**
```bash
musoq tool execute greeting -- --name "Alice" --age 30
```

</details>

---

## Logging and History

<details>
<summary><h3>View Query History</h3></summary>

Display recent query execution logs with results.

**Command:**
```bash
musoq log
```

**Expected Output (no history):**
```
No query execution logs found
```

**Expected Output (with history):**
```
Recent Query Execution Logs

[2024-10-21 14:30:15] SUCCESS (125ms)
Query: SELECT 1 FROM #system.dual()
Rows: 1

[2024-10-21 14:30:20] SUCCESS (98ms)
Query: SELECT 2 FROM #system.dual()
Rows: 1

[2024-10-21 14:30:25] SUCCESS (103ms)
Query: SELECT 3 FROM #system.dual()
Rows: 1
```

**What it does:** Shows the history of recently executed queries with timestamps, execution status, duration, and result counts.

</details>

<details>
<summary><h3>Limit Log Output</h3></summary>

Control the number of log entries displayed.

**Command:**
```bash
musoq log --count 2
```

**Expected Output:**
```
Recent Query Execution Logs (2)

[2024-10-21 14:30:25] SUCCESS (103ms)
Query: SELECT 3 FROM #system.dual()
Rows: 1

[2024-10-21 14:30:20] SUCCESS (98ms)
Query: SELECT 2 FROM #system.dual()
Rows: 1
```

**What it does:** Limits the output to the specified number of most recent log entries.

</details>

<details>
<summary><h3>View Timestamps and Duration</h3></summary>

Query logs include detailed timing information.

**Command:**
```bash
musoq log
```

**Output includes:**
- **Timestamp:** `[2024-10-21 12:34:56]` - When the query was executed
- **Status:** `SUCCESS` or `FAILED` - Execution result
- **Duration:** `125ms` - How long the query took to execute

**What it does:** Each log entry shows when queries ran and how long they took, helping identify performance issues.

</details>

---

## Base64 Encoding

<details>
<summary><h3>Encode Image to Base64</h3></summary>

Convert image files to base64-encoded strings.

#### Encode Regular File

**Command:**
```bash
musoq image encode path/to/image.png
```

**Expected Output:**
```
iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAYAAAAfFcSJAAAADUlEQVR42mNk+M9QDwADhgGAWjR9awAAAABJRU5ErkJggg==
```

---

#### Encode Small Binary File

**Command:**
```bash
musoq image encode path/to/small-file.bin
```

**Expected Output:**
```
iVBORw0KGgo=
```

**What it does:** Reads the specified file and outputs its contents as a base64-encoded string.

**Note:** Despite the command name "image encode", it can encode any binary file, not just images.

</details>

---

## Server Management

<details>
<summary><h3>Start Server</h3></summary>

Start the local Musoq agent server in the background.

**Command (background mode):**
```bash
musoq serve
```

**Command (foreground mode - wait until exit):**
```bash
musoq serve --wait-until-exit
```

**What it does:** 
- `serve`: Starts the local agent API server as a background process. The server handles query execution, plugin management, and all other operations. The command returns immediately after starting the server.
- `serve --wait-until-exit`: Starts the server in foreground mode and blocks until the server is explicitly stopped. Useful for debugging or when you want to keep the server running in a terminal session.

**Note:** Most CLI commands require the server to be running. The server starts automatically when needed in many scenarios.

</details>

<details>
<summary><h3>Stop Server</h3></summary>

Gracefully shut down the running server.

**Command:**
```bash
musoq quit
```

**Expected Output:**
```
Server shutdown initiated
```

**What it does:** Sends a shutdown signal to the running server, allowing it to complete current operations and exit cleanly.

</details>

---

## Quick Reference

### Common Commands

| Task | Command |
|------|---------|
| Run simple query | `musoq run "SELECT 1 FROM #system.dual()"` |
| Run query as JSON | `musoq run "SELECT 1 FROM #system.dual()" --format json` |
| Run query as CSV | `musoq run "SELECT 1 FROM #system.dual()" --format csv` |
| Run query from file | `musoq run query.sql` |
| Run query with command execution | `musoq run "SELECT 1 as Test FROM #system.dual()" --execute "powershell -command 1+2"` |
| Process piped text | `echo "data" \| musoq run "SELECT * FROM #stdin.TextBlock()"` |
| Flatten JSON from stdin | `echo '{"key":"value"}' \| musoq run "SELECT * FROM #stdin.JsonFlat()"` |
| Flatten YAML from stdin | `echo 'key: value' \| musoq run "SELECT * FROM #stdin.YamlFlat()"` |
| Convert YAML to JSON | `echo 'key: value' \| musoq run "SELECT y.Path, y.Value FROM #stdin.YamlFlat() y" --format interpreted_json` |
| Convert JSON to YAML | `echo '{"key":"value"}' \| musoq run "SELECT j.Path, j.Value FROM #stdin.JsonFlat() j" --format yaml` |
| Set environment variable | `musoq set environment-variable "VAR_NAME" "value"` |
| Set agent name | `musoq set agent-name "my-agent"` |
| List tools | `musoq tool list` |
| Show tool details | `musoq tool show tool-name` |
| Execute tool | `musoq tool execute tool-name --param1 value1` |
| List Python plugins | `musoq python list` |
| Create Python plugin | `musoq python create plugin_name [template]` |
| Read Python plugin | `musoq python read plugin_name` |
| Rename Python plugin | `musoq python update old_name new_name` |
| Delete Python plugin | `musoq python delete plugin_name` |
| Show plugins folder | `musoq python folder` |
| Get data sources | `musoq get data-sources` |
| Check server status | `musoq get is-running` |
| Get environment variables | `musoq get environment-variables` |
| Create bucket | `musoq bucket create bucket-name` |
| View query history | `musoq log` |
| Encode image | `musoq image encode file.png` |
| Start server | `musoq serve` |
| Start server (foreground) | `musoq serve --wait-until-exit` |
| Stop server | `musoq quit` |

### Output Formats

| Format | Flag | Options | Use Case |
|--------|------|---------|----------|
| Table (default) | None or `--format table` | `--execute` | Human-readable output |
| JSON | `--format json` | `--execute` | API integration, parsing |
| CSV | `--format csv` | `--unquoted`, `--no-header`, `--execute` | Excel, data analysis |
| Raw | `--format raw` | `--execute` | Debugging, type inspection |

**Note:** The `--execute` option works with all output formats to post-process results with shell commands.

### Python Plugin Templates

| Template | Use Case |
|----------|----------|
| `basic` | Simple data sources with static or computed data |
| `api` | REST API-based data sources |

### Configuration Commands

| Category | Set Command | Clear Command |
|----------|-------------|---------------|
| Environment Variable | `set environment-variable NAME VALUE` | `clear environment-variable NAME` |
| Log Path | `set log-path PATH` | `clear log-path` |

### Common Data Sources

| Data Source | Syntax | Example |
|-------------|--------|---------|
| System dual | `#system.dual()` | `SELECT 1 FROM #system.dual()` |
| Files | `#system.files(path, recursive)` | `SELECT Name FROM #system.files('C:\\', false)` |
| Directories | `#system.directory(path, recursive)` | `SELECT Name FROM #system.directory('C:\\', false)` |
| Stdin text | `#stdin.TextBlock()` | `SELECT Value FROM #stdin.TextBlock()` |
| Stdin regex | `#stdin.Regex(pattern)` | `SELECT r.name, r.age FROM #stdin.Regex('(?<name>\w+)\s+(?<age>\d+)') r` |
| Stdin JSON | `#stdin.JsonFlat()` | `SELECT j.Path, j.Value FROM #stdin.JsonFlat() j` |
| Stdin YAML | `#stdin.YamlFlat()` | `SELECT y.Path, y.Value FROM #stdin.YamlFlat() y` |
| Python plugin | `#schema.datasource()` | `SELECT * FROM #mydata.items()` |

### File Locations

| Resource | Default Location |
|----------|-----------------|
| Settings file | `~/.musoq/settings.json` |
| Python plugins | `~/.musoq/Python/Scripts/` |
| Environment variables | `~/.musoq/environment-variables.json` |
| Tools | `~/.musoq/Tools/` |

---

## Troubleshooting

### Server Not Running
```bash
# Check if server is running
musoq get is-running

# If not running, start it
musoq serve
```

### Plugin Not Found
```bash
# List available data sources
musoq get data-sources

# For Python plugins, ensure server was restarted after creation
musoq quit
musoq serve
```

### Query Execution Failed
```bash
# Check recent logs for error details
musoq log --count 5
```

### Configuration Issues
```bash
# View environment variables
musoq get environment-variables

# View environment variables file path
musoq get environment-variables-file-path

# Clear and reset an environment variable
musoq clear environment-variable "VAR_NAME"
musoq set environment-variable "VAR_NAME" "new-value"
```

### Python Plugin Issues
```bash
# List all Python plugin projects
musoq python list

# Read plugin content to verify structure
musoq python read plugin_name

# Show plugins directory location
musoq python folder

# Open plugins directory in file explorer
musoq python folder --open
```
