
{ pkgs, config, inputs, ... }:
  let
    mutable = false;
    vscode-extensions = inputs.vscode-extensions;
    marketplace = vscode-extensions.extensions.x86_64-linux.vscode-marketplace;
    baseSettings = {
      "editor.fontFamily"= pkgs.lib.mkForce "'Haskilg', 'Droid Sans Mono', monospace";
      "editor.fontLigatures"= true;
      "editor.lineNumbers"= "relative";
      "editor.minimap.enabled"= false;
      "explorer.confirmDelete"= false;
      "files.autoSave"= "afterDelay";
      "git.openRepositoryInParentFolders"= "always";
      "security.workspace.trust.untrustedFiles"= "open";
      "window.commandCenter"= false;
      "window.menuBarVisibility"= "compact";
      "workbench.activityBar.location"= "top";
      "breadcrumbs.enabled"= false;
      "workbench.editor.editorActionsLocation"= "hidden";
      "workbench.editor.showTabs"= "none";
      "workbench.iconTheme"= "catppuccin-mocha";
      "workbench.productIconTheme"= "material-product-icons";
      "workbench.layoutControl.enabled"= false;
      "workbench.sideBar.location"= "right";
      "workbench.startupEditor"= "none";
      "workbench.statusBar.visible"= false;
      "workbench.colorTheme"= pkgs.lib.mkForce "Hybrid dim";


      "chat.editor.fontSize" = pkgs.lib.mkForce 14;
      "debug.console.fontSize" = pkgs.lib.mkForce 14;
      "editor.fontSize" = pkgs.lib.mkForce 14;
      "markdown.preview.fontSize" = pkgs.lib.mkForce 14;
      "terminal.integrated.fontSize" = pkgs.lib.mkForce 14;

    };
  in {
    programs.vscode = {
      enable = true;
      package = pkgs.vscodium;
      mutableExtensionsDir = true;

      profiles.default = {
        extensions = [
          # AI chat
          marketplace.openai.chatgpt

          # environment support
          marketplace.mkhl.direnv
          marketplace.arrterian.nix-env-selector

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
        userSettings = if mutable then {} else baseSettings;
      };

  };
  
}
