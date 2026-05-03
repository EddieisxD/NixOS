
{ pkgs, ... }: {
  programs.nh = {
    enable = true;
    # 1. Point to your flake directory
    # Now you can run 'nh os switch' from ANYWHERE without --flake /path/to/flake
    flake = "/home/addy/Templates/NixOS/";

    # 2. Automate Garbage Collection
    clean = {
      enable = true;
      # Run weekly
      dates = "weekly";
      # "Keep the last 3 generations AND everything made in the last 3 days"
      extraArgs = "--keep-since 3d --keep 3";
    };
  };
  
  # Optional: If you want to use the diff feature, ensure nvd is available
  environment.systemPackages = [ pkgs.nvd ]; 
}
