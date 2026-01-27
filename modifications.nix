{ config, pkgs, lib, ... }: {

  imports = [
    ./system/default.nix
    ./storage/databases.nix
    ./desktop-environment/default.nix
    ./virtualisation/default.nix
  ];

  # ──────────────────────────────────────────────────────────────
  # Dynamic Library Linking
  # ──────────────────────────────────────────────────────────────
  programs.nix-ld.enable = true;
  

  # ──────────────────────────────────────────────────────────────
  # Steam
  # ──────────────────────────────────────────────────────────────
  programs.steam.enable = true;
  programs.steam.gamescopeSession.enable = true;
  programs.gamemode.enable = true;


  # ──────────────────────────────────────────────────────────────
  # Network Packet Filtering
  # ──────────────────────────────────────────────────────────────

  networking.nftables.enable = lib.mkDefault true;
  networking.firewall.trustedInterfaces = [ "incusbr0" "virbr0" ];

 
  # ─────────────────────────────────────────────────────────────
  # Niri Window Manager
  # ─────────────────────────────────────────────────────────────


  # ─────────────────────────────────────────────────────────────
  # Swapfile 
  # ─────────────────────────────────────────────────────────────

  # swapDevices = [{ 
  #   device = "/swap/swapfile"; 
  #   size = 32*1024; # Creates an 32GB swap file 
  # }];

  # boot.kernel.sysctl = {
    # This is between 0 (no swap until absolutely necessay) to 100 (swap as much as you can), usually the default is 60.
  #   "vm.swappiness" = 15;  
  # };

  # zramSwap = {
  #   enable = true;
  #   memoryPercent = 50;  # Use half your RAM for compressed swap
  #   priority = 100;
  # };
  #
  # # Step 3: Enable zswap
  # boot.kernelParams = [
  #   "zswap.enabled=1"
  #   "zswap.compressor=zstd"
  #   "zswap.max_pool_percent=25"
  # ];
  #
  # # Step 4: Enable dynamic swapspace (disk-based fallback)
  # services.swapspace.enable = true;

  # ──────────────────────────────────────────────────────────────
  #  Base System Packages
  # ──────────────────────────────────────────────────────────────
  environment.systemPackages = with pkgs; [
    # CLI essentials
    neovim 
    git
    ripgrep
    zoxide
    fd
    fzf
    bat
    wget
    curl
    btop
    nvtopPackages.v3d
    file
    which
    tree 
    kitty
    btrbk
    remmina
    appimage-run
    ptyxis


    # Container stack
    podman 
    docker 
    incus
    distrobox
    devbox
    nvidia-container-toolkit
    dnsmasq
    home-manager

    # App distribution
    flatpak
  ];

  # ──────────────────────────────────────────────────────────────
  #  Enable Modern Nix CLI + Flake Support
  # ──────────────────────────────────────────────────────────────

  nix = {
    settings = {
      experimental-features = [ "nix-command" "flakes" ];

      # Safety and reproducibility settings
      warn-dirty = false;              # don’t nag on uncommitted files
      auto-optimise-store = true;      # deduplicate identical files in /nix/store
      sandbox = true;                  # ensure pure builds
      trusted-users = [ "root" "addy" ];  # allow you to use nix without sudo
    };
    gc = {
      automatic = true;
      dates = "weekly";
      options = "--delete-older-than 14d";
    };
  };

  # ──────────────────────────────────────────────────────────────
  #  Containerization Setup (Podman, Docker, LXD)
  # ──────────────────────────────────────────────────────────────


  # ──────────────────────────────────────────────────────────────
  #  User Access and Permissions
  # ──────────────────────────────────────────────────────────────
  users.users.addy = {
    isNormalUser = true;
    description = "Addy";
    extraGroups = [
      "wheel"   # sudo access
      "networkmanager"
      "podman"
      "docker"
      "incus-admin"
      "libvirtd"
    ];
    shell = pkgs.fish;  # explicitly set your shell here
  };

  programs.zsh.enable = true;  # ensure zsh is available system-wide
  programs.fish.enable = true;  # ensure zsh is available system-wide

  # ──────────────────────────────────────────────────────────────
  #  Flatpak (App Distribution)
  # ──────────────────────────────────────────────────────────────
  services.flatpak.enable = true;

  # ──────────────────────────────────────────────────────────────
  #  Optional Cleanup and Quality-of-Life
  # ──────────────────────────────────────────────────────────────
  # Remove unwanted GNOME apps (if using GNOME)

  # Explicitly enable graphical session management if needed
  services.xserver.enable = lib.mkDefault true;
  services.xserver.excludePackages = with pkgs; [
    xterm
  ];

  xdg.portal.extraPortals = [ pkgs.xdg-desktop-portal-gtk ];

  # NixOS by default adds coreutils, bash, systemd, etc., so no need to repeat.
}
