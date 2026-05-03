{ pkgs, ... }:

{
  
  imports = [
    ../programs/shell-integrations/atuin.nix
    ../programs/shell-integrations/starship_prompt.nix
    ../programs/shell-integrations/fzf.nix
    ../programs/shell-integrations/zoxide.nix
    ../programs/direnv.nix
  ];

  programs.fish = {
    enable = true;

    # Shell aliases (1:1 mapping)
    shellAliases = {
      ls = "eza";
      ll = "eza -l --git";
      la = "eza -la --git";
      tree = "eza --tree";
      v = "nvim";
      z = "zeditor";
    };

    # Interactive shell config
    interactiveShellInit = ''
      # Vi mode
      fish_vi_key_bindings

      # Cursor shape (makes mode obvious)
      set -g fish_cursor_default block
      set -g fish_cursor_insert line
      set -g fish_cursor_replace_one underscore
      set -g fish_cursor_visual block

      # Faster escape
      set -g fish_escape_delay_ms 10

      # History behavior (closest match to your zsh setup)
      set -g fish_history share

      # Disable fish greeting
      set -g fish_greeting

      # Better word motions
      set -g fish_vi_force_cursor 1

       # Valid commands → green
      set -g fish_color_command green

      # Arguments → normal
      set -g fish_color_param normal

      # Quoted strings → yellow
      set -g fish_color_quote yellow

      # Errors → red + bold
      set -g fish_color_error red --bold

      # Autosuggestions → faint
      set -g fish_color_autosuggestion brblack

      # Operators (|, >, <, etc)
      set -g fish_color_operator cyan

      # Escapes like \n \t
      set -g fish_color_escape magenta

    '';
  };

  programs.starship = {
    enableFishIntegration = true;
  };

  programs.fzf = {
    enableFishIntegration = true;
  };

  programs.zoxide = {
    enableFishIntegration = true;
  };
  
  programs.atuin = {
      enableFishIntegration = true;
  };

}
