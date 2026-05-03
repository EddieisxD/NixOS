{
  size = "100%";
  content = {
    type = "btrfs";
    extraArgs = [ "-f" ]; # Force overwrite if an existing filesystem is found

    # Subvolumes must set a mountpoint to be mounted, unless their parent is mounted
    subvolumes = {
      "/nixos" = { };
      # Root subvolume, mounted at /
      "/nixos/root" = {
        mountpoint = "/";
        mountOptions = [ "compress=zstd" "noatime" ];
      };
      # Home subvolume, mounted at /home
      "/nixos/home" = {
        mountpoint = "/home";
        mountOptions = [ "compress=zstd" "noatime" ];
      };
      # Nix subvolume, mounted at /nix
      "/nixos/nix" = {
        mountpoint = "/nix";
        mountOptions = [ "compress=zstd" "noatime" ];
      };
      # A separate subvolume to contain the swap file.
      # We mount it at a hidden path, like /.swapvol, so the swap file
      # can be placed inside it. This allows for snapshotting the root
      # subvolume without including the swap file.
      "/nixos/swap" = {
        mountpoint = "/.swap-file";
        # Leave compression off on this subvolume because it will hold the swapfile.
        swap.swapfile.size = "16G"; # Create a 16G swapfile inside this subvolume
      };
    };
  };
}
