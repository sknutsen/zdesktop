{
  config,
  lib,
  pkgs,
  ...
}: let
  inherit (lib) mkDefault mkIf;
in {
  config = mkIf (config.xdg.portal.enable or false) {
    xdg.portal.extraPortals = [pkgs.xdg-desktop-portal-gtk];
    xdg.portal.config.hyprland = {
      default = mkDefault ["hyprland" "gtk"];
      "org.freedesktop.impl.portal.Settings" = ["gtk"];
    };
  };
}
