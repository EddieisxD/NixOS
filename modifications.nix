{
  pkgs,
  nixpkgs,
  lib,
  ...
}:
{

  imports = [
    ./system/default.nix
    # ./storage/databases.nix
    ./desktop-environment/default.nix
    ./virtualisation/default.nix
    ./distroagnostic_package_management.nix
    # ./multiple_monitors.nix
    ./nixos-container.nix
  ];

  
  # Verifies authenticity of the programs being downloaded
  programs.gnupg.agent = {
    enable = true;
  };

  # ──────────────────────────────────────────────────────────────
  # Gaming
  # ──────────────────────────────────────────────────────────────
  programs.steam.enable = true;
  programs.steam.gamescopeSession.enable = true;
  # programs.gamemode.enable = true;
  programs.gamescope.enable = true;
  # powerManagement.cpuFreqGovernor = "performance";
  services.power-profiles-daemon.enable = false;

  services.tailscale.enable = false;

  # Cosmic Desktop

  # Razer
  hardware.openrazer = {
    enable = true;
    users = [ "addy" ];
  };

  # ──────────────────────────────────────────────────────────────
  # Network Packet Filtering
  # ──────────────────────────────────────────────────────────────

  networking.nftables.enable = lib.mkDefault true;
  networking.firewall = {
    enable = true;
    allowedTCPPorts = [ 55000 ];
    allowedUDPPorts = [ 55000 ];
    trustedInterfaces = [
      "incusbr0"
        "virbr0"
    ];
  };

  zramSwap = {
    enable = true;
    memoryPercent = 60;  # Use half your RAM for compressed swap
    priority = 100;
    algorithm = "zstd";
  };
  # # Step 4: Enable dynamic swapspace (disk-based fallback)
  services.swapspace.enable = true;
  services.earlyoom.enable = true;

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
    eza
    tldr
    file
    which
    tree
    otree
    yq
    kitty
    btrbk
    appimage-run
    ptyxis
    direnv
    cachix
    home-manager
    devenv
    stow
    arion
    comma
    niv

    # Hardware utils
    pciutils
    hwloc
    libva-utils

    # Container stack
    podman
    docker
    incus
    waydroid
    distrobox
    nixos-container
    devbox
    nvidia-container-toolkit

    # more packages
    dnsmasq
    wireshark nmap
    remmina
    waypipe
    steam-run
    bazaar
  ];

  # ──────────────────────────────────────────────────────────────
  #  Enable Modern Nix CLI + Flake Support
  # ──────────────────────────────────────────────────────────────

  nix = {

    registry.nixpkgs.flake = nixpkgs;
    settings = {

      experimental-features = [
        "nix-command"
        "flakes"
      ];

      substituters = [
	      "https://cache.nixos.org"
	      "https://nix-community.cachix.org"
	      "https://devenv.cachix.org"
      ];

      trusted-public-keys = [
        "cache.nixos.org-1:6NCHdD59X431o0gWypbMrAURkbJ16ZPMQFGspcDShjY="
	      "nix-community.cachix.org-1:mB9FSh9qf2dCimDSUo8Zy7bkq5CX+/rkCWyvRCYg3Fs="
	      "devenv.cachix.org-1:w1cLUi8dv3hnoSPGAuibQv+f9TZLr6cv/Hm9XgU50cw="
      ];

      # 2. This tells Nix: "If it's not in the cache, DON'T build it."
      # Note: This can be annoying if a tiny wrapper needs to be built.
      # Most users prefer passing '--no-build' on the command line instead.
      # allow-import-from-derivation = false; 

      # 3. Ensure Nix always tries the cache first
      builders-use-substitutes = true;
      keep-outputs = true;
      keep-derivations = true;

      cores = 0;
      # Safety and reproducibility settings
      warn-dirty = false; # don’t nag on uncommitted files
      auto-optimise-store = false; # deduplicate identical files in /nix/store
      sandbox = true; # ensure pure builds
      trusted-users = [
        "root"
        "addy"
      ]; # allow you to use nix without sudo
    };
    gc = {
      automatic = true;
      dates = "weekly";
      options = "--delete-older-than 10d";
    };
  };
  

  # ──────────────────────────────────────────────────────────────
  #  Containerization Setup (Podman, Docker, LXD)
  # ──────────────────────────────────────────────────────────────

  # ──────────────────────────────────────────────────────────────
  #  User Access and Permissions
  # ──────────────────────────────────────────────────────────────
  users.users.root = { 
    subUidRanges = [
      { startUid = 1000; count = 1; }
    ];
    subGidRanges = [
      { startGid = 1000; count = 1; }
    ];
  };
  users.users.addy = {
    isNormalUser = true;
    description = "Addy";
    extraGroups = [
      "wheel" # sudo access
      "networkmanager"
      "podman"
      "docker"
      "incus-admin"
      "libvirtd"
      "render" "video"
      "gamemode"
      "guixbuild"
    ];
    shell = pkgs.fish; # explicitly set your shell here
  };

  programs.zsh.enable = true; # ensure zsh is available system-wide
  programs.fish.enable = true; # ensure zsh is available system-wide

  fonts = {
    enableDefaultPackages = true;
    packages = with pkgs; [
      noto-fonts
      noto-fonts-cjk-sans
      noto-fonts-color-emoji

      # Core coding fonts
      jetbrains-mono
      fira-code
      fira-code-symbols
      iosevka
      hasklig

      cascadia-code
      maple-mono.NF

      # Nerd patched versions (icons + powerline symbols)
      nerd-fonts.jetbrains-mono
      nerd-fonts.fira-code
      nerd-fonts.iosevka
      nerd-fonts.hasklug

      # Optional UI fallback
      liberation_ttf
    ];
  };

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
