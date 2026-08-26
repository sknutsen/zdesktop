{
  config,
  lib,
  ...
}: let
  inherit (lib) mkIf mkEnableOption;

  cfg = config.programs.zdkhypr;
  desktop = config.zdesktop;
in {
  imports = [./theme.nix];

  options.programs.zdkhypr = {
    enable = mkEnableOption "zdesktop Hyprland config";
  };

  config = mkIf cfg.enable {
    wayland.windowManager.hyprland = {
      enable = true;
      configType = "lua";
      systemd.enable = true;

      extraLuaFiles =
        {
          "main" = {
            content = ../../hypr/hyprland.lua;
            autoLoad = true;
          };
        }
        // lib.optionalAttrs desktop.applySystemTheme {
          "zdesktop.theme" = {
            content = desktop.generated.hyprLua;
            autoLoad = false;
          };
        };
    };

    xdg.configFile."uwsm" = {
      source = config.lib.file.mkOutOfStoreSymlink "${../../uwsm}";
      force = true;
      recursive = true;
    };
  };
}
