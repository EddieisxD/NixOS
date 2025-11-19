{ config, pkgs, lib, ... }: {

  imports = [
    ./gpu-nvidia.nix
  ];

  # ──────────────────────────────────────────────────────────────
  # Dynamic Library Linking
  # ──────────────────────────────────────────────────────────────
  programs.nix-ld.enable = false;


  # ──────────────────────────────────────────────────────────────
  # Network Packet Filtering
  # ──────────────────────────────────────────────────────────────

  networking.nftables.enable = lib.mkDefault true;
  networking.firewall.trustedInterfaces = [ "incusbr0" ];

  # ─────────────────────────────────────────────────────────────
  # Niri Window Manager
  # ─────────────────────────────────────────────────────────────
  services.displayManager.autoLogin.enable = false;
  programs.niri = {
    enable = true;
  };

  # ─────────────────────────────────────────────────────────────
  # Hyprland Window Manager
  # ─────────────────────────────────────────────────────────────
  
  programs.hyprland = {
    enable = true;
    withUWSM = true; # recommended for most users
    xwayland.enable = true; # Xwayland can be disabled.
  };

  # # ─────────────────────────────────────────────────────────────
  # # Nvidia Drivers
  # # ─────────────────────────────────────────────────────────────
  #
  # hardware.graphics.enable = true;
  # services.xserver.videoDrivers = [ "nvidia" ];
  # hardware.nvidia.open = true;  # open source drives form Nvidia
  # hardware.nvidia-container-toolkit.enable = true;


  # ─────────────────────────────────────────────────────────────
  # Swapfile 
  # ─────────────────────────────────────────────────────────────

  swapDevices = [{ 
    device = "/swap/swapfile"; 
    size = 32*1024; # Creates an 32GB swap file 
  }];

  boot.kernel.sysctl = {
    # This is between 0 (no swap until absolutely necessay) to 100 (swap as much as you can), usually the default is 60.
    "vm.swappiness" = 15;  
  };

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
    wget
    curl
    btop
    nvtopPackages.v3d
    file
    which
    tree 
    kitty
    btrbk

    # Niri
    mako # Wayland notification daemon
    gnome-keyring # Component in Gnome that stores secreats, passwords, etc
    xdg-desktop-portal-gtk # Desktop integration portal for sandboxed apps
    xdg-desktop-portal-gnome # backend implementation of xdg-desktop-portal for Gnome
    fuzzel # Wayland native application launcher similar to rofi's drun mode
    kdePackages.polkit-kde-agent-1 # Daemon providing a Polkit authentication UI for Plasma
    xwayland-satellite # Xwayland outside your Wayland compositor
    waybar # Highly customizable Wayland bar for Sway and Wlroots based compositors


    # Container stack
    podman docker 
    incus
    distrobox

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

  virtualisation = {
    containers.enable = true;  # systemd-nspawn support, needed by distrobox

    podman = {
      enable = true;
      dockerCompat = false;                 # provides /run/current-system/sw/bin/docker
      defaultNetwork.settings.dns_enabled = true;  # fix DNS in containers
      autoPrune.enable = true;             # automatically remove stopped containers/images
      extraPackages = with pkgs; [ slirp4netns fuse-overlayfs ];  # explicit rootless networking helpers
    };

    docker = {
      enable = true;                       # optional, for docker-daemon-based workflows
      daemon.settings = {
        dns = [ "1.1.1.1" "8.8.8.8" ];     # explicit DNS for docker containers
        log-driver = "journald";           # use journald for logs
      };
    };

    incus = {
      enable = true;
      ui.enable = true; # optional web ui
    };

  };

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
    ];
    shell = pkgs.zsh;  # explicitly set your shell here
  };

  programs.zsh.enable = true;  # ensure zsh is available system-wide

  # ──────────────────────────────────────────────────────────────
  #  Flatpak (App Distribution)
  # ──────────────────────────────────────────────────────────────
  services.flatpak.enable = true;

  # ──────────────────────────────────────────────────────────────
  #  Optional Cleanup and Quality-of-Life
  # ──────────────────────────────────────────────────────────────
  # Remove unwanted GNOME apps (if using GNOME)
  environment.gnome.excludePackages = with pkgs; [
    xterm
    geary
    gnome-tour
    yelp
    gnome-contacts
    epiphany
    gnome-maps
    gnome-calendar
    gnome-weather
    gnome-clocks
    gnome-music
    gnome-photos
    gnome-text-editor
    gnome-logs
    gnome-disk-utility
  ];

  # Explicitly enable graphical session management if needed
  services.xserver.enable = lib.mkDefault true;

  # NixOS by default adds coreutils, bash, systemd, etc., so no need to repeat.
}
