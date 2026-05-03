
{ pkgs, config, inputs, ... }:
  let
    vscode-extensions = inputs.vscode-extensions;
    marketplace = vscode-extensions.extensions.x86_64-linux.vscode-marketplace;
    open-vsx = vscode-extensions.extensions.x86_64-linux.open-vsx;
  in {
    programs.vscode = {
      enable = true;
      package = pkgs.vscodium;
      mutableExtensionsDir = true;

      profiles.default = {
        extensions = [

          marketplace.mkhl.direnv
          marketplace.arrterian.nix-env-selector

          open-vsx.jeanp413.open-remote-ssh

          # language support
          marketplace.tamasfe.even-better-toml
          marketplace.jnoortheen.nix-ide
          marketplace.llvm-vs-code-extensions.vscode-clangd

          # themes
          marketplace.catppuccin.catppuccin-vsc
          marketplace.catppuccin.catppuccin-vsc-icons
          marketplace.xscriptor.xscriptor-themes
          marketplace.meronz.hybrid-dim
          marketplace.pkief.material-product-icons
        ];
      };
    };
    # xdg.configFile."VSCodium/User/settings.json".source = ../dotfiles/vscodium/settings.json;
}
