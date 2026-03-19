{ config, pkgs, inputs, ... }:

{
  imports = [
    ./config/zsh_shell.nix
    ./config/distrobox.nix
    ./config/fish_shell.nix
    inputs.nix4nvchad.homeManagerModule
    # ./programs/flatpaks.nix
    # inputs.nix-flatpak.homeManagerModules.nix-flatpak
  ];
  # Home Manager needs a bit of information about you and the paths it should
  # manage.
  home.username = "addy";
  home.homeDirectory = "/home/addy";


  nixpkgs.config.allowUnfree = true;
  # programs.zsh.dotDir = "${config.xdg.configHome}/zsh";

  # This value determines the Home Manager release that your configuration is
  # compatible with. This helps avoid breakage when a new Home Manager release
  # introduces backwards incompatible changes.
  #
  # You should not change this value, even if you update Home Manager. If you do
  # want to update the value, then make sure to first check the Home Manager
  # release notes.
  home.stateVersion = "26.05"; # Please read the comment before changing.

  # The home.packages option allows you to install Nix packages into your
  # environment.
  home.packages = [
    pkgs.chromium
    pkgs.jujutsu
    pkgs.trash-cli
    pkgs.tldr
    pkgs.atuin
    pkgs.eza
    pkgs.vscodium
    pkgs.protonup-ng
    pkgs.x11docker
    pkgs.ghostty
    pkgs.nerd-fonts.fira-code
    pkgs.nerd-fonts.zed-mono
    pkgs.nerd-fonts.hasklug
    pkgs.nerd-fonts.jetbrains-mono
    pkgs.direnv
    pkgs.n8n # unfree license
    pkgs.ansible
    pkgs.gh
    pkgs.waypipe
    pkgs.duplicati
    pkgs.opencode
    pkgs.zotero
    pkgs.jabref
    pkgs.steam-run
    pkgs.megasync
    pkgs.zed-editor
    pkgs.mise
    pkgs.devenv
    pkgs.arion
    pkgs.niv
    pkgs.kata-runtime
    pkgs.nixd
    pkgs.nil
    pkgs.anytype
    pkgs.glab
    pkgs.stow
    pkgs.obsidian
    pkgs.logseq
    pkgs.super-productivity
    pkgs.nushell
    pkgs.tmux
    pkgs.ollama
    pkgs.planify
    pkgs.protonvpn-gui
    pkgs.qbittorrent
    pkgs.telegram-desktop
    pkgs.vesktop
    pkgs.vlc
    pkgs.bazaar
    pkgs.gearlever
    pkgs.warehouse
    # pkgs.heroic
    (pkgs.heroic.override {
      extraPkgs = pkgs: with pkgs; [
       gamescope
       gamemode
      ];
     })
    pkgs.bitwarden-desktop
    pkgs.bitwarden-cli
    # pkgs.wireshark pkgs.nmap
    inputs.antigravity-nix.packages.x86_64-linux.default
  ];

  programs.nvchad = {
    enable = true;
    backup = false;
    extraPackages = with pkgs; [ ];
    hm-activation = true;
  };

  # Home Manager is pretty good at managing dotfiles. The primary way to manage
  # plain files is through 'home.file'.
  home.file = {

  };

  # Home Manager can also manage your environment variables through
  # 'home.sessionVariables'. These will be explicitly sourced when using a
  # shell provided by Home Manager. If you don't want to manage your shell
  # through Home Manager then you have to manually source 'hm-session-vars.sh'
  # located at either
  #
  #  ~/.nix-profile/etc/profile.d/hm-session-vars.sh
  #
  # or
  #
  #  ~/.local/state/nix/profiles/profile/etc/profile.d/hm-session-vars.sh
  #
  # or
  #
  #  /etc/profiles/per-user/addy/etc/profile.d/hm-session-vars.sh
  #
  home.sessionVariables = {
    EDITOR = "nvim";
    STEAM_EXTRA_COMPAT_TOOLS_PATHS = "\${HOME}/.steam/root/compatibilitytools.d";
  };

  # Let Home Manager install and manage itself.
  programs.home-manager.enable = true;
}
