{pkgs, ... }: {
  programs.hyprland = {
    enable = true;
    withUWSM = false; # Disabled to fix GDM "Session never registered" issues
    xwayland.enable = true; # Xwayland can be disabled.
  };
}
