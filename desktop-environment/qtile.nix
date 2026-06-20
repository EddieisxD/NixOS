{
  config,
  pkgs,
  ...
}: {
  # ──────────────────────────────────────────────────────────────
  # Qtile Window Manager (X11)
  # ──────────────────────────────────────────────────────────────
  # This module is fully self-contained. Remove the import and
  # nothing qtile-related (packages, configs, services) remains.
  # Dotfiles are managed by home-manager (see home-manager/qtile/).

  services.xserver.windowManager.qtile = {
    enable = true;
    configFile = ../home-manager/qtile/config.py;
    extraPackages = python3Packages: with python3Packages; [
      qtile-extras
    ];
  };

  environment.systemPackages = with pkgs; [
    picom                # compositor (blur, shadows, rounded corners, animations)
    dunst                # notification daemon
    feh                  # wallpaper setter
    playerctl            # media player controls
    xclip                # X11 clipboard
    flameshot            # screenshots
    pamixer              # volume for qtile widget
    networkmanagerapplet # nm-applet in systray
    vicinae              # app launcher
    swaybg               # wallpaper for Wayland session
  ];
}
