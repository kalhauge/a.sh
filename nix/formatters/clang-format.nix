{ pkgs, ... }:
{
  package = pkgs.clang-tools;
  command = "clang-format";
  args = [ "-" ];
}
