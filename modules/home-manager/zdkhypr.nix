{
  config,
  lib,
  ...
}: let
  inherit (lib) mkIf mkEnableOption;

  cfg = config.programs.zdkhypr;
in {
  options.programs.zdkhypr = {
    enable = mkEnableOption "zdesktop Hyprland config";
  };

  config = mkIf cfg.enable {
    wayland.windowManager.hyprland = {
      enable = true;
      systemd.enable = true;

      # Keep the full config as a sourced file so it stays editable as plain conf.
      # Home Manager still owns enable/systemd so zdkshell can bind to hyprland-session.target.
      # extraConfig = ''
      #   source = ${../../hypr/hyprland.lua}
      # '';
    };

    xdg.configFile."hypr" = {
      source = config.lib.file.mkOutOfStoreSymlink "${../../hypr}";
      force = true;
      recursive = true;
    };
  };
}
