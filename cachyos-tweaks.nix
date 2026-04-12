{ pkgs, ... }: {

  # boot.kernelPackages = pkgs.linuxPackages_cachyos;

  # Or "schedutil" for a balance of battery and speed
  powerManagement.cpuFreqGovernor = "performance"; 

  # zramSwap.enable = true;
  # zramSwap.memoryPercent = 25; # Or a fixed 'memoryMax'

  # changes the priority of apps dynamically
  services.ananicy = {
    enable = true;
    package = pkgs.ananicy-cpp;
    rulesProvider = pkgs.ananicy-rules-cachyos; # This contains the "CachyOS" logic
  };

  programs.gamemode.enable = true;
  programs.steam.gamescopeSession.enable = true;
}
