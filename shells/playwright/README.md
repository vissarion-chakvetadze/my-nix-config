# Playwright Nix Shell

NixOS-compatible shell for projects using Node.js Playwright (Vite, Storybook, etc.) alongside `playwright-cli`.

## Usage

Symlink `shell.nix` into your project:

```bash
ln -sf ~/code/nix-config/shells/playwright/shell.nix ~/code/work/your-project/shell.nix
```

Then enter the shell:

```bash
nix-shell
```

## Why this exists

On NixOS, `npx playwright install` doesn't work — downloaded browser binaries have hardcoded library paths that don't exist on NixOS. Instead, `playwright-driver.browsers` provides NixOS-compatible browsers via nixpkgs.

Two separate issues needed solving:

**Node.js Playwright** (for tests): respects `PLAYWRIGHT_BROWSERS_PATH`, so pointing it at `playwright-driver.browsers` works out of the box.

**playwright-cli**: defaults to the `chrome` channel (looks for Google Chrome at `/opt/google/chrome/chrome`) and ignores `PLAYWRIGHT_BROWSERS_PATH`. The fix is a `.playwright/cli.config.json` config file with `browser.browserName` and `browser.launchOptions.executablePath` set explicitly.

The `find` for the chromium binary is scoped to `chromium-*` to avoid matching Firefox's internal `chrome` directory, which would cause a false match.

## Python packages

The shell includes a Python venv with `psycopg2`, `numpy`, and `pytz`. Adjust the `withPackages` list as needed for your project.
