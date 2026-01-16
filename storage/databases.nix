
{pkgs, ... }: {
  services = {
    # mongodb = {
    #   enable = true;
    #   package = pkgs.mongodb;
    # };
    redis.servers.default.enable = true;
    postgresql = {
      enable = true;
      package = pkgs.postgresql_18;
    };
  };
  environment.systemPackages = with pkgs; [ redis postgresql_18 sqlite ];
}
