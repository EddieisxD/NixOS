{
  pkgs,
  ...
}: {
  programs.ghostty = {
    enable = true;
    package = pkgs.ghostty;
    settings = {
      font-size = 16;
      background-opacity = 0.7;
      background = "#000000";
      window-padding-balance = true;
      font-family = "JetBrainsMono Nerd Font Mono";
      window-padding-y = 1;
      window-padding-x = 1;
      window-decoration = false;
      gtk-tabs-location = "hidden";
      confirm-close-surface = false;
    };
  };
}
