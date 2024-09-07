# 🚀 Musoq.CLI

[![GitHub license](https://img.shields.io/badge/license-MIT-blue.svg)](https://github.com/yourusername/Musoq.CLI/blob/main/LICENSE)

Musoq.CLI is a powerful command-line interface that brings the magic of [Musoq](https://github.com/Puchaczov/Musoq) to your fingertips. Query various data sources with ease, wherever they reside!

## 🌟 Features

- 🖥️ Spin up a Musoq server
- 🔍 Query diverse data sources
- 🔄 Seamless server-client interaction
- 📊 Multiple output formats (Raw, CSV, JSON, Interpreted JSON)
- 🚫 No additional dependencies required

## 🚀 Quick Start

### With Server Observation

1. 📥 Download the zipped program for your architecture
2. 📂 Unpack to a directory
3. 🖥️ Open first console in the directory
4. 🏃‍♂️ Run the server:
   - Windows: `Musoq.exe serve --wait-until-exit`
   - Linux: `./Musoq serve --wait-until-exit` (use `chmod +x ./Musoq` first)
5. 🖥️ Open second console in the directory
6. 🔍 Run a query:
   - Windows: `Musoq.exe run query "select 1 from #system.dual()"`
   - Linux: `./Musoq run query "select 1 from #system.dual()"`
7. 🛑 To quit the server: `Musoq quit`

### Single Console

1. 📥 Download and unpack as above
2. 🖥️ Open console in the directory
3. 🏃‍♂️ Run the server in background:
   - Windows: `Musoq.exe serve`
   - Linux: `./Musoq serve`
4. 🔍 Run queries as needed
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
Get-Content 'C:\Some\Path\To\Text' | Musoq.exe run query "select l.LicenseNameOnly, l.Copyright, l.FullClause, l.LicenseSimpleDescription from #stdin.text('OpenAi', 'gpt-4o') l"
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
Musoq.exe image encode "C:\Images\Receipt1.jpg" | Musoq.exe run query "select s.Shop, s.ProductName, s.Price from #stdin.image('OpenAi', 'gpt-4o') s"
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
Musoq.exe image encode "C:\Images\Receipt1.jpg" | Musoq.exe run query "table Receipt { Shop 'System.String', ProductName 'System.String', Price 'System.Decimal' }; couple #stdin.image with table Receipt as SourceOfReceipts; select s.Shop, s.ProductName, s.Price from SourceOfReceipts('OpenAi', 'gpt-4o') s"
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

## 🔍 Explore CLI Options

Discover more CLI options with the `--help` command:

```bash
Musoq --help
```

## 🔮 Future Plans

Automating the installation process. Soon, you'll be able to install Musoq.CLI through package managers like `snap` or `chocolatey`. Stay tuned!

## 📄 License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.
