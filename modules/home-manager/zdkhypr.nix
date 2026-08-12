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
      configType = "lua";
      systemd.enable = true;

      # Keep the full config as a sourced file so it stays editable as plain conf.
      # Home Manager still owns enable/systemd so zdkshell can bind to hyprland-session.target.
      extraLuaFiles = {
        "main" = {
          content = ../../hypr/hyprland.lua;
          autoLoad = true;
        };
      };
    };

    # xdg.configFile."hypr" = {
    #   source = config.lib.file.mkOutOfStoreSymlink "${../../hypr}";
    #   force = true;
    #   recursive = true;
    # };

    xdg.configFile."uwsm" = {
      source = config.lib.file.mkOutOfStoreSymlink "${../../uwsm}";
      force = true;
      recursive = true;
    };
  };
}
