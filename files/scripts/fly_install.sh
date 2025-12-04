#!/bin/sh
# Based on Fly.io install script - https://fly.io/install.sh
# which is based on Deno installer: Copyright 2019 the Deno authors. All rights reserved. MIT license.

set -e

main() {
    os=$(uname -s)
    arch=$(uname -m)
    version=${1:-latest}

    # get download URL
    flyctl_uri=$(curl -s ${FLY_FORCE_TRACE:+ -H "Fly-Force-Trace: $FLY_FORCE_TRACE"} https://api.fly.io/app/flyctl_releases/$os/$arch/$version)

    # location for binary to be installed
    flyctl_install="${FLYCTL_INSTALL:-$HOME/.fly/bin}"

    mkdir -p "$flyctl_install"
    tmp_dir=$(mktemp -d)

    exe="$flyctl_install/flyctl"
    simexe="$flyctl_install/fly"

    curl -q --fail --location --progress-bar --output "$tmp_dir/flyctl.tar.gz" "$flyctl_uri"

    # extract to tmp dir so we don't open existing executable file for writing:
    tar -C "$tmp_dir" -xzf "$tmp_dir/flyctl.tar.gz"
    chmod +x "$tmp_dir/flyctl"

    # atomically rename into place
    mv "$tmp_dir/flyctl" "$exe"
    # create symlink
    ln -sf $exe $simexe

    # set update channel
    if [ "${1}" = "prerel" ] || [ "${1}" = "pre" ]; then
        "$exe" version -s "shell-prerel"
    else
        "$exe" version -s "shell"
    fi

    echo "flyctl was installed successfully to $exe"
    if command -v flyctl >/dev/null; then
        echo "Run 'flyctl --help' to get started"
    else
        case $SHELL in
        /bin/zsh) shell_profile=".zshrc" ;;
        *) shell_profile=".bash_profile" ;;
        esac
        echo "Manually add the directory to your \$HOME/$shell_profile (or similar)"
        echo "  export FLYCTL_INSTALL=\"$flyctl_install\""
        echo "  export PATH=\"\$FLYCTL_INSTALL/bin:\$PATH\""
        echo "Run '$exe --help' to get started"
    fi
}

main "$1"
