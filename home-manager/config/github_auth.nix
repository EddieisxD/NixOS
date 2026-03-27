
{ pkgs, ... }: {
  programs.ssh = {
    enable = true;
    enableDefaultConfig = false; 
    matchBlocks = {
      "github_aditya22598" = {
        hostname = "github.com";
        user = "git";
        identityFile = "~/.ssh/id_github_aditya22598";
        identitiesOnly = true;
      };
      "github_eddieisxd12" = {
        hostname = "github.com";
        user = "git";
        identityFile = "~/.ssh/id_github_eddieisxd12";
        identitiesOnly = true;
      };
    };
  };
}
