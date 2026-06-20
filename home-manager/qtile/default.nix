{
  config,
  pkgs,
  ...
}: {
  home.sessionVariables = {
    XCURSOR_THEME = "Adwaita";
    XCURSOR_SIZE = "24";
  };

  gtk.cursorTheme = {
    name = "Adwaita";
    size = 24;
  };

  home.file = {
    ".config/qtile/config.py".source = ./config.py;
    ".config/qtile/autostart_once.sh" = {
      source = ./autostart_once.sh;
      executable = true;
    };
    ".config/qtile/picom.conf".source = ./picom.conf;
    ".config/qtile/dunstrc".source = ./dunstrc;
    ".config/qtile/Assets" = {
      source = ./Assets;
      recursive = true;
    };
  };
}
