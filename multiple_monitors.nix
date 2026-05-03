{pkgs, config, ... }: {
 environment.systemPackages = [ pkgs.displaylink ];
  
  # Load the EVDI kernel module
  boot.extraModulePackages = [ config.boot.kernelPackages.evdi ];
  boot.kernelModules = [ "evdi" ];

# Enable the DisplayLink service
  systemd.services.dlm = {
    description = "DisplayLink Manager Service";
    wantedBy = [ "multi-user.target" ];
    serviceConfig = {
      ExecStart = "${pkgs.displaylink}/bin/DisplayLinkManager";
      Restart = "always";
    };
  };
}
