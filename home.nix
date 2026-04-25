{ osConfig, pkgs, unstable, ... }:

let
  nixvimLib = import (builtins.fetchTarball {
    url = "https://github.com/nix-community/nixvim/archive/main.tar.gz";
  });

  nvim = nixvimLib.legacyPackages.${pkgs.system}.makeNixvimWithModule {
    pkgs = unstable;
    module = import ./nixvim/nixvim-module.nix;
  };

  dshScript = pkgs.writeShellScriptBin "dsh" ''
    if [ ! -f ".devcontainer/devcontainer.json" ] && [ ! -f "devcontainer.json" ]; then
      echo "No devcontainer config found in current directory"
      exit 1
    fi
    exec devcontainer exec --workspace-folder . sh -c 'which zsh && exec zsh || exec bash'
  '';

  devScript = pkgs.writeShellScriptBin "dev" ''
    set -e
    SESSION=$(basename "$PWD")
    REBUILD=""
    NO_CACHE=""
    for arg in "$@"; do
      case "$arg" in
        --rebuild) REBUILD="--remove-existing-container" ;;
        --no-cache) NO_CACHE="--build-no-cache" ;;
      esac
    done

    # Attach to existing session if already running (skip if rebuilding)
    if tmux has-session -t "$SESSION" 2>/dev/null; then
      if [ -z "$REBUILD" ]; then
        tmux attach-session -t "$SESSION"
        exit 0
      else
        tmux kill-session -t "$SESSION"
      fi
    fi

    tmux new-session -d -s "$SESSION"

    # Left pane: neovim
    tmux send-keys -t "$SESSION" "nvim ." Enter

    # Right pane: claude — inside container if devcontainer config exists, otherwise on host
    tmux split-window -h -t "$SESSION"
    if [ -f ".devcontainer/devcontainer.json" ] || [ -f "devcontainer.json" ]; then
      # Auto-rebuild if devcontainer config files have changed since last run
      HASH_FILE="/tmp/devcontainer-hash-$SESSION"
      CURRENT_HASH=$(cat \
        devcontainer.json \
        .devcontainer/devcontainer.json \
        .devcontainer/Dockerfile \
        .devcontainer/docker-compose.yml \
        docker-compose.yml \
        2>/dev/null | sha256sum | cut -d' ' -f1)
      STORED_HASH=$(cat "$HASH_FILE" 2>/dev/null || echo "")
      if [ "$CURRENT_HASH" != "$STORED_HASH" ]; then
        echo "Devcontainer config changed, rebuilding..."
        REBUILD="--remove-existing-container"
      fi

      echo "Starting devcontainer..."
      devcontainer up $REBUILD $NO_CACHE --workspace-folder .
      echo "$CURRENT_HASH" > "$HASH_FILE"
      tmux send-keys -t "$SESSION" "devcontainer exec --workspace-folder . claude" Enter
    else
      tmux send-keys -t "$SESSION" "claude" Enter
    fi

    # Focus neovim
    tmux select-pane -t "$SESSION:0.0"

    tmux attach-session -t "$SESSION"
  '';

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

  programs.tmux = {
    enable = true;
    mouse = true;
    extraConfig = ''
      set -g @scroll-speed-num-lines-per-scroll "1"
      run-shell ${pkgs.tmuxPlugins.better-mouse-mode}/share/tmux-plugins/better-mouse-mode/scroll_copy_mode.tmux
    '';
  };
  programs.lazygit.enable = true;

  home.packages = [ claudeAuto nvim devScript dshScript pkgs.lazydocker pkgs.devcontainer ] ++ map mkClaudeWrapper [ "work" "personal" ];
}
