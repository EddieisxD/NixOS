{pkgs, ... }: {
  programs.virt-manager.enable = true;

  virtualisation = {
    containers.enable = true;  # systemd-nspawn support, needed by distrobox
    
    libvirtd = {
      enable = true;
      qemu.vhostUserPackages = with pkgs; [ virtiofsd ];
    };

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
            features = {
              cdi = true;
            };
        };
    };


    incus = {
      enable = true;
      ui.enable = true; # optional web ui
    };

  };
}
