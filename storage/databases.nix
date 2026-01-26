
{pkgs, ... }: {
  services = {
    mongodb = {
      enable = false;
      package = pkgs.mongodb;
    };
    redis.servers.default.enable = true;
    postgresql = {
      enable = true;
      package = pkgs.postgresql_18;
    };
  };
}
