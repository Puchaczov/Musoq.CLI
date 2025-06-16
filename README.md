# 🚀 Musoq.CLI

[![GitHub license](https://img.shields.io/badge/license-MIT-blue.svg)](https://github.com/yourusername/Musoq.CLI/blob/main/LICENSE)

Musoq.CLI is a powerful command-line interface that brings the magic of [Musoq](https://github.com/Puchaczov/Musoq) to your fingertips. Query various data sources with ease, wherever they reside!

## 🌟 Features

- 🖥️ Spin up a Musoq server
- 🔍 Query diverse data sources
- 🔄 Seamless server-client interaction
- 📊 Multiple output formats (Raw, CSV, JSON, Interpreted JSON)
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

Bash:

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

## 🎨 Output Formats

Musoq.CLI supports multiple output formats. Try this query with different formats:

```bash
Musoq run query "select Value, NewId() from #system.range(1, 10)" --format [raw|csv|json|interpreted_json]
```

- 📊 Raw Format

```
Columns:
[{"name":"Value","type":"System.Int64","order":0},{"name":"NewId()","type":"System.String","order":1}]
Rows:
[[{"value":1},{"value":"979d94fa-b4e3-4af4-9124-ec8b9d2ee75d"}],[{"value":2},{"value":"66355215-1349-45f5-9b8c-9aff13ac83f9"}],...]
```

- 📊 CSV Format

```csv
Value,NewId()
1,"fa3765ed-077d-4064-a6fd-a874fdb1e411"
2,"6d205bf8-9588-4d11-b847-48b25b226323"
...
```

- 📊 JSON Format

```json
[{"Value":1,"NewId()":"a3c745da-aef9-4ac3-b149-472af63fe080"},{"Value":2,"NewId()":"0562a629-cbfb-4950-93d5-433c52f17bf3"},...]
```

- 📊 Interpreted JSON Format

For a nested structure, try:

```bash
Musoq run query "select Value as 'obj.Number', NewId() as 'obj.Id' from #system.range(0, 10)" --format interpreted-json
```

Output:
```json
[{"obj":{"Number":0,"Id":"00666e1c-358b-424a-b1bd-2550bb3d3d1d"}},{"obj":{"Number":1,"Id":"fb391e2c-a5d6-479e-9008-a44adddb475a"}},...]
```
</details>

## 🔬 Query Code with SQL

Musoq allows you to query your code using SQL-like syntax. This feature uses **buckets** to manage loaded solutions. 
Buckets are a powerful feature for efficient data management and querying. Here's what you need to know:

- A bucket allows you to load multiple data sources into a single AssemblyLoadContext.
- It preserves loaded data in memory between queries, significantly improving performance.
- Without buckets, each query would create a new AssemblyLoadContext, reloading data every time.
- Using a named bucket lets you load data once and reuse it across multiple queries, saving time and resources.

Here's how to use buckets for code querying:

Create a bucket for various plugin cross requests data

```bash
Musoq bucket create test
```

Then use that bucket to load solution into

```bash
Musoq csharp solution load --solution "mnt\something\repos\Repo.sln" --bucket test
```

Query your solution within a bucket

```bash
Musoq run query "select p.Name from #csharp.solution('mnt\something\repos\Repo.sln') s cross apply s.Projects p" --bucket test
```

After you've done quering, unload solution from the bucket

```bash
Musoq csharp solution unload --solution "mnt\something\repos\Repo.sln" --bucket test
```

Or you can just delete bucket

```bash
Musoq bucket delete test
```

## ⛲ Pipe Extractions

The tool allows to extract various informations from photos (through LLMs providers like OpenAi or Ollama), process CLI tables as they would be native data sources. This way, you can queries and transform those data directly.

### With Powershell

```powershell
//true determine whether table has headers or not
wmic process get name,processid,workingsetsize | Musoq.exe run query "select t.Name, Count(t.Name) from #stdin.table(true) t group by t.Name having Count(t.Name) > 1"
```

Output:

```
┌─────────────────────────┬───────────────┐
│ t.Name                  │ Count(t.Name) │
├─────────────────────────┼───────────────┤
│ csrss.exe               │ 2             │
│ fontdrvhost.exe         │ 2             │
│ svchost.exe             │ 92            │
└─────────────────────────┴───────────────┘
```

### With Bash

```bash
ps -eo comm,pid,rss --sort=-rss | head -n 20 | Musoq.exe run query "select t.COMMAND, t.PID, t.RSS from #stdin.table(true) t"
```

Output:

```bash
┌─────────────────┬───────┬───────┐
│ t.COMMAND       │ t.PID │ t.RSS │
├─────────────────┼───────┼───────┤
│ python3.10      │ 339   │ 47684 │
│ snapd           │ 251   │ 36312 │
│ systemd-journal │ 40    │ 19616 │
│ docker-desktop- │ 2767  │ 17884 │
└─────────────────┴───────┴───────┘
```

### Extracting Structured Output From Text

```powershell
Get-Content 'C:\Some\Path\To\Text' | Musoq.exe run query "select l.LicenseNameOnly, l.Copyright, l.FullClause, l.LicenseSimpleDescription from #stdin.text('from-text-extraction-model') l"
```

Output:

```
┌───────────────────────┬────────────────────────────────────────────────┬─────────────────────────────────────────────────────────────────────────────────┐
│ License               │ Copyright                                      │ LicenseSimpleDescription                                                        │
├───────────────────────┼────────────────────────────────────────────────┼─────────────────────────────────────────────────────────────────────────────────┤
│ The MIT License (MIT) │ Copyright (c) .NET Foundation and Contributors │ Permission is hereby granted, free of charge, to any person obtaining a copy of │
│                       │                                                │ this software and associated documentation files (the 'Software'), to deal in   │
│                       │                                                │ the Software without restriction, including without limitation the rights to    │
│                       │                                                │ use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies   │
│                       │                                                │ of the Software, and to permit persons to whom the Software is furnished to do  │
│                       │                                                │ so, subject to the following conditions: The above copyright notice and this    │
│                       │                                                │ permission notice shall be included in all copies or substantial portions of    │
│                       │                                                │ the Software. THE SOFTWARE IS PROVIDED 'AS IS', WITHOUT WARRANTY OF ANY KIND,   │
│                       │                                                │ EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF              │
│                       │                                                │ MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO    │
│                       │                                                │ EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES   │
│                       │                                                │ OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE,        │
│                       │                                                │ ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER     │
│                       │                                                │ DEALINGS IN THE SOFTWARE.                                                       │
└───────────────────────┴────────────────────────────────────────────────┴─────────────────────────────────────────────────────────────────────────────────┘
```

### Extracting From Image With Query (all columns are strings)

```powershell
Musoq.exe image encode "C:\Images\Receipt1.jpg" | Musoq.exe run query "select s.Shop, s.ProductName, s.Price from #stdin.image('from-image-extraction-model') s"
```

Output:

```
┌─────────────┬─────────────────────────────────────┬─────────┐
│ s.Shop      │ s.ProductName                       │ s.Price │
├─────────────┼─────────────────────────────────────┼─────────┤
│ MEDIAEXPERT │ LOGITECH MOUSE                      │ 59.00   │
└─────────────┴─────────────────────────────────────┴─────────┘
```

### Extracting From Image With Query (columns are extracted with types hinted)

```powershell
Musoq.exe image encode "C:\Images\Receipt1.jpg" | Musoq.exe run query "table Receipt { Shop 'System.String', ProductName 'System.String', Price 'System.Decimal' }; couple #stdin.image with table Receipt as SourceOfReceipts; select s.Shop, s.ProductName, s.Price from SourceOfReceipts('from-image-extraction-model') s"
```

### Combining Multiple Outputs Into One Table

```powershell
& { docker image ls; .\Musoq.exe separator; docker container ls } | ./Musoq.exe run query "select t.IMAGE_ID, t.REPOSITORY, t.SIZE, t.TAG, t2.CONTAINER_ID, t2.CREATED, t2.STATUS from #stdin.table(true) t inner join #stdin.table(true) t2 on t.IMAGE_ID = t2.IMAGE"
```

Output:

```
┌──────────────┬────────────────────────────────────────┬────────┬────────────────────────────────────────┬─────────────────┬───────────────┬──────────────┐
│ t.IMAGE_ID   │ t.REPOSITORY                           │ t.SIZE │ t.TAG                                  │ t2.CONTAINER_ID │ t2.CREATED    │ t2.STATUS    │
├──────────────┼────────────────────────────────────────┼────────┼────────────────────────────────────────┼─────────────────┼───────────────┼──────────────┤
│ cc802bd2841e │ qdrant/qdrant                          │ 275MB  │ latest                                 │ d87759bd4581    │ 3 weeks ago   │ Up 3 weeks   │
│ 878983f8f504 │ redis                                  │ 174MB  │ latest                                 │ 887d68135231    │ 3 weeks ago   │ Up 3 weeks   │
└──────────────┴────────────────────────────────────────┴────────┴────────────────────────────────────────┴─────────────────┴───────────────┴──────────────┘
```

### Extracting Data From Text (using Ollama)

```text
Ticket #: 1234567
Date: 2024-09-07 14:30:22 UTC
Customer: Jane Doe (jane.doe@email.com)
Product: CloudSync Pro v3.5.2
OS: macOS 12.3.1

Subject: Sync Failure and Data Loss

Description:
Customer reported that CloudSync Pro failed to sync properly on 2024-09-06 around 18:45 local time. 
The sync process started but stopped at 43% completion with error code E-1010. 
After the failed sync, the customer noticed that approximately 250 MB of data was missing from their local drive.
The customer has tried restarting the application and their computer, but the issue persists.
They are using CloudSync Pro on 3 devices in total: MacBook Pro, iPhone 13, and iPad Air.

Steps to Reproduce:
1. Open CloudSync Pro v3.5.2 on macOS 12.3.1
2. Initiate a full sync
3. Observe sync progress halting at 43% with error E-1010

Impact: High - Customer cannot sync data and has lost important files

Troubleshooting Attempted:
- Restarted application: No effect
- Restarted computer: No effect
- Checked internet connection: Stable at 100 Mbps

Additional Notes:
Customer is a premium subscriber and requests urgent assistance due to lost data containing work-related documents.
```

```powershell
Get-Content "C:\Tickets\ticket.txt" | ./Musoq.exe run query "select t.TicketNumber, t.TicketDate, t.CustomerName, t.CustomerEmail, t.Product, t.OperatingSystem, t.Subject, t.ImpactLevel, t.ErrorCode, t.DataLossAmount, t.DeviceCount, case when ToLowerInvariant(t.SubscriptionType) like '%premium%' then 'PREMIUM' else 'STANDARD' end from #stdin.text('from-text-extraction-model') t"
```

Output:

```
┌────────────────┬─────────────────────────┬───────────────────────────────┬────────────────────┬──────────────────────┬───────────────────┬────────────────────────────┬───────────────┬─────────────┬──────────────────┬───────────────┬─────────────────────────────────────────────┐
│ t.TicketNumber │ t.TicketDate            │ t.CustomerName                │ t.CustomerEmail    │ t.Product            │ t.OperatingSystem │ t.Subject                  │ t.ImpactLevel │ t.ErrorCode │ t.DataLossAmount │ t.DeviceCount │ case when                                   │
│                │                         │                               │                    │                      │                   │                            │               │             │                  │               │ ToLowerInvariant(t.SubscriptionType) like   │
│                │                         │                               │                    │                      │                   │                            │               │             │                  │               │ %premium% then PREMIUM else STANDARD end    │
├────────────────┼─────────────────────────┼───────────────────────────────┼────────────────────┼──────────────────────┼───────────────────┼────────────────────────────┼───────────────┼─────────────┼──────────────────┼───────────────┼─────────────────────────────────────────────┤
│ 1234567        │ 2024-09-07 14:30:22 UTC │ Jane Doe (jane.doe@email.com) │ jane.doe@email.com │ CloudSync Pro v3.5.2 │ macOS 12.3.1      │ Sync Failure and Data Loss │ High          │ E-1010      │ 250 MB           │ 3             │ PREMIUM                                     │
└────────────────┴─────────────────────────┴───────────────────────────────┴────────────────────┴──────────────────────┴───────────────────┴────────────────────────────┴───────────────┴─────────────┴──────────────────┴───────────────┴─────────────────────────────────────────────┘
```

## 🔍 Explore CLI Options

Discover more CLI options with the `--help` command:

```bash
Musoq --help
```

## 🔮 Future Plans

Automating the installation process. Soon, you'll be able to install Musoq.CLI through package managers like `snap` or `chocolatey`. Stay tuned!

## 📄 License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.
