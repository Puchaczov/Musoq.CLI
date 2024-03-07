# Musoq.CLI

This repository contains Musoq command line interface. The program consists of two main parts:

- `Musoq agent`: Server part that allows to load the Musoq runtime and run your queries
- `Musoq cli`: Thin client that allows to run the queries on server

## How to try it out

1. Download zipped program for your target architecture (look at release assets)
2. Unpack to some directory
3. Open first console in the directory
4. For Windows run `./Musoq.exe serve`, for Linux, run `./Musoq serve`
5. Open second console in the directory
6. For windows run `./Musoq.exe run query "select 1 from #system.dual()"`, For linux run `./Musoq run query "select 1 from #system.dual()"`

## Does it need any additional dependencies?

No. It is self contained and should be ready to go immediatelly.

## Explore

You can explore CLI options with `--help` helper command

## Future

In the future, it's expected that the installation will be fully automated so you will be able to install the software through `snap` or `chocolatey`
