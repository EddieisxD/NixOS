
{config, pkgs, ... }: {

  programs.dconf.profiles.user = {
    databases = [{
      settings = {
        "org/gnome/mutter" = {
          experimental-features = ["scale-monitor-framebuffer" "xwayland-native-scaling"];
        };
        # add more schemas/keys as needed
      };
    }];
  };

  environment.systemPackages = with pkgs; [
    gnomeExtensions.user-themes
    gnomeExtensions.appindicator
    gnomeExtensions.blur-my-shell
    gnomeExtensions.caffeine
    gnomeExtensions.dash-to-dock
    gnomeExtensions.gsconnect
    gnomeExtensions.places-status-indicator
  ]; 
  
  environment.gnome.excludePackages = with pkgs; [
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
}
