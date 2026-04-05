{ config, lib, pkgs, modulesPath, ... }:

{
  imports = [
      (modulesPath + "/installer/scan/not-detected.nix")
  ];

  boot.loader.systemd-boot.extraEntries = {
    "arch.conf" = ''
      title Arch Linux
      linux /vmlinuz-linux
      initrd /initramfs-linux.img
      options root=UUID=DD14-E8F1 rootflags=subvol=@archlinux rw
      '';
  };

  boot.initrd.availableKernelModules = [ "xhci_pci" "ahci" "nvme" "vmd" "usbhid" "usb_storage" "sd_mod" ];
  boot.initrd.kernelModules = [ ];
  boot.kernelModules = [ "kvm-intel" ];
  boot.extraModulePackages = [ ];

  hardware.enableAllFirmware = true;
  nixpkgs.hostPlatform = lib.mkDefault "x86_64-linux";
  hardware.enableRedistributableFirmware = true;
  hardware.firmware = with pkgs; [ linux-firmware ];
  hardware.cpu.intel.updateMicrocode = lib.mkDefault config.hardware.enableRedistributableFirmware;
}
