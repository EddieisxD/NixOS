{
  lib,
  ... 
}: {

  programs.starship = {
    enable = true;
    settings = {
      add_newline = false;

      format = lib.concatStrings [
        "$os" "$container"
        "$directory"
        "$git_branch"
        "$git_status"
        "$character"
      ];

      character = {
        success_symbol = "[λ](bold green)";
        error_symbol = "[λ](bold red)";
        vimcmd_symbol = "[𝜔](bold white)";
        vimcmd_visual_symbol = "[𝜔](bold white)";
      };

      os = {
        disabled = false;
      };

      os.symbols = {
        Windows = "󰍲";
        Ubuntu = "󰕈";
        SUSE = "";
        Raspbian = "󰐿";
        Mint = "󰣭";
        Macos = " ";
        Manjaro = "";
        Linux = "󰌽";
        Gentoo = "󰣨";
        Fedora = "󰣛";
        Alpine = "";
        Amazon = "";
        Android = "";
        Arch = "󰣇";
        Artix = "󰣇";
        CentOS = "";
        Debian = "󰣚";
        Redhat = "󱄛";
        NixOS = "";
        RedHatEnterprise = "󱄛";
      };

      directory = {
        style = "sapphire";
        format = "[ $path ]($style)";
        truncation_length = 4;
      };

      # Git branch status
      git_branch = {
        style = "bold purple";
        symbol = " ";
      };

      # Nix Shell detection
      nix_shell = {
        symbol = "⏒";
        format = "via [$symbol$state]($style) ";
      };

      # Container detection (Incus, Distrobox, Docker)
      container = {
        disabled = false;
        format = "[$symbol $name]($style) ";
        symbol = " 󰡨";
      };
    };
  };
}
