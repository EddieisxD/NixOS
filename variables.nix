{
  config,
  lib,
  ...
}: {
  options = { var = lib.mkOption { type = lib.types.attrs; default = {}; }; };
  config.var.keyboard = "us";
}
