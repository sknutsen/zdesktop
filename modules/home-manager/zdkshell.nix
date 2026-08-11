{
  config,
  lib,
  pkgs,
  ...
}: let
  inherit (lib) mkIf mkEnableOption mkPackageOption mkOption types;

  cfg = config.programs.zdkshell;
in {
  options.programs.zdkshell = {
    enable = mkEnableOption "zdkshell";

    package = mkPackageOption pkgs "quickshell" {
      nullable = true;
    };

    configPackage = mkOption {
      type = types.package;
      description = "Packaged zdkshell Quickshell config (share/zdkshell).";
    };

    systemd.enable = mkEnableOption "zdkshell systemd autostart" // {default = true;};
  };

  config = mkIf cfg.enable {
    programs.quickshell = {
      enable = true;
      package = cfg.package;
      configs.zdkshell = "${cfg.configPackage}/share/zdkshell";
      activeConfig = "zdkshell";
      systemd = {
        enable = cfg.systemd.enable;
        target = "hyprland-session.target";
      };
    };

    xdg.configFile."zdesktop/themes.toml".source = ../../themes.toml;
  };
}
