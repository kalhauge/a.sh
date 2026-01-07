# Ash - One developer tool to rule them all.

It makes no sense that every editor needs to be configured with every language
out there. Instead we should just have one developer tool, which directs the
correct queries to the right apps.

Ash is a single bash script, which does this.

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

## Overrides

See https://github.com/github-linguist/linguist/blob/main/docs/overrides.md#using-gitattributes

## Requirements

- As a user I would like to specify which tools should handle my code, and have those easily interact with my editor and shell environments.

- The configuration of the repository should take precedence
