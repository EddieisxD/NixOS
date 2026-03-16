{ disks ? [ "/dev/nvme0n1" ], ... }:
  let b = builtins; in {
  disko.devices.disk = {
    base = {
      type   = "disk";
      device = b.elemAt disks 0;
      content = {
        type = "gpt";
        partitions = {
          boot = import ./base/boot_partition.nix;
          root = import ./base/root_partition.nix;
        };
      };
    };
  };
}
