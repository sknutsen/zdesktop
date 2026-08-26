{
  config,
  lib,
  pkgs,
  ...
}: let
  inherit (lib) mkIf mkEnableOption mkPackageOption mkOption mkDefault types;

  cfg = config.programs.zdkshell;

  themesData = lib.importTOML ../../themes.toml;
  themeNames = builtins.sort builtins.lessThan (builtins.attrNames themesData.theme);
  selectedTheme =
    themesData.theme.${cfg.theme}
    or (throw "programs.zdkshell.theme: unknown theme '${cfg.theme}'");
  darkMode = selectedTheme.dark_mode or true;
  gtkThemeName = selectedTheme.gtk_theme or null;

  gtkThemePackages = {
    Nordic = pkgs.nordic;
  };

  themesToml = pkgs.writeText "themes.toml" (
    builtins.replaceStrings
    [''theme = "${themesData.active.theme}"'']
    [''theme = "${cfg.theme}"'']
    (builtins.readFile ../../themes.toml)
  );
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

    theme = mkOption {
      type = types.enum themeNames;
      default = themesData.active.theme or "nord";
      defaultText = lib.literalExpression ''(lib.importTOML ../../themes.toml).active.theme'';
      example = "nord";
      description = ''
        Theme from themes.toml. Written to `$XDG_CONFIG_HOME/zdesktop/themes.toml`
        as `[active].theme`. With `applySystemTheme`, that theme's `dark_mode`
        and `gtk_theme` also set GTK, Qt, and the desktop color-scheme.
      '';
    };

    applySystemTheme = mkOption {
      type = types.bool;
      default = true;
      description = ''
        Apply the selected theme to the session so apps follow light/dark.

        Sets GTK 3/4 `gtk-application-prefer-dark-theme`,
        `org.gnome.desktop.interface color-scheme` (the value
        xdg-desktop-portal exposes as `org.freedesktop.appearance`),
        and Qt's platform theme so Qt follows GTK.

        Hyprland's portal does not implement appearance. On NixOS, route
        Settings to the GTK portal:

            xdg.portal.extraPortals = [ pkgs.xdg-desktop-portal-gtk ];
            xdg.portal.config.hyprland."org.freedesktop.impl.portal.Settings" = [ "gtk" ];
      '';
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

    xdg.configFile."zdesktop/themes.toml".source = themesToml;

    gtk = mkIf cfg.applySystemTheme {
      enable = mkDefault true;
      theme = mkIf (gtkThemeName != null) (mkDefault {
        name = gtkThemeName;
        package = gtkThemePackages.${gtkThemeName} or null;
      });
      gtk3.extraConfig = {
        gtk-application-prefer-dark-theme = darkMode;
      };
      gtk4.extraConfig = {
        gtk-application-prefer-dark-theme = darkMode;
      };
    };

    dconf.settings = mkIf cfg.applySystemTheme {
      "org/gnome/desktop/interface" =
        {
          color-scheme =
            if darkMode
            then "prefer-dark"
            else "prefer-light";
        }
        // lib.optionalAttrs (gtkThemeName != null) {
          gtk-theme = gtkThemeName;
        };
    };

    qt = mkIf cfg.applySystemTheme {
      enable = mkDefault true;
      platformTheme = mkDefault "gtk3";
    };
  };
}
