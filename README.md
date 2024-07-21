# Musoq.CLI

This repository contains `Musoq` command line interface. It allows to spin up Musoq server and query various data sources wherever they reside. Evaluator behind that CLI tool is [Musoq](https://github.com/Puchaczov/Musoq). 

This is a single program that acts as a server and cli tool.

- `Musoq server`: Server part that allows to run Musoq runtime and query your data
- `Musoq cli`: Thin client that allows to run the queries on server and print them on console

## How to try it out - with observation how server works

1. Download zipped program for your target architecture (look at release assets)
2. Unpack to some directory
3. Open first console in the directory
4. For Windows run `Musoq.exe serve --wait-until-exit`, for Linux, run `Musoq serve --wait-until-exit` (you will need `chmod +x ./Musoq`)
5. Open second console in the directory
6. For windows run `Musoq.exe run query "select 1 from #system.dual()"`, For linux run `Musoq run query "select 1 from #system.dual()"`
7. After finished working with the server, just run `Musoq quit` to gracefully quit the server

## Does it need any additional dependencies?

No. It is self contained and should be ready to go immediatelly.

## Explore

You can explore CLI options with `--help` helper command



## Details about the server

The default port that http server is run at is `5137`



## Future

In the future, it's expected that the installation will be fully automated so you will be able to install the software through `snap` or `chocolatey`
