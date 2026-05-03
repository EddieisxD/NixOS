{ ... } : {
  xdg.configFile."distrobox/distrobox.conf".text = ''
      # # --- Wayland + runtime ---
      #  XDG_RUNTIME_DIR=/run/user/1000
      #
      # # --- XDG base directories ---
      #  XDG_CONFIG_HOME=\$HOME/.config
      #  XDG_CACHE_HOME=\$HOME/.cache
      #  XDG_DATA_HOME=\$HOME/.local/share
      #  XDG_STATE_HOME=\$HOME/.local/state
  '';
  home.file.".distroboxrc".text = ''
    export XCURSOR_THEME=Adwaita
    export XCURSOR_SIZE=24
    # export QT_SCALE_FACTOR=1.25
    # export GDK_SCALE=1
    # export GDK_DPI_SCALE=1
    # export XWAYLAND_FORCE_SCALE=1.25

    export XFT_DPI=144
    export QT_FONT_DPI=144

    # Inject DPI into X resources
    if command -v xrdb >/dev/null 2>&1; then
      xrdb -merge <<< "Xft.dpi: 144"
    fi
  '';

}
