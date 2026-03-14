{ config, pkgs,... }:

{
  # Host Configuration
  boot.enableContainers = true;
  virtualisation.containers.enable = true;

  containers.dev-env = {
    autoStart = false;
    ephemeral = false;
    privateNetwork = false; # Share host network stack

    bindMounts = {
      # Share the Nix store to avoid duplication
      "/nix/store" = { hostPath = "/nix/store"; isReadOnly = true; };
      # Mount Wayland and Audio sockets
      "/run/user/1000/wayland-0" = { hostPath = "/run/user/1000/wayland-0"; isReadOnly = false; };
      "/run/user/1000/pulse/native" = { hostPath = "/run/user/1000/pulse/native"; isReadOnly = false; };
      # Mount GPU nodes
      "/dev/dri" = { hostPath = "/dev/dri"; isReadOnly = false; };
    };

    config = { config, pkgs,... }: {
      # Guest Configuration
      services.xserver.videoDrivers = [ "modesetting" ];
      hardware.graphics.enable = true;
      
      environment.variables = {
        WAYLAND_DISPLAY = "wayland-0";
        XDG_RUNTIME_DIR = "/run/user/1000";
        PULSE_SERVER = "unix:/run/user/1000/pulse/native";
      };

      # Binary compatibility for external tools
      programs.nix-ld.enable = true;
      services.envfs.enable = true;

      # Allow the user to act as root in the container safely
      users.users.root.password = ""; 

    };
  };
}

