{
  pkgs,
  lib,
  config,
  ...
}:
{

  options = {
    languages.git.enable = lib.mkEnableOption "Git";
  };

  config = {
    formatters = lib.mkIf config.languages.git.enable {
      "Git Attributes".skip = true;
      "Ignore List".skip = true;
    };
  };
}
