{ lib, config, pkgs, ... }:

let
  cfg = config.host-virtualisation.virtualisation.qemu;
in
{
  options.virtualisation.qemu = {
    enable = lib.mkEnableOption "QEMU/KVM";
  };

  config = lib.mkIf cfg.enable {
    virtualisation.qemu.package = pkgs.qemu_kvm;
    environment.etc."qemu/ovmf".source = lib.mkIf cfg.enable "${pkgs.OVMF.fd}/FV";
    environment.systemPackages = with pkgs; [
      #qemu-full # everything included every possible architecture
      qemu-utils # qemu management tools
      qemu-kvm # stripped down version on include x86-64 bit architecture
      virt-manager
    ];
  };
}

