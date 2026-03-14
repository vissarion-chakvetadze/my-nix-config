# nix-config

My personal NixOS configuration.

## Highlights

### Dual Claude Code isolation

`claude-work` and `claude-personal` are shell wrappers that launch Claude Code with completely separate identities — different `CLAUDE_HOME`, `CLAUDE_CONFIG_DIR`, and temp dirs. A `claude` alias blocks the bare command to prevent accidentally mixing contexts.

### Secure Boot with Lanzaboote

UEFI Secure Boot via [lanzaboote](https://github.com/nix-community/lanzaboote) and sbctl for key management, pinned via [lon](https://github.com/nickel-lang/lon).

### NVIDIA Prime offload + local AI

Hybrid Intel/NVIDIA GPU with fine-grained power management. NVIDIA only activates on demand via `nvidia-offload`. Ollama is built with CUDA acceleration for local LLM inference.

### Virtual camera pipeline

v4l2loopback kernel module exposing a virtual V4L2 device, with mediamtx running a local RTSP/RTMP server (bound to localhost only).

### Private profile abstraction

`options.nix` defines a `myProfile` NixOS option set (username, full name, email, timezone). The actual values live in `private.nix`, which is `.gitignore`d. This keeps the entire config shareable without leaking personal data.

### Home Manager

User environment managed declaratively:
- Git configured with per-directory email overrides (work vs personal) via `gitdir` conditions
- npm global prefix set to `~/.npm-global` — no sudo for global installs
- Shell aliases and session PATH managed in Nix

## Structure

```
configuration.nix       # Entry point, imports everything
options.nix             # myProfile option definitions
my-config.nix           # Main system config (packages, services, hardware)
home.nix                # Home Manager config
private.nix             # Personal values — not in git
lon.nix                 # Dependency lock file (lon)
hardware-configuration.nix
```

## Applying

```bash
sudo nixos-rebuild build
sudo nixos-rebuild test
sudo nixos-rebuild switch
```
