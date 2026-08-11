# AGENTS.md

Operating guide for coding agents working in this repository.

## What this is

`zdesktop` is a Nix flake that packages a personal Linux desktop:

- `zdkshell` — a [Quickshell](https://quickshell.org/) (QML) Wayland desktop shell. The QML config lives in `shell/`.
- A Hyprland config in `hypr/`.
- Home Manager modules in `modules/home-manager/` (`zdkshell`, `zdkhypr`) that wire the shell and Hyprland config into a user session.

Key files:

- `flake.nix` — packages (`zdkshell`, `zdkshell-config`), `homeManagerModules`, and a `devShells.default` that provides `quickshell`.
- `packages/zdkshell.nix` — builds the config derivation and a `zdkshell` wrapper that runs `quickshell --path <config>`.
- `shell/shell.qml` — shell entrypoint. Panel is in `shell/panel/`, control center in `shell/controlcenter/`, shared bits in `shell/core/`.
- `themes.toml` — theme definitions read at runtime from `$XDG_CONFIG_HOME/zdesktop/themes.toml` (see `shell/core/Theme.qml`).

## Prerequisites

This repo is Nix-first. You need Nix with flakes enabled:

```
mkdir -p ~/.config/nix
echo 'experimental-features = nix-command flakes' >> ~/.config/nix/nix.conf
```

If `nix` isn't on `PATH` in a non-interactive shell, source the profile first:

```
. "$HOME/.nix-profile/etc/profile.d/nix.sh"   # single-user install
# or: . /nix/var/nix/profiles/default/etc/profile.d/nix.sh  # multi-user
```

## Common commands

- Build the shell package: `nix build .#zdkshell` (produces `./result/bin/zdkshell`).
- Enter the dev shell (provides `quickshell`): `nix develop`.
- Evaluate everything / lint the flake: `nix flake check`.
  - A `warning: unknown flake output 'homeManagerModules'` is expected and harmless — that output name isn't part of the flake schema.
- Run the shell on a real Hyprland/Wayland session: `quickshell --path ./shell/` (or run the built `./result/bin/zdkshell`).

The first build compiles Quickshell from source (large Qt/C++ build) unless a binary cache serves it; subsequent builds are cached.

## Testing changes

- QML/config-only changes: `nix flake check` plus running `quickshell --path ./shell/` against a live session is the fastest signal. Quickshell hot-reloads QML by default.
- Package/flake changes: `nix build .#zdkshell` and `nix flake check`.

### Running the shell headless (no GPU / CI / Cloud Agent)

The shell targets Hyprland, but Hyprland's backend (aquamarine) needs a DRM device and won't start without `/dev/dri`. To render the shell in a headless, GPU-less environment for screenshots, use Sway's headless backend with the pixman (software) renderer and Qt's software backend:

```
export XDG_RUNTIME_DIR=/tmp/xdgrt; mkdir -p "$XDG_RUNTIME_DIR"; chmod 700 "$XDG_RUNTIME_DIR"

# 1) Start a headless compositor (wlr-layer-shell + software rendering, no GPU needed)
WLR_BACKENDS=headless WLR_RENDERER=pixman WLR_LIBINPUT_NO_DEVICES=1 \
  sway &                     # creates output HEADLESS-1 at 1920x1080 on wayland-1

# 2) Run the shell against it with Qt software rendering
export WAYLAND_DISPLAY=wayland-1 QT_QPA_PLATFORM=wayland QT_QUICK_BACKEND=software
./result/bin/zdkshell &

# 3) Capture a screenshot
grim -o HEADLESS-1 /tmp/shot.png
```

`sway`, `grim`, and a Nerd Font (the shell uses `MesloLGS Nerd Font Mono`) can be provided via `nix shell nixpkgs#sway nixpkgs#grim nixpkgs#nerd-fonts.meslo-lg`.

Caveats under Sway (vs. Hyprland):

- `shell/panel/WorkspaceArea.qml` uses `Quickshell.Hyprland`; with no Hyprland running you'll see `$HYPRLAND_INSTANCE_SIGNATURE is unset` and the workspace widget stays hidden. The rest of the panel (logo, clock) renders normally.
- The control center (`shell/core/ClickAwayPopup.qml`) is a grabbing `PopupWindow` that needs a focused seat, so it won't open in an input-less headless session without synthesizing input.

## Conventions

- Formatting follows `.editorconfig`. Nix files use the flake's formatter conventions (2-space indent).
- Prefer the repo's pinned inputs; don't run `nix flake update` or rewrite `flake.lock` unless explicitly asked.
