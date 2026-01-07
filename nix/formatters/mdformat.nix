{ config, lib, ... }:
{
  options = {
    number = lib.mkOption {
      type = lib.types.bool;
      default = true;
      description = "make numbers increment in ordered lists";
    };
  };

  config = {
    command = "mdformat";
    args = (if config.number then [ "--number" ] else [ ]) ++ [ "-" ];
  };
}
