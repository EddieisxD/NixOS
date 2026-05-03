{
  pkgs,
  ...
}: {
  programs.ghostty = {
    enable = true;
    package = pkgs.ghostty;
    settings = {
      font-size = 14;
      background-opacity = 0.7;
      background = "#000000";
      window-padding-balance = true;
      font-family = "JetBrainsMono Nerd Font Mono";
      window-padding-y = 12;
      window-padding-x = 12;
      window-decoration = false;
      window-padding-color = "extend";
      gtk-tabs-location = "hidden";
      confirm-close-surface = false;
    };
  };
}
