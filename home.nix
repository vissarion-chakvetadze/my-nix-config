{ osConfig, pkgs, ... }:

let
  claudeBin = "/run/current-system/sw/bin/claude";

  mkClaudeWrapper = name: pkgs.writeShellScriptBin "claude-${name}" ''
    export CLAUDE_HOME="$HOME/claude-${name}-home"
    export CLAUDE_CONFIG_DIR="$CLAUDE_HOME/.claude"
    export CLAUDE_CODE_TMPDIR="/tmp/claude-${name}"

    mkdir -p "$CLAUDE_CONFIG_DIR" "$CLAUDE_CODE_TMPDIR"
    ln -sf "$HOME/.claude/ide" "$CLAUDE_CONFIG_DIR/ide"

    exec ${claudeBin} "$@"
  '';

  # Auto-selects claude-work or claude-personal based on current directory.
  # ~/code/work and all subdirectories → claude-work, everything else → claude-personal.
  # Not involved when running inside a devcontainer (handled by docker-compose mount).
  claudeAuto = pkgs.writeShellScriptBin "claude" ''
    work_path="/home/${osConfig.myProfile.username}/code/work"

    if [[ "$PWD" == "$work_path" || "$PWD" == "$work_path/"* ]]; then
      exec claude-work "$@"
    else
      exec claude-personal "$@"
    fi
  '';
in

{
  home.stateVersion = "25.11";

  programs.bash.enable = true;

  programs.zsh = {
    enable = true;
    syntaxHighlighting.enable = true;
    oh-my-zsh = {
      enable = true;
      theme = "robbyrussell";
      plugins = [ "git" ];
    };
  };

  programs.direnv = {
    enable = true;
    nix-direnv.enable = true;
  };

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

      url."git@github.com:".insteadOf = "https://github.com/";
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

  home.sessionVariables = {
    CLAUDE_CONFIG_DIR = "/home/${osConfig.myProfile.username}/claude-personal-home/.claude";
  };

  # Sets CLAUDE_CONFIG_DIR in the shell environment for ~/code/work.
  # This is read by devcontainers (docker-compose mounts this env var in) so
  # Claude inside the container uses the work config, not the personal one.
  home.file."code/work/.envrc".text = ''
    export CLAUDE_CONFIG_DIR=~/claude-work-home/.claude
  '';

  home.packages = [ claudeAuto ] ++ map mkClaudeWrapper [ "work" "personal" ];
}
