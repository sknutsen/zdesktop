# Home Manager module
{
  inputs,
  lib,
}: {
  config,
  pkgs,
  ...
}: let
  inherit (lib) maintainers;
  inherit (lib.modules) mkIf;
  inherit (lib.options) mkEnableOption mkPackageOption;

  cfg = config.programs.zdkshell;
in {
  imports = [
  ];

  meta.maintainers = with maintainers; [sknutsen];

  # conceptual
  options.programs.zdkshell = {
    enable = mkEnableOption "zdkshell";
    package = mkPackageOption pkgs "quickshell" {}; # from your flake input/overlay
    systemd.enable = mkEnableOption "autostart" // {default = true;};
  };

  config = mkIf cfg.enable {
    programs.quickshell = {
      enable = true;
      package = cfg.package; # inputs.quickshell.packages.${pkgs.system}.default
      configs.zdkshell = "${pkgs.zdkshell}/share/zdkshell"; # or ./../../../shell
      activeConfig = "zdkshell";
      systemd = {
        enable = cfg.systemd.enable;
        target = "hyprland-session.target"; # once Hyprland is in the picture
      };
    };

    # themes (see below)
    xdg.configFile."zdesktop/themes.toml".source = ../../../themes.toml;
  };
}
