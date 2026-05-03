{ lib, config, pkgs, ... }:

let
  cfg = config.my.virtualisation.lxc;
in
{
  options.my.virtualisation.lxc = {
    enable = lib.mkEnableOption "LXC";
  };

  config = lib.mkIf cfg.enable {
    virtualisation.lxc.enable = true;

    environment.systemPackages = with pkgs; [
      lxc
      lxcfs
    ];
  };
}

