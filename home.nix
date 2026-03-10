{ osConfig, pkgs, ... }:

{
  home.stateVersion = "25.11";

  programs.bash.enable = true;

  home.file.".npmrc".text = ''
    prefix=/home/${osConfig.myProfile.username}/.npm-global
  '';

  home.sessionPath = [
    "/home/${osConfig.myProfile.username}/.npm-global/bin"
  ];

  programs.bash.initExtra = ''
    if [ -f "$HOME/.secrets/github-token.sh" ]; then
      source "$HOME/.secrets/github-token.sh"
    fi
  '';

  programs.git = {
    enable = true;

    settings = {
      user = {
        name  = osConfig.myProfile.fullName;
        email = osConfig.myProfile.email;
      };

      init.defaultBranch = "main";
    };

    includes = [
      {
        condition = "gitdir:/home/${osConfig.myProfile.username}/code/work/**";
        contents = {
          user.email = osConfig.myProfile.email;
        };
      }
    ];
  };

  home.shellAliases = {
    claude = "echo 'Use claude-work or claude-personal'";
  };

  home.packages = [
    (pkgs.writeShellScriptBin "claude-work" ''
      export CLAUDE_HOME="$HOME/claude-work-home"
      export CLAUDE_CONFIG_DIR="$CLAUDE_HOME/.claude"
      export CLAUDE_CODE_TMPDIR="/tmp/claude-work"

      mkdir -p "$CLAUDE_CONFIG_DIR" "$CLAUDE_CODE_TMPDIR"

      exec claude code
    '')

    (pkgs.writeShellScriptBin "claude-personal" ''
      export CLAUDE_HOME="$HOME/claude-personal-home"
      export CLAUDE_CONFIG_DIR="$CLAUDE_HOME/.claude"
      export CLAUDE_CODE_TMPDIR="/tmp/claude-personal"

      mkdir -p "$CLAUDE_CONFIG_DIR" "$CLAUDE_CODE_TMPDIR"

      exec claude code
    '')
  ];
}
