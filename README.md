# Musoq CLI

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

# Musoq Server & CLI Specification

---

## Table of Contents

1. [Introduction](#1-introduction)
2. [Architecture Overview](#2-architecture-overview)
3. [Installation & Environment](#3-installation--environment)
4. [Server Commands](#4-server-commands)
5. [Query Execution](#5-query-execution)
6. [Data Source Management](#6-data-source-management)
7. [Python Plugin Development](#7-python-plugin-development)
8. [Tool Management](#8-tool-management)
9. [Scripts Management](#9-scripts-management)
10. [Registry Management](#10-registry-management)
11. [Configuration Management](#11-configuration-management)
12. [Bucket Management](#12-bucket-management)
13. [Utility Commands](#13-utility-commands)
14. [API Reference](#14-api-reference)
15. [Exit Codes & Error Handling](#15-exit-codes--error-handling)
16. [Configuration Files](#16-configuration-files)
17. [Security Considerations](#17-security-considerations)

---

## 1. Introduction

### 1.1 Purpose

This specification defines the Musoq server and command-line interface (CLI). The server provides a local execution environment for Musoq SQL queries, enabling developers to query diverse data sources through a unified interface.

### 1.2 Scope

This specification covers:

- CLI command structure and syntax
- Server lifecycle management
- Data source plugin management (both .NET and Python)
- Python plugin development contract
- Tool definition and execution
- SQL script management
- Plugin registry configuration
- Configuration and environment variables
- REST API endpoints for programmatic access
- Error handling and exit codes
- Configuration file formats
- Security considerations

### 1.3 Design Philosophy

The Musoq CLI follows these principles:

- **Discoverability**: Commands are organized hierarchically with consistent patterns
- **Composability**: Output formats support piping and scripting
- **Offline-First**: By default, it doesn't connect anywhere, doesn't send any telemetry, can work fully offline
- **Extensibility**: Plugin architecture for data sources and tools

### 1.4 Command Structure

All CLI commands follow this general pattern:

```
musoq <command> [subcommand] [arguments] [options]
```

Commands are case-insensitive. Options use the standard `--option` or `-o` format.

### 1.5 Terminology

| Term | Definition |
|------|------------|
| **Server** | The local server that executes queries and manages plugins |
| **Data Source** | A plugin that provides access to a specific type of data |
| **Schema** | The named interface exposed by a data source for SQL queries |
| **Tool** | A predefined SQL query template with parameters |
| **Script** | A saved SQL query file |
| **Registry** | A remote source for discovering and downloading plugins |
| **Bucket** | An isolated context for query execution with preloaded data |

---

## 2. Architecture Overview

### 2.1 Component Architecture

```
┌─────────────────────────────────────────────────────────────────┐
│                         CLI (musoq)                             │
│  ┌─────────────────────────────────────────────────────────────┐│
│  │ Commands: serve, run, datasource, tool, scripts, registry   ││
│  └─────────────────────────────────────────────────────────────┘│
└────────────────────────────┬────────────────────────────────────┘
                             │ HTTP / Named Pipes
                             ▼
┌─────────────────────────────────────────────────────────────────┐
│                         API Server                              │
│  ┌──────────────┐  ┌──────────────┐  ┌────────────────────────┐ │
│  │ Controllers  │  │ CQRS Handlers│  │ Query Execution Engine │ │
│  └──────────────┘  └──────────────┘  └────────────────────────┘ │
└────────────────────────────┬────────────────────────────────────┘
                             │
                             ▼
┌─────────────────────────────────────────────────────────────────┐
│                      Data Source Plugins                        │
│  ┌──────────┐  ┌──────────┐  ┌──────────┐  ┌─────────────────┐  │
│  │ .NET     │  │ Python   │  │ Built-in │  │ External (.zip) │  │
│  │ Plugins  │  │ Plugins  │  │ Sources  │  │ Packages        │  │
│  └──────────┘  └──────────┘  └──────────┘  └─────────────────┘  │
└─────────────────────────────────────────────────────────────────┘
```

### 2.2 Communication Model

The CLI communicates with the API server through:

1. **HTTP REST API**: For management operations
2. **Named Pipes**: For pipe feeding data into queries

### 2.3 Server Lifecycle

The server operates in two modes:

| Mode | Command | Behavior |
|------|---------|----------|
| Background | `musoq serve` | Starts as detached process, returns immediately |
| Foreground | `musoq serve --wait-until-exit` | Blocks until explicitly stopped |

---

## 3. Installation & Environment

### 3.1 Prerequisites

| Requirement | Version | Purpose |
|-------------|---------|---------|
| Python (optional) | 3.12 | Python plugin support via Python.NET |

---

## 4. Server Commands

### 4.1 serve - Start Server

Start the local server.

```
musoq serve [options]
```

**Options:**

| Option | Description | Default |
|--------|-------------|---------|
| `--wait-until-exit` | Run in foreground, block until stopped | false |
| `--auto-shutdown` | Enable auto-shutdown after idle period | false |
| `--is-independent-process` | Internal flag for subprocess mode | false |

**Examples:**

```bash
# Start server in background (returns immediately)
musoq serve

# Start server in foreground (blocks)
musoq serve --wait-until-exit

# Start with auto-shutdown enabled (shuts down after 10 minutes of inactivity)
musoq serve --wait-until-exit --auto-shutdown
```

**Output on Success:**
```
███    ███ ██    ██ ███████  ██████   ██████ 
████  ████ ██    ██ ██      ██    ██ ██    ██
██ ████ ██ ██    ██ ███████ ██    ██ ██    ██ 
██  ██  ██ ██    ██      ██ ██    ██ ██ ▄▄ ██
██      ██  ██████  ███████  ██████   ██████  
                                         ▀▀   
Server is up and running
```

### 4.2 quit - Stop Server

Stop the running Musoq server.

```
musoq quit
```

**Exit Codes:**
- `0`: Server stopped successfully
- `2`: Server was not running or communication failed

---

## 5. Query Execution

### 5.1 run - Execute Queries

Execute SQL queries from strings, script names, or files.

```
musoq run <input> [options]
```

**Arguments:**

| Argument | Description |
|----------|-------------|
| `<input>` | SQL query string, script name, or file path (with `--from-file`) |

**Options:**

| Option | Description | Default |
|--------|-------------|---------|
| `--bucket <name>` | Bucket name for query context | None |
| `--format <format>` | Output format (see table below) | `table` |
| `--execute <expr>` | Expression to execute on results | None |
| `--debug` | Show transformed query before execution | false |
| `--unquoted` | Disable quoting in CSV output | false |
| `--no-header` | Skip header row in output | false |
| `--stacktrace` | Include stack trace in error output | false |
| `--execution-details` | Show execution phase and progress details | false |
| `--from-file` | Treat input as file path | false |

**Examples:**

```bash
# Execute inline query
musoq run "SELECT 1 FROM #system.dual()"

# Execute with JSON output
musoq run "SELECT * FROM #os.files('.')" --format json

# Execute script by name (looks up in ~/.musoq/Scripts/)
musoq run my_script

# Execute from file
musoq run ./queries/analysis.sql --from-file

# Debug mode - shows the actual query sent to the server
musoq run "SELECT * FROM #os.files('.')" --debug

# Pipe-friendly CSV output without headers
musoq run "SELECT Name, Size FROM #os.files('.')" --format csv --no-header

# Show execution progress for long-running queries
musoq run "SELECT * FROM #os.files('/', true)" --execution-details
```

### 5.2 Standard Input Piping

Queries can reference piped data using the `#stdin` schema:

```bash
# Pipe CSV data
cat data.csv | musoq run "SELECT * FROM #stdin.csv(true, 0)"

# Pipe JSON data
cat data.json | musoq run "SELECT * FROM #stdin.json()"

# Chain with other tools
curl https://api.example.com/data | musoq run "SELECT id, name FROM #stdin.json() WHERE active = true"
```

### 5.3 Output Formats

| Format | Response Format | Description | Use Case |
|--------|-----------------|-------------|----------|
| `table` | raw | ASCII table (default) | Human-readable terminal output |
| `json` | json | JSON array of objects | API integration, jq processing |
| `csv` | csv | Comma-separated values | Spreadsheet import, further processing |
| `yaml` | yaml | YAML format | Configuration files, readability |
| `raw` | raw | Raw values, newline-separated | Simple scripting |
| `interpreted_json` | json | Interpreted JSON (preserves structure) | Structured data extraction |
| `reconstructed_json` | json | Reconstructed JSON (path-value mode) | Flattened JSON output |
| `interpreted_yaml` | yaml | Interpreted YAML (preserves structure) | Structured data as YAML |
| `reconstructed_yaml` | yaml | Reconstructed YAML (path-value mode) | Flattened YAML output |

### 5.4 Script Resolution

When the input doesn't look like a SQL query, the CLI attempts to resolve it as a script:

1. Check if input ends with `.sql` - treat as script name
2. Look up script in `~/.musoq/Scripts/{name}.sql`
3. If found, execute the script contents
4. If not found, treat input as a raw query

### 5.5 Query Transformation

The CLI performs the following transformations before execution:

1. **Expression to Query**: Simple expressions like `1 + 1` are wrapped in `SELECT ... FROM #system.dual()`
2. **Stdin Rewriting**: References to `#stdin` are rewritten with appropriate model configurations for AI extraction

---

## 6. Data Source Management

The `datasource` command manages installed data source plugins, including both .NET assemblies and Python scripts.

### 6.1 Plugin Types

| Type | Description | Location |
|------|-------------|----------|
| `DotNet` | Compiled .NET assemblies | `~/.musoq/DataSources/` |
| `Python` | Python v.2 plugin projects | `~/.musoq/Python/Scripts/` |
| `BuiltIn` | Plugins bundled with Musoq | Application directory |

### 6.2 datasource list

List all installed data sources.

```
musoq datasource list
```

**Output Columns:**

| Column | Description |
|--------|-------------|
| Name | Data source identifier (used in `datasource show`) |
| Version | Installed version (semantic versioning) |
| Type | Plugin type: `DotNet`, `Python`, or `BuiltIn` |
| Enabled | Whether the data source is active (`Yes`/`No`) |
| Installed At | Installation timestamp (UTC) |

**Example Output:**
```
┌──────────────────────────────┬─────────┬────────┬─────────┬─────────────────────┐
│ Name                         │ Version │ Type   │ Enabled │ Installed At        │
├──────────────────────────────┼─────────┼────────┼─────────┼─────────────────────┤
│ Musoq.DataSources.Roslyn     │ 7.2.0   │ DotNet │ Yes     │ 2024-12-15 10:30:00 │
│ weather_api                  │ 1.0.0   │ Python │ Yes     │ 2024-12-16 14:20:00 │
└──────────────────────────────┴─────────┴────────┴─────────┴─────────────────────┘
```

### 6.3 datasource show

Show detailed information about a specific data source.

```
musoq datasource show <name>
```

**Output Fields:**

| Field | Description |
|-------|-------------|
| Name | Data source identifier |
| Version | Installed version |
| Type | Plugin type |
| Enabled | Active status |
| Installed | Installation timestamp |
| Path | Filesystem path to the plugin |
| Entry Point | Main assembly or script file |
| Architecture | Target architecture (x64, arm64, any) |
| Platform | Target platform (windows, linux, osx, any) |

**Example Output:**
```
Musoq.DataSources.Roslyn

Version:      7.2.0
Type:         DotNet
Enabled:      Yes
Installed:    2024-12-15 10:30:00
Path:         /home/user/.musoq/DataSources/Musoq.DataSources.Roslyn
Entry Point:  Musoq.DataSources.Roslyn.dll
Architecture: x64
Platform:     linux
```

### 6.4 datasource install

Install a data source from the plugin registry.

```
musoq datasource install <name> [options]
```

**Arguments:**

| Argument | Description |
|----------|-------------|
| `<name>` | Plugin name (short or full, e.g., `roslyn` or `Musoq.DataSources.Roslyn`) |

**Options:**

| Option | Description | Default |
|--------|-------------|---------|
| `-v, --version <VERSION>` | Specific version to install | latest |
| `--offline` | Use cached registry only | false |
| `--non-interactive` | Plain text progress output (for CI/CD) | false |

**Examples:**

```bash
# Install latest version (uses short name)
musoq datasource install roslyn

# Install using full package name
musoq datasource install Musoq.DataSources.Roslyn

# Install specific version
musoq datasource install Musoq.DataSources.Roslyn --version 7.1.0

# Non-interactive mode for CI/CD pipelines
musoq datasource install Musoq.DataSources.Roslyn --non-interactive
```

**Interactive Progress:**
```
Installing Musoq.DataSources.Roslyn v7.2.0...
  ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━ 100% 0:00:02
✓ Successfully installed Musoq.DataSources.Roslyn (v7.2.0)
```

### 6.5 datasource import

Import a data source from a local path or zip file.

```
musoq datasource import <path> [options]
```

**Arguments:**

| Argument | Description |
|----------|-------------|
| `<path>` | Path to plugin directory or zip file |

**Options:**

| Option | Description | Default |
|--------|-------------|---------|
| `--name <name>` | Custom name for imported plugin | Derived from path |
| `--non-interactive` | Plain text progress output | false |

**Examples:**

```bash
# Import from directory
musoq datasource import /path/to/plugin

# Import from zip file
musoq datasource import ./plugin.zip

# Import with custom name
musoq datasource import ./plugin.zip --name my-custom-plugin
```

### 6.6 datasource uninstall

Uninstall a data source.

```
musoq datasource uninstall <name>
```

**Example:**
```bash
musoq datasource uninstall Musoq.DataSources.Roslyn
# Output: Successfully uninstalled data source 'Musoq.DataSources.Roslyn'
```

### 6.7 datasource create

Create a new Python data source from a template.

```
musoq datasource create <name> [options]
```

**Arguments:**

| Argument | Description |
|----------|-------------|
| `<name>` | Name for the new Python data source (alphanumeric, underscores allowed) |

**Options:**

| Option | Description | Default |
|--------|-------------|---------|
| `-t, --template <template>` | Template type | `basic` |

**Available Templates:**

| Template | Description | Use Case |
|----------|-------------|----------|
| `basic` | Minimal plugin with single data source | Simple data providers |
| `api` | HTTP API integration template | REST API wrappers |
| `database` | Database connection template | Database connectors |

**Examples:**

```bash
# Create basic plugin
musoq datasource create weather_data

# Create API-based plugin
musoq datasource create github_stats --template api

# Create database plugin
musoq datasource create postgres_analytics --template database
```

### 6.8 datasource search

Search for data sources in the plugin registry.

```
musoq datasource search [query] [options]
```

**Arguments:**

| Argument | Description |
|----------|-------------|
| `[query]` | Optional search term (searches name, description, tags) |

**Options:**

| Option | Description | Default |
|--------|-------------|---------|
| `--offline` | Search cached registry only | false |

**Examples:**

```bash
# List all available plugins
musoq datasource search

# Search for specific plugin
musoq datasource search postgres

# Search by tag
musoq datasource search database
```

**Example Output:**
```
┌──────────┬─────────────────────────────────┬─────────┬────────────────────────────────┐
│ Name     │ Full Name                       │ Version │ Description                    │
├──────────┼─────────────────────────────────┼─────────┼────────────────────────────────┤
│ postgres │ Musoq.DataSources.Postgres      │ 7.2.0   │ Query PostgreSQL databases     │
│ sqlite   │ Musoq.DataSources.SQLite        │ 7.2.0   │ Query SQLite databases         │
└──────────┴─────────────────────────────────┴─────────┴────────────────────────────────┘

Hint: Use 'musoq datasource install <name>' to install a plugin.
```

### 6.9 datasource folder

Show or open the data sources folder.

```
musoq datasource folder [name] [options]
```

**Arguments:**

| Argument | Description |
|----------|-------------|
| `[name]` | Optional: specific data source name |

**Options:**

| Option | Description |
|--------|-------------|
| `--open` | Open folder in file explorer |

**Examples:**

```bash
# Show root data sources folder path
musoq datasource folder
# Output: /home/user/.musoq/DataSources

# Open specific plugin folder
musoq datasource folder my_plugin --open

# Open root folder
musoq datasource folder --open
```

---

## 7. Python Plugin Development

Python plugins enable developers to create custom data sources using Python scripts. Musoq uses Python.NET to integrate Python code into the query engine.

### 7.1 Plugin Version

Musoq supports **v.2** Python plugins exclusively. The v.2 format uses a project-based structure with a directory containing `main.py` as the entry point. Flat `.py` files (v.1 format) are **no longer supported**.

### 7.2 Project Structure

Every v.2 plugin is a project directory:

```
~/.musoq/Python/Scripts/
└── my_plugin/                    # Plugin project name
    ├── main.py                   # REQUIRED: Plugin entry point
    ├── requirements.txt          # Optional: Python dependencies (auto-installed)
    ├── project.json              # Optional: Plugin metadata
    └── helpers.py                # Optional: Supporting modules
```

**Key Requirements:**

- `main.py` is **required** and must contain the `DataPlugin` class
- Project name (directory name) must be alphanumeric with underscores
- Additional `.py` files are optional for code organization
- Plugin is automatically discovered when directory contains `main.py`

### 7.3 DataPlugin Contract

Every Python plugin must implement this exact contract:

```python
class DataPlugin:
    """Complete v.2 plugin contract - ALL METHODS REQUIRED"""
    
    def schema_name(self) -> str:
        """
        Return the schema name used in SQL queries.
        Must be alphanumeric (underscores allowed), unique across plugins.
        
        Example: return "mydata"
        SQL Usage: SELECT * FROM #mydata.method()
        """
        pass
    
    def data_sources(self) -> list[str]:
        """
        Return list of data source method names.
        Each name becomes a SQL-callable method.
        
        Example: return ["users", "posts", "summary"]
        """
        pass
    
    def schemas(self) -> dict[str, dict[str, str]]:
        """
        Return column schemas for each data source.
        Keys MUST match data_sources() names.
        
        Example:
            return {
                "users": {"id": "int", "name": "str", "email": "str"},
                "posts": {"id": "int", "user_id": "int", "title": "str"}
            }
        """
        pass
    
    def initialize(self) -> None:
        """Initialize plugin (called once at load time)."""
        pass
    
    def get_required_env_vars(self, method_name: str) -> dict[str, bool]:
        """
        Return required environment variables for method.
        True = required (query fails if missing)
        False = optional (uses default)
        
        Example: return {"API_KEY": True, "API_ENDPOINT": False}
        """
        pass
    
    def get_required_execute_arguments(self, method_name: str) -> list[tuple[str, str]]:
        """
        Return parameter definitions for method.
        
        Example: return [("minimum_id", "int"), ("name_filter", "str")]
        """
        pass
    
    def execute(self, method_name: str, environment_variables: dict[str, str], *args):
        """
        Execute data source method and yield rows.
        
        Args:
            method_name: Data source method to execute
            environment_variables: Runtime environment variables
            *args: Parameters from SQL query
        
        MUST be a generator (use yield, not return).
        MUST yield dictionaries with keys matching schema.
        """
        pass
    
    def dispose(self) -> None:
        """Cleanup resources (called at unload)."""
        pass

# Module-level instance (REQUIRED)
plugin = DataPlugin()
```

### 7.4 Supported Types

| Type String | Python Type | SQL Type | Example |
|-------------|-------------|----------|---------|
| `"int"` | `int` | INTEGER | `42` |
| `"str"` | `str` | VARCHAR | `"hello"` |
| `"float"` | `float` | FLOAT | `3.14` |
| `"bool"` | `bool` | BOOLEAN | `True` |
| `"datetime"` | `str` | DATETIME | `"2024-12-01 15:30:00"` |

**DateTime Format:** Use ISO 8601 format: `YYYY-MM-DD HH:MM:SS`

### 7.5 Automatic Dependency Installation

When a plugin includes `requirements.txt`, Musoq automatically installs dependencies during plugin discovery:

**requirements.txt:**
```txt
requests>=2.31.0
pandas==2.1.0
python-dateutil>=2.8.2
```

### 7.6 Local Module Imports

Python plugins can import from local modules in the same directory:

**Project Structure:**
```
~/.musoq/Python/Scripts/hackernews/
├── main.py          # Entry point
├── http_client.py   # HTTP utilities
├── parsers.py       # Data parsing logic
└── requirements.txt # External dependencies
```

**main.py:**
```python
from http_client import fetch_json
from parsers import parse_story

class DataPlugin:
    def execute(self, method_name, environment_variables, *args):
        data = fetch_json("https://api.example.com/stories")
        for item in data:
            yield parse_story(item)

plugin = DataPlugin()
```

### 7.7 Environment Variables

Access environment variables in the `execute` method:

```python
def execute(self, method_name, environment_variables, *args):
    # Get with default
    api_key = environment_variables.get("API_KEY", "")
    endpoint = environment_variables.get("API_URL", "https://default.com")
    
    # Get with validation
    api_key = environment_variables.get("API_KEY")
    if not api_key:
        raise ValueError("API_KEY required")
    
    # Type conversion
    timeout = int(environment_variables.get("TIMEOUT", "30"))
```

### 7.8 Complete Example

**main.py:**
```python
"""Weather data plugin with current and forecast data sources."""
from datetime import datetime

class DataPlugin:
    def schema_name(self):
        return "weather"
    
    def data_sources(self):
        return ["current", "forecast"]
    
    def schemas(self):
        return {
            "current": {
                "city": "str",
                "temperature": "float",
                "humidity": "int",
                "conditions": "str",
                "timestamp": "datetime"
            },
            "forecast": {
                "city": "str",
                "date": "str",
                "high_temp": "float",
                "low_temp": "float",
                "precipitation": "int"
            }
        }
    
    def initialize(self):
        pass
    
    def get_required_env_vars(self, method_name):
        return {"WEATHER_API_KEY": True, "WEATHER_API_URL": False}
    
    def get_required_execute_arguments(self, method_name):
        return [("city", "str")]
    
    def execute(self, method_name, environment_variables, *args):
        api_key = environment_variables.get("WEATHER_API_KEY")
        if not api_key:
            raise ValueError("WEATHER_API_KEY required")
        
        city = args[0] if args else "London"
        
        if method_name == "current":
            yield {
                "city": city,
                "temperature": 22.5,
                "humidity": 65,
                "conditions": "Partly Cloudy",
                "timestamp": datetime.now().strftime("%Y-%m-%d %H:%M:%S")
            }
        elif method_name == "forecast":
            for i in range(5):
                yield {
                    "city": city,
                    "date": f"2024-12-{i+1:02d}",
                    "high_temp": 24.0 - i,
                    "low_temp": 15.0 - i,
                    "precipitation": 10 * (i + 1)
                }
    
    def dispose(self):
        pass

plugin = DataPlugin()
```

**SQL Usage:**
```sql
SELECT * FROM #weather.current('Paris')
SELECT * FROM #weather.forecast('London') WHERE precipitation > 20
```

### 7.9 Plugin Metadata (Runtime)

When a Python plugin is loaded, Musoq extracts the following metadata:

| Property | Description |
|----------|-------------|
| `ProjectName` | Directory name containing the plugin |
| `ProjectPath` | Full path to the project directory |
| `MainScriptPath` | Path to `main.py` |
| `SchemaName` | Value from `schema_name()` |
| `DataSources` | List of data source metadata |

**Per Data Source Metadata:**

| Property | Description |
|----------|-------------|
| `Name` | Data source method name |
| `Schema` | Column name → Type mapping |
| `ExecuteArguments` | List of (name, type) tuples |
| `EnvironmentVariables` | Variable name → Required flag |

### 7.10 Testing Python Plugins

**Standalone Testing:**

```python
def main():
    """Test plugin standalone."""
    plugin = DataPlugin()
    plugin.initialize()
    
    test_env = {"WEATHER_API_KEY": "test_key"}
    
    for row in plugin.execute("current", test_env, "Paris"):
        print(f"  {row}")
    
    plugin.dispose()

if __name__ == "__main__":
    main()
```

Run: `python main.py`

**Integration Testing via SQL:**

```sql
-- Test basic execution
SELECT * FROM #weather.current('London')

-- Test with filters
SELECT * FROM #weather.forecast('Paris') WHERE precipitation > 20

-- Test aggregation
SELECT COUNT(*) FROM #weather.forecast('Tokyo')
```

---

## 8. Tool Management

Tools are predefined SQL queries with dynamic parameters, stored as YAML files in `~/.musoq/Tools/`.

### 8.1 tool list

List available tools.

```
musoq tool list [options]
```

**Options:**

| Option | Description | Default |
|--------|-------------|---------|
| `--search <query>` | Filter tools by name or description | None |

**Example Output:**
```
┌──────────────────────┬─────────────────────────────────────────────┐
│ Name                 │ Description                                 │
├──────────────────────┼─────────────────────────────────────────────┤
│ weather              │ Get current weather for a city              │
│ file_analysis        │ Analyze files in a directory                │
│ docker_stats         │ Show container resource usage               │
└──────────────────────┴─────────────────────────────────────────────┘
```

### 8.2 tool show

Show detailed information about a specific tool.

```
musoq tool show <name>
```

**Example Output:**
```
Tool: weather
Description: Get current weather for a city

Query:
  SELECT city, temperature, conditions
  FROM #weather.current('{{city}}')
  WHERE temperature > {{min_temp}}

Output Format: table

Parameters:
  city (string, required)
    City name to query
  
  min_temp (int, optional, default: -50)
    Minimum temperature filter
```

### 8.3 tool execute

Execute a tool with dynamic parameters.

```
musoq tool execute <tool-name> [parameters...] [options]
```

**Parameter Passing:**

Parameters can be passed in two formats:

1. **Positional (key-value pairs):** `param1 value1 param2 value2`
2. **Named:** `--param1 value1 --param2 value2`

**Options:**

| Option | Description | Default |
|--------|-------------|---------|
| `--format <format>` | Output format override | Tool's default |
| `--debug` | Show processed query before execution | false |

**Examples:**

```bash
# Positional parameters
musoq tool execute weather city London

# Named parameters
musoq tool execute weather --city London

# Multiple parameters
musoq tool execute weather city London min_temp 10

# Mixed with options
musoq tool execute weather city London --format json --debug
```

**Debug Output:**
```
Processing query for tool 'weather'...
Processed Query:
  SELECT city, temperature, conditions
  FROM #weather.current('London')
  WHERE temperature > 10

Executing...
```

### 8.4 tool create

Create a new tool from a template.

```
musoq tool create <name>
```

### 8.5 tool folder

Show or open the tools folder.

```
musoq tool folder [options]
```

**Options:**

| Option | Description |
|--------|-------------|
| `--open` | Open folder in file explorer |

**Examples:**

```bash
# Show path
musoq tool folder
# Output: /home/user/.musoq/Tools

# Open folder
musoq tool folder --open
```

### 8.6 Tool Definition Format (YAML)

Tools are defined in YAML files with the following schema:

```yaml
name: weather
description: Get current weather for a city
query: |
  SELECT city, temperature, conditions
  FROM #weather.current('{{city}}')
  WHERE temperature > {{min_temp}}
output:
  format: table
parameters:
  - name: city
    type: string
    required: true
    description: City name to query
  - name: min_temp
    type: int
    required: false
    default: -50
    description: Minimum temperature filter
```

**Schema Reference:**

| Field | Type | Required | Description |
|-------|------|----------|-------------|
| `name` | string | Yes | Unique tool identifier |
| `description` | string | Yes | Human-readable description |
| `query` | string | Yes | SQL query with `{{parameter}}` placeholders |
| `output.format` | string | No | Default output format |
| `parameters` | array | No | List of parameter definitions |

**Parameter Definition Fields:**

| Field | Type | Required | Description |
|-------|------|----------|-------------|
| `name` | string | Yes | Parameter name (used in placeholders) |
| `type` | string | Yes | One of: `string`, `int`, `long`, `decimal`, `bool`, `datetime` |
| `required` | boolean | Yes | Whether the parameter must be provided |
| `default` | any | No | Default value (for optional parameters) |
| `description` | string | No | Human-readable description |

**Supported Parameter Types:**

| Type | Description | Example Values |
|------|-------------|----------------|
| `string` | Text value | `"London"`, `"SELECT * FROM table"` |
| `int` | 32-bit integer | `42`, `-100` |
| `long` | 64-bit integer | `9223372036854775807` |
| `decimal` | High-precision decimal | `123.456789` |
| `bool` | Boolean | `true`, `false` |
| `datetime` | ISO 8601 date/time | `"2024-12-01"`, `"2024-12-01 15:30:00"` |

### 8.7 Advanced Tool Examples

**File Analysis Tool:**
```yaml
name: file_analysis
description: Analyze files in a directory by extension
query: |
  SELECT 
    Extension,
    COUNT(*) AS FileCount,
    SUM(Size) AS TotalSize
  FROM #system.directory('{{path}}', {{recursive}})
  GROUP BY Extension
  ORDER BY TotalSize DESC
output:
  format: table
parameters:
  - name: path
    type: string
    required: true
    description: Directory path to analyze
  - name: recursive
    type: bool
    required: false
    default: false
    description: Include subdirectories
```

**Docker Container Stats:**
```yaml
name: docker_stats
description: Show container resource usage
query: |
  SELECT 
    Name,
    Status,
    CpuPercent,
    MemoryUsage,
    NetworkIn,
    NetworkOut
  FROM #docker.containers()
  WHERE Status = 'running'
    AND CpuPercent > {{min_cpu}}
output:
  format: table
parameters:
  - name: min_cpu
    type: decimal
    required: false
    default: 0.0
    description: Minimum CPU percentage filter
```

---

## 9. Scripts Management

SQL scripts are stored files in `~/.musoq/Scripts/` that can be executed by name.

### 9.1 scripts list

List all SQL scripts.

```
musoq scripts list
```

**Output Columns:**

| Column | Description |
|--------|-------------|
| Name | Script filename (without .sql extension) |
| Created | Creation timestamp |
| Modified | Last modification timestamp |

**Example Output:**
```
┌──────────────────────┬─────────────────────┬─────────────────────┐
│ Name                 │ Created             │ Modified            │
├──────────────────────┼─────────────────────┼─────────────────────┤
│ daily_report         │ 2024-12-01 10:00:00 │ 2024-12-15 14:30:00 │
│ file_analysis        │ 2024-12-10 08:00:00 │ 2024-12-10 08:00:00 │
│ container_health     │ 2024-12-12 16:45:00 │ 2024-12-14 09:15:00 │
└──────────────────────┴─────────────────────┴─────────────────────┘
```

### 9.2 scripts create

Create a new SQL script and open in editor.

```
musoq scripts create <name>
```

**Examples:**

```bash
# Create script (opens in editor)
musoq scripts create my_analysis

# Extension is added automatically
musoq scripts create my_analysis.sql  # Same result
```

**Default Template:**
```sql
-- Script: my_analysis
-- Created: 2024-12-15 10:30:00
-- 
-- Write your SQL query below:

SELECT * FROM #system.dual()
```

### 9.3 scripts update

Open an existing SQL script in the default editor.

```
musoq scripts update <name>
```

**Example:**
```bash
musoq scripts update daily_report
# Opens ~/.musoq/Scripts/daily_report.sql in default editor
```

### 9.4 scripts delete

Delete an SQL script.

```
musoq scripts delete <name>
```

**Example:**
```bash
musoq scripts delete old_report
# Output: Successfully deleted script 'old_report'
```

### 9.5 scripts folder

Show or open the SQL scripts folder.

```
musoq scripts folder [options]
```

**Options:**

| Option | Description |
|--------|-------------|
| `--open` | Open folder in file explorer |

**Examples:**

```bash
# Show path
musoq scripts folder
# Output: /home/user/.musoq/Scripts

# Open folder
musoq scripts folder --open
```

### 9.6 Running Scripts

Scripts can be executed using the `run` command with the `@` prefix:

```bash
# Run by script name
musoq run @daily_report

# Run with output format
musoq run @file_analysis --format json
```

See Section 5 (Query Execution) for complete `run` command options.

---

## 10. Registry Management

Registries are sources for discovering and downloading data source plugins.

### 10.1 registry list

List all configured registries.

```
musoq registry list [options]
```

**Options:**

| Option | Description | Default |
|--------|-------------|---------|
| `--enabled-only` | Show only enabled registries | false |

**Output Columns:**

| Column | Description |
|--------|-------------|
| Name | Registry identifier |
| URL | Registry endpoint URL |
| Default | Whether this is the default registry |
| Enabled | Whether the registry is active |
| Added At | Registration timestamp |

**Example Output:**
```
┌──────────┬────────────────────────────────────────────────────────────────────────────────────────────────────────────┬─────────┬─────────┬─────────────────────┐
│ Name     │ URL                                                                                                        │ Default │ Enabled │ Added At            │
├──────────┼────────────────────────────────────────────────────────────────────────────────────────────────────────────┼─────────┼─────────┼─────────────────────┤
│ official │ https://github.com/Puchaczov/Musoq.DataSources/releases/download/plugin-registry/plugin-registry.json      │ Yes     │ Yes     │ 2024-01-01 00:00:00 │
│ custom   │ https://internal.company.com/registry.json                                                                 │ No      │ Yes     │ 2024-12-01 10:00:00 │
└──────────┴────────────────────────────────────────────────────────────────────────────────────────────────────────────┴─────────┴─────────┴─────────────────────┘
```

### 10.2 registry show

Show detailed information about a registry.

```
musoq registry show <name>
```

**Example Output:**
```
Registry: official

URL:         https://registry.musoq.io/plugins.json
Default:     Yes
Enabled:     Yes
Added At:    2024-01-01 00:00:00
Description: Official Musoq plugin registry
```

### 10.3 registry add

Add a new registry.

```
musoq registry add <name> <url> [options]
```

**Options:**

| Option | Description |
|--------|-------------|
| `--default` | Set as default registry |
| `--description <text>` | Registry description |
| `--token <token>` | Authentication token (for private registries) |

**Examples:**

```bash
# Add registry
musoq registry add custom https://example.com/registry.json

# Add as default
musoq registry add internal https://internal.com/registry.json --default

# Add with authentication
musoq registry add private https://private.com/registry.json --token "abc123"

# Add with description
musoq registry add backup https://backup.com/registry.json --description "Backup registry"
```

### 10.4 registry remove

Remove a registry.

```
musoq registry remove <name> [options]
```

**Options:**

| Option | Description |
|--------|-------------|
| `--force` | Force removal of system registries |

**Examples:**

```bash
# Remove custom registry
musoq registry remove custom

# Force remove (even if system registry)
musoq registry remove official --force
```

### 10.5 registry update

Update registry configuration.

```
musoq registry update <name> [options]
```

**Options:**

| Option | Description |
|--------|-------------|
| `--url <url>` | New registry URL |
| `--description <text>` | New description |

**Examples:**

```bash
# Update URL
musoq registry update custom --url https://new-url.com/registry.json

# Update description
musoq registry update custom --description "Updated description"
```

### 10.6 registry set-default

Set a registry as the default.

```
musoq registry set-default <name>
```

**Example:**
```bash
musoq registry set-default custom
# Output: Registry 'custom' is now the default
```

### 10.7 Registry File Format

Registries use a JSON format to define available plugins:

```json
{
  "plugins": [
    {
      "name": "Musoq.DataSources.Roslyn",
      "shortName": "roslyn",
      "description": "Query C# code with Roslyn",
      "tags": ["code", "csharp", "analysis"],
      "versions": [
        {
          "version": "7.2.0",
          "releaseDate": "2024-12-01",
          "downloadUrl": "https://...",
          "sha256": "abc123...",
          "platforms": ["windows-x64", "linux-x64", "osx-x64"]
        }
      ]
    }
  ]
}
```

---

## 11. Configuration Management

### 11.1 set - Set Configuration Values

```
musoq set <setting> <value>
```

**Available Settings:**

| Setting | Description | Example |
|---------|-------------|---------|
| `organization-id` | Organization identifier | `musoq set organization-id org-123` |
| `api-key` | API authentication key | `musoq set api-key key-abc-123` |
| `labels` | Agent labels (space-separated) | `musoq set labels prod us-east` |
| `update-data-sources` | Auto-update data sources | `musoq set update-data-sources true` |
| `sso-url` | SSO authentication URL | `musoq set sso-url https://...` |
| `agent-name` | Agent display name | `musoq set agent-name my-agent` |
| `log-path` | Log file directory | `musoq set log-path /var/log/musoq` |
| `environment-variable` | Set environment variable | `musoq set environment-variable KEY value` |

### 11.2 get - Get System Information

```
musoq get <info>
```

**Available Information:**

| Info | Description |
|------|-------------|
| `data-sources` | List loaded data sources |
| `server-version` | Show server version |
| `environment-variables` | List environment variables |
| `environment-variables-file-path` | Path to env vars file |
| `is-running` | Check if server is running |
| `server-port` | Get server port number |
| `licenses` | Show license information |
| `startup-metrics` | Show startup performance metrics |

**Options for `environment-variables`:**

| Option | Description |
|--------|-------------|
| `--show-sensitive` | Include sensitive values |

**Examples:**

```bash
# Check if server is running
musoq get is-running
# Output: Server is running on port 5000

# or
# Output: Server is not running

# List data sources with details
musoq get data-sources

# Show environment variables (masked)
musoq get environment-variables

# Show environment variables (including sensitive)
musoq get environment-variables --show-sensitive

# Get server version
musoq get server-version
# Output: Musoq v1.0.0

# Get startup performance metrics
musoq get startup-metrics
```

### 11.3 clear - Clear Configuration Values

```
musoq clear <setting>
```

All settings available in `set` can be cleared with `clear`.

**Examples:**

```bash
musoq clear organization-id
musoq clear environment-variable MY_VAR
musoq clear labels
```

---

## 12. Bucket Management

Buckets provide isolated contexts for query execution with preloaded data.

### 12.1 bucket list

List all storage buckets.

```
musoq bucket list
```

**Example Output:**
```
┌──────────────┬─────────────────────┬──────────┐
│ Name         │ Created             │ Items    │
├──────────────┼─────────────────────┼──────────┤
│ my-data      │ 2024-12-01 10:00:00 │ 3        │
│ test-env     │ 2024-12-05 14:30:00 │ 1        │
└──────────────┴─────────────────────┴──────────┘
```

### 12.2 bucket create

Create a new storage bucket.

```
musoq bucket create <name>
```

**Example:**
```bash
musoq bucket create analytics-data
# Output: Bucket 'analytics-data' created successfully
```

### 12.3 bucket delete

Delete a storage bucket.

```
musoq bucket delete <name>
```

**Example:**
```bash
musoq bucket delete old-data
# Output: Bucket 'old-data' deleted successfully
```

### 12.4 Using Buckets in Queries

Buckets allow you to preload data and reference it in queries:

```bash
# Create bucket
musoq bucket create my-data

# Run query with bucket context
musoq run "SELECT * FROM #bucket.table()" --bucket my-data
```

---

## 13. Utility Commands

### 13.1 log - Show Query Logs

Show recent query execution logs.

```
musoq log [options]
```

**Options:**

| Option | Description | Default |
|--------|-------------|---------|
| `--count <n>` | Number of log entries to show | 10 |

**Example:**
```bash
musoq log --count 5
```

**Example Output:**
```
Query Log (Last 5 entries):

[2024-12-15 14:30:45] SELECT * FROM #system.dual()
  Status: Success | Duration: 23ms | Rows: 1

[2024-12-15 14:28:12] SELECT Name, Size FROM #system.directory('.', true)
  Status: Success | Duration: 156ms | Rows: 42

[2024-12-15 14:25:00] SELECT * FROM #weather.current('London')
  Status: Error | Duration: 2500ms | Error: API_KEY not set
```

### 13.2 separator - Input Stream Separator

Insert a separator in the input stream (for piped input processing).

```
musoq separator
```

This command is used when piping multiple queries through stdin to mark boundaries between queries.

### 13.3 image encode - Encode Image to Base64

Convert an image file to base64 encoding for use in queries.

```
musoq image encode <file>
```

**Example:**

```bash
musoq image encode photo.jpg
# Output: data:image/jpeg;base64,/9j/4AAQSkZJRg...
```

### 13.4 api - List API Endpoints

List available REST API endpoints.

```
musoq api [options]
```

**Options:**

| Option | Description |
|--------|-------------|
| `--format <format>` | Output format: `table`, `json` |

### 13.5 quit - Stop Server

Stop the running Musoq server.

```
musoq quit
```

**Example:**
```bash
musoq quit
# Output: Server shutdown complete
```

---

## 14. API Reference

The server exposes a REST API for programmatic access. By default, the server listens on `http://localhost:8585`. Complete API documentation is available via Swagger UI at `http://localhost:8585/swagger`.

### 14.1 Core Endpoints

| Method | Endpoint | Description |
|--------|----------|-------------|
| GET | `/application/server-version` | Get server version |
| GET | `/application/is-ready` | Check server readiness |
| GET | `/application/startup-metrics` | Get startup metrics |
| GET | `/application/server-metrics` | Get runtime metrics |
| POST | `/application/quit` | Shutdown server |

**Example - Get Server Version:**
```bash
curl http://localhost:8585/application/server-version
```
```json
{
  "version": "1.0.0",
  "buildDate": "2024-12-15T10:00:00Z"
}
```

### 14.2 Query Execution

| Method | Endpoint | Description |
|--------|----------|-------------|
| POST | `/local/execute` | Execute SQL query |

**Request Body:**

```json
{
  "script": "SELECT * FROM #system.dual()",
  "format": "json",
  "bucket": "optional-bucket-name",
  "unquoted": false,
  "noHeader": false,
  "executionDetails": false
}
```

**Response (format: json):**
```json
{
  "columns": ["Column1"],
  "rows": [
    {"Column1": 1}
  ],
  "executionDetails": {
    "duration": "00:00:00.023",
    "rowCount": 1
  }
}
```

### 14.3 Data Sources

| Method | Endpoint | Description |
|--------|----------|-------------|
| GET | `/data-sources` | List loaded data sources |
| GET | `/data-sources/installed` | List installed plugins |
| GET | `/data-sources/installed/{name}` | Get plugin details |
| POST | `/data-sources/install` | Install plugin |
| POST | `/data-sources/install-stream` | Install with progress streaming |
| DELETE | `/data-sources/installed/{name}` | Uninstall plugin |
| GET | `/data-sources/folder` | Get plugins folder path |
| GET | `/data-sources/registry` | Search plugin registry |
| POST | `/data-sources/force-refresh` | Refresh data sources |

**Example - List Installed Plugins:**
```bash
curl http://localhost:5000/data-sources/installed
```
```json
{
  "plugins": [
    {
      "name": "Musoq.DataSources.Roslyn",
      "version": "7.2.0",
      "type": "DotNet",
      "enabled": true,
      "installedAt": "2024-12-15T10:00:00Z"
    }
  ]
}
```

### 14.4 Tools

| Method | Endpoint | Description |
|--------|----------|-------------|
| GET | `/tools/management` | List tools |
| GET | `/tools/management/{name}` | Get tool details |
| POST | `/tools/management` | Create tool |
| PUT | `/tools/management/{name}` | Update tool |
| DELETE | `/tools/management/{name}` | Delete tool |
| POST | `/tools/management/{name}/execute` | Execute tool |
| GET | `/tools/management/folder` | Get tools folder path |

**Example - Execute Tool:**
```bash
curl -X POST http://localhost:5000/tools/management/weather/execute \
  -H "Content-Type: application/json" \
  -d '{"parameters": {"city": "London"}}'
```

### 14.5 Scripts

| Method | Endpoint | Description |
|--------|----------|-------------|
| GET | `/scripts` | List scripts |
| POST | `/scripts` | Create script |
| GET | `/scripts/{name}/path` | Get script file path |
| DELETE | `/scripts/{name}` | Delete script |
| GET | `/scripts/folder` | Get scripts folder path |

### 14.6 Registries

| Method | Endpoint | Description |
|--------|----------|-------------|
| GET | `/registries` | List registries |
| GET | `/registries/{name}` | Get registry details |
| POST | `/registries` | Add registry |
| PUT | `/registries/{name}` | Update registry |
| DELETE | `/registries/{name}` | Remove registry |
| POST | `/registries/{name}/set-default` | Set default |

### 14.7 Settings & Environment

| Method | Endpoint | Description |
|--------|----------|-------------|
| POST | `/settings` | Set configuration |
| DELETE | `/settings` | Clear configuration |
| GET | `/environment-variables` | List env vars |
| POST | `/environment-variable` | Set env var |
| GET | `/application/environment-variables-file-path` | Get env file path |

### 14.8 Buckets

| Method | Endpoint | Description |
|--------|----------|-------------|
| GET | `/bucket/list` | List buckets |
| POST | `/bucket/create/{name}` | Create bucket |
| DELETE | `/bucket/delete/{name}` | Delete bucket |
| POST | `/bucket/load/{name}` | Load data into bucket |
| POST | `/bucket/unload/{name}` | Unload data from bucket |
| POST | `/bucket/set/{name}` | Set bucket data |
| POST | `/bucket/get/{name}` | Get bucket data |

---

## 15. Exit Codes & Error Handling

The CLI returns the following exit codes:

| Code | Name | Description |
|------|------|-------------|
| 0 | Success | Operation completed successfully |
| 1 | QueryFailure | Query execution failed |
| 2 | ServerCommunicationFailure | Cannot communicate with server |
| 3 | ConfigurationError | Configuration problem |
| 4 | NotFound | Requested resource not found |

### 15.1 Common Error Scenarios

**Server Not Running:**
```
Error: Cannot connect to server.
Hint: Start the server with 'musoq serve'
Exit code: 2
```

**Data Source Not Found:**
```
Error: Data source 'unknown_source' not found.
Hint: Use 'musoq datasource list' to see available data sources
Exit code: 4
```

**Query Syntax Error:**
```
Error: Query execution failed.
  Line 1, Column 8: Expected FROM clause
Exit code: 1
```

**Missing Environment Variable:**
```
Error: Required environment variable 'API_KEY' is not set.
Hint: Use 'musoq set environment-variable API_KEY <value>' to set it
Exit code: 3
```

---

## 16. Configuration Files

### 16.1 appsettings.json

The main configuration file for the server:

**Location:** 
- Windows: `%APPDATA%\Musoq\appsettings.json`
- Linux/macOS: `~/.config/musoq/appsettings.json`

**Example:**
```json
{
  "AutoShutdown": {
    "Enabled": true,
    "IdleTimeoutMinutes": 30
  },
  "Models": {
    "Ollama": {
      "ChatModel": "llama3",
      "EmbeddingModel": "nomic-embed-text",
      "Endpoint": "http://localhost:11434"
    },
    "OpenAi": {
      "ChatModel": "gpt-4",
      "EmbeddingModel": "text-embedding-ada-002"
    }
  },
  "Logging": {
    "LogLevel": {
      "Default": "Information",
      "Microsoft": "Warning"
    }
  }
}
```

### 16.2 settings.json

User-specific settings managed via CLI:

**Location:** `~/.musoq/settings.json`

**Structure:**
```json
{
  "agentName": "my-agent",
  "labels": ["prod", "us-east"],
  "logPath": "/var/log/musoq"
}
```

### 16.3 environment-variables.json

Environment variables for data sources:

**Location:** `~/.musoq/environment-variables.json`

**Structure:**
```json
{
  "API_KEY": "sk-abc123",
  "DATABASE_URL": "postgresql://localhost/mydb",
  "WEATHER_API_KEY": "weather-key-456"
}
```

---

## 17. Examples & Workflows

### 17.1 First-Time Setup

```bash
# Start the server
musoq serve

# Verify server is running
musoq get is-running

# Check available data sources
musoq get data-sources

# Run a simple query
musoq run "SELECT 1 + 1 AS Result FROM #system.dual()"
```

### 17.2 Creating a Python Plugin

```bash
# Create new plugin from template
musoq datasource create weather_api --template api

# Edit the plugin (opens in editor)
# Plugin created at ~/.musoq/Python/Scripts/weather_api/main.py

# Refresh data sources
musoq run "SELECT 1 FROM #system.dual()"  # Triggers reload

# Use the new plugin
musoq run "SELECT * FROM #weather_api.current('London')"
```

### 17.3 Working with Tools

```bash
# List available tools
musoq tool list

# Create a custom tool
musoq tool create daily_report

# Edit the tool definition (YAML)
musoq tool folder --open

# Execute tool with parameters
musoq tool execute daily_report date 2024-01-15 format summary
```

### 17.4 Script-Based Workflow

```bash
# Create a reusable script
musoq scripts create quarterly_analysis

# Edit in your preferred editor
# Script saved to ~/.musoq/Scripts/quarterly_analysis.sql

# Run by name
musoq run @quarterly_analysis

# Run with different output format
musoq run @quarterly_analysis --format json > results.json
```

### 17.5 CI/CD Integration

```bash
#!/bin/bash
# Automated data quality check

# Ensure server is running
musoq serve --auto-shutdown

# Run validation queries with non-interactive output
musoq datasource install Musoq.DataSources.Roslyn --non-interactive

# Execute analysis with JSON output for parsing
result=$(musoq run "
  SELECT Count(1) as ErrorCount 
  FROM #csharp.solution('./MyProject.sln') s
  CROSS APPLY s.Projects p
  WHERE p.HasErrors = true
" --format json)

# Check results
error_count=$(echo $result | jq '.[0].ErrorCount')
if [ "$error_count" -gt 0 ]; then
  echo "Found $error_count projects with errors"
  exit 1
fi

echo "All projects validated successfully"
```

### 17.6 Piping Data

```bash
# Pipe JSON and format as CSV
curl https://api.example.com/data | musoq run "
  SELECT id, name, status
  FROM #stdin.json()
  WHERE status = 'active'
" --format csv > active_records.csv
```

---

## 17. Security Considerations

### 17.1 Sensitive Data

- **Environment Variables:** Stored in `~/.musoq/environment-variables.json`
  - File permissions should be restricted (600 on Unix)
  - Use `musoq get environment-variables` (masked by default)
  - Use `--show-sensitive` only when necessary
  - Use `{{ VAR_NAME}}` syntax in queries to reference environment variables from your operating system

- **API Keys:** Never hardcode in queries or plugins
  - Always use environment variables
  - Consider using secret management tools

### 17.2 Network Security

- **Local Server:** Binds to `localhost` by default (127.0.0.1)
- **Musoq:** Is not intended to be publicly accessible. There is no built-in authentication for external access and leaving endpoints opens to everybody would cause serious security issues.

---
