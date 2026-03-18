with import <nixpkgs> {};

mkShell {
  packages = [
    python313
    stdenv.cc.cc.lib
    playwright-driver.browsers
    (python313.withPackages (ps: with ps; [
      psycopg2
      numpy
      pytz
    ]))
  ];

  shellHook = ''
    if [ ! -d .venv ]; then
      echo "Creating virtualenv..."
      python -m venv .venv
    fi

    source .venv/bin/activate

    export LD_LIBRARY_PATH="${lib.makeLibraryPath [ stdenv.cc.cc.lib ]}:$LD_LIBRARY_PATH"
    export PLAYWRIGHT_BROWSERS_PATH="${playwright-driver.browsers}"
    export PLAYWRIGHT_SKIP_BROWSER_DOWNLOAD=1
    export PLAYWRIGHT_SKIP_VALIDATE_HOST_REQUIREMENTS=true
    export PLAYWRIGHT_HOST_PLATFORM_OVERRIDE="ubuntu-24.04"

    # playwright-cli: point at chromium binary from playwright-driver.browsers
    # scoped to chromium-* dir to avoid matching firefox's internal "chrome" path
    CHROMIUM_BIN=$(find -L "${playwright-driver.browsers}"/chromium-* -name "chrome" | head -1)
    mkdir -p .playwright
    printf '{"browser":{"browserName":"chromium","launchOptions":{"executablePath":"%s"}}}' \
      "$CHROMIUM_BIN" > .playwright/cli.config.json
  '';
}
