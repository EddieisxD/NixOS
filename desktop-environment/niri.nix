{pkgs, ... }: {

  services.displayManager.autoLogin.enable = false;
  programs.niri = {
    enable = false;
  };

  environment.systemPackages = with pkgs; [
    # Niri
    # mako # Wayland notification daemon
    # gnome-keyring # Component in Gnome that stores secreats, passwords, etc
    # xdg-desktop-portal-gtk # Desktop integration portal for sandboxed apps
    # xdg-desktop-portal-gnome # backend implementation of xdg-desktop-portal for Gnome
    # fuzzel # Wayland native application launcher similar to rofi's drun mode
    # kdePackages.polkit-kde-agent-1 # Daemon providing a Polkit authentication UI for Plasma
    # xwayland-satellite # Xwayland outside your Wayland compositor
    # waybar # Highly customizable Wayland bar for Sway and Wlroots based compositors
  ];
}
