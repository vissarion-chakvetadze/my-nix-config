{ osConfig, pkgs, ... }:

let
  mkClaudeWrapper = name: pkgs.writeShellScriptBin "claude-${name}" ''
    export CLAUDE_HOME="$HOME/claude-${name}-home"
    export CLAUDE_CONFIG_DIR="$CLAUDE_HOME/.claude"
    export CLAUDE_CODE_TMPDIR="/tmp/claude-${name}"

    mkdir -p "$CLAUDE_CONFIG_DIR" "$CLAUDE_CODE_TMPDIR"

    exec claude code "$@"
  '';
in

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

  home.packages = map mkClaudeWrapper [ "work" "personal" ];
}
