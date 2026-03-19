
{ ... }: {

  programs.starship = {
    enable = true;
    settings = {
      # Custom prompt character
      character = {
        success_symbol = "[➜ :](bold green)";
        error_symbol = "[➜ :](bold red)";
      };

      # Truncated working directory (shows last 3)
      directory = {
        truncation_length = 3;
        truncation_symbol = "…/";
        style = "bold cyan";
      };

      # Git branch status
      git_branch = {
        symbol = " ";
        style = "bold purple";
      };

      # Nix Shell detection
      nix_shell = {
        symbol = "❄️ ";
        format = "via [$symbol$state]($style) ";
      };

      # Container detection (Incus, Distrobox, Docker)
      container = {
        disabled = false;
        format = "[$symbol $name]($style) ";
        symbol = "📦";
      };
    };
  };
}
