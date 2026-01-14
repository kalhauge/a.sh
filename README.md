# A.sh - One developer tool to rule them all.

It makes no sense that every editor needs to be configured with every language
out there. Instead we should just have one developer tool, which directs the
correct queries to the right apps.

A.sh is a single bash script, which does this.

## Features

The goal of this project is to be a one-stop-shop for most language related
developer workflows.

### Language

Auto detect what langauage a file has.

### Format

Format the code so that complies with the rules.

### Check

Run linters and static analyses.

### Test and Debug

Run the test-suite, and attach to it if you need to debug it.

### Serve

Start a lsp server for any language you have configured.

*Strech goals* be a single lsp which can call others. Futhermore, make sure
that all the other capabilities are exposed through the code.

### Configure

## Install

Installation could not be simpler, but requires you to have git, jq, go-toml, and enry installed.

```shell
cp bin/a.sh /usr/local/bin
```

But you can also try it out using [nix](https://nixos.org/):

```shell
nix run github:kalhauge/a.sh -- ARGS
```

## Configuration

### TODO

Follow https://github.com/numtide/prj-spec/blob/main/PRJ_SPEC.md

## Overrides

See https://github.com/github-linguist/linguist/blob/main/docs/overrides.md#using-gitattributes

## Requirements

- As a user I would like to specify which tools should handle my code, and have those easily interact with my editor and shell environments.

- The configuration of the repository should take precedence

## Strech Goals

- Support multi-project repositories
