{
  config.languages = {
    "Git Attributes" = {
      formatters = [ "skip" ];
    };
    "Ignore List" = {
      formatters = [ "skip" ];
    };
    "Public Key" = {
      formatters = [ "skip" ];
    };
    "Text" = {
      formatters = [ "skip" ];
    };
    "TSV" = {
      formatters = [ "skip" ];
    };
    "CSV" = {
      formatters = [ "skip" ];
    };
    "C" = {
      formatters = [ "clang-format" ];
    };
    "Markdown" = {
      formatters = [ "mdformat" ];
    };
    "Python" = {
      formatters = [ "ruff" ];
      servers = [ "ty" ];
    };
    "TOML" = {
      formatters = [ "tomll" ];
    };
    "JSON" = {
      formatters = [ "jq" ];
    };
    "Nix" = {
      formatters = [ "nixfmt" ];
      servers = [ "nixd" ];
    };
    "Shell" = {
      formatters = [ "shfmt" ];
    };
    "Lua" = {
      formatters = [ "stylua" ];
    };
  };
}
