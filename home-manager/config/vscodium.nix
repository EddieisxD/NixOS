
{ pkgs, config, inputs, ... }:
  let
    vscode-extensions = inputs.vscode-extensions;
    marketplace = vscode-extensions.extensions.x86_64-linux.vscode-marketplace;
    open-vsx = vscode-extensions.extensions.x86_64-linux.open-vsx;
  in {
    programs.vscodium = {
      enable = true;
      package = pkgs.vscodium;
      mutableExtensionsDir = true;

      profiles.default = {
        extensions = [

          pkgs.vscode-extensions.teros-technology.teroshdl
          pkgs.vscode-extensions.asvetliakov.vscode-neovim
          pkgs.vscode-extensions.mkhl.direnv
          pkgs.vscode-extensions.continue.continue
          pkgs.vscode-extensions.llvm-vs-code-extensions.vscode-clangd
          pkgs.vscode-extensions.jnoortheen.nix-ide
          pkgs.vscode-extensions.foam.foam-vscode

          open-vsx.jeanp413.open-remote-ssh

          # language support
          marketplace.tamasfe.even-better-toml
          # themes
          marketplace.catppuccin.catppuccin-vsc
          marketplace.catppuccin.catppuccin-vsc-icons
          marketplace.xscriptor.xscriptor-themes
          marketplace.meronz.hybrid-dim
          marketplace.pkief.material-product-icons
        ];
      };
    };
    xdg.configFile."VSCodium/User/settings.json".source = config.lib.file.mkOutOfStoreSymlink "/home/addy/System/v1/home-manager/dotfiles/vscodium/settings.json";
    xdg.configFile."VSCodium/User/settings.json".force = true;
}
