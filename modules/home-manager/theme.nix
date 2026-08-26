{
  config,
  lib,
  options,
  ...
}: let
  inherit (lib) mkIf mkOption mkDefault types;

  cfg = config.zdesktop;
  themesData = lib.importTOML ../../themes.toml;
  themeNames = builtins.sort builtins.lessThan (builtins.attrNames themesData.theme);
  selectedTheme =
    themesData.theme.${cfg.theme}
    or (throw "zdesktop.theme: unknown theme '${cfg.theme}'");
  darkMode = selectedTheme.dark_mode or true;
  gtkThemeName = selectedTheme.gtk_theme or null;
  defaultGtkThemeName = "Adwaita";
  resolvedGtkTheme =
    if gtkThemeName == null
    then defaultGtkThemeName
    else gtkThemeName;
  borderpx = themesData.appearance.borderpx or 1;

  hex = key: fallback:
    lib.toLower (lib.removePrefix "#" (selectedTheme.${key} or fallback));
  css = key: fallback: "#${hex key fallback}";
  rgba = key: fallback: alpha: "rgba(${hex key fallback}${alpha})";

  paletteIndexes = lib.range 0 15;

  hyprLua = ''
    -- Generated from themes.toml theme "${cfg.theme}"
    return {
      active_border = "${rgba "selbordercolor" "81A1C1" "ee"}",
      active_border_alt = "${rgba "term_color6" "88C0D0" "ee"}",
      inactive_border = "${rgba "normbordercolor" "3B4252" "aa"}",
      shadow = "${rgba "term_bg" "2E3440" "ee"}",
      border_size = ${toString borderpx},
    }
  '';

  ghosttyTheme = ''
    background = ${css "term_bg" "2E3440"}
    foreground = ${css "term_fg" "D8DEE9"}
    cursor-color = ${css "term_cursor" "81A1C1"}
    cursor-text = ${css "term_bg" "2E3440"}
    selection-background = ${css "selbgcolor" "434C5E"}
    selection-foreground = ${css "selfgcolor" "ECEFF4"}
    ${lib.concatMapStringsSep "\n" (
        i: "palette = ${toString i}=${css "term_color${toString i}" "000000"}"
      )
      paletteIndexes}
  '';

  gtkCss = ''
    @define-color accent_color ${css "selbordercolor" "81A1C1"};
    @define-color accent_bg_color ${css "selbordercolor" "81A1C1"};
    @define-color accent_fg_color ${css "term_bg" "2E3440"};
    @define-color window_bg_color ${css "term_bg" "2E3440"};
    @define-color window_fg_color ${css "term_fg" "D8DEE9"};
    @define-color view_bg_color ${css "normbgcolor" "434C5E"};
    @define-color view_fg_color ${css "normfgcolor" "D8DEE9"};
    @define-color headerbar_bg_color ${css "normbgcolor" "434C5E"};
    @define-color headerbar_fg_color ${css "selfgcolor" "ECEFF4"};
    @define-color headerbar_border_color ${css "normbordercolor" "3B4252"};
    @define-color headerbar_backdrop_color ${css "term_bg" "2E3440"};
    @define-color card_bg_color ${css "normbgcolor" "434C5E"};
    @define-color card_fg_color ${css "normfgcolor" "D8DEE9"};
    @define-color popover_bg_color ${css "normbgcolor" "434C5E"};
    @define-color popover_fg_color ${css "normfgcolor" "D8DEE9"};
    @define-color dialog_bg_color ${css "normbgcolor" "434C5E"};
    @define-color dialog_fg_color ${css "normfgcolor" "D8DEE9"};
    @define-color sidebar_bg_color ${css "term_bg" "2E3440"};
    @define-color sidebar_fg_color ${css "term_fg" "D8DEE9"};
    @define-color theme_bg_color ${css "term_bg" "2E3440"};
    @define-color theme_fg_color ${css "term_fg" "D8DEE9"};
    @define-color theme_selected_bg_color ${css "selbordercolor" "81A1C1"};
    @define-color theme_selected_fg_color ${css "term_bg" "2E3440"};
    @define-color destructive_bg_color ${css "term_color1" "BF616A"};
    @define-color destructive_fg_color ${css "term_bg" "2E3440"};
    @define-color success_color ${css "term_color2" "A3BE8C"};
    @define-color warning_color ${css "term_color3" "EBCB8B"};
    @define-color error_color ${css "term_color1" "BF616A"};
    @define-color borders ${css "normbordercolor" "3B4252"};
  '';

  desktopEnabled =
    (options.programs ? zdkshell && config.programs.zdkshell.enable)
    || (options.programs ? zdkhypr && config.programs.zdkhypr.enable);
in {
  options.zdesktop = {
    theme = mkOption {
      type = types.enum themeNames;
      default = themesData.active.theme or "nord";
      defaultText = lib.literalExpression ''(lib.importTOML ../../themes.toml).active.theme'';
      example = "nord";
      description = ''
        Theme from themes.toml. Drives zdkshell, Hyprland borders, Ghostty,
        GTK CSS, Qt (via GTK), and the desktop color-scheme.
      '';
    };

    applySystemTheme = mkOption {
      type = types.bool;
      default = true;
      description = ''
        Apply the selected theme outside the shell: Hyprland colors, Ghostty
        palette, GTK CSS / color-scheme, and Qt following GTK.

        Sets GTK `colorScheme`, GTK 3/4 `gtk-application-prefer-dark-theme`
        (including `false` for light themes), `org.gnome.desktop.interface
        color-scheme` (the value xdg-desktop-portal exposes as
        `org.freedesktop.appearance`), and Qt's platform theme so Qt follows
        GTK.

        Written to `[active].apply_system_theme` in themes.toml so the shell
        only runs `gsettings` when this option is true.

        `gtk_theme` in the selected theme is a theme name only (not packaged
        here). If a theme omits `gtk_theme`, gtk-theme is reset to Adwaita
        rather than leaving the previous value. Palette colors are always
        applied as GTK CSS on top of that.

        Hyprland's portal does not implement appearance. On NixOS, route
        Settings to the GTK portal:

            xdg.portal.extraPortals = [ pkgs.xdg-desktop-portal-gtk ];
            xdg.portal.config.hyprland."org.freedesktop.impl.portal.Settings" = [ "gtk" ];
      '';
    };

    generated = {
      hyprLua = mkOption {
        type = types.lines;
        internal = true;
        readOnly = true;
      };
      ghosttyTheme = mkOption {
        type = types.lines;
        internal = true;
        readOnly = true;
      };
      gtkCss = mkOption {
        type = types.lines;
        internal = true;
        readOnly = true;
      };
    };
  };

  config = {
    zdesktop.generated = {
      inherit hyprLua ghosttyTheme gtkCss;
    };

    gtk = mkIf (desktopEnabled && cfg.applySystemTheme) {
      enable = mkDefault true;
      colorScheme = mkDefault (
        if darkMode
        then "dark"
        else "light"
      );
      theme = mkDefault {
        name = resolvedGtkTheme;
      };
      gtk3.extraConfig = {
        gtk-application-prefer-dark-theme = darkMode;
      };
      gtk4.extraConfig = {
        gtk-application-prefer-dark-theme = darkMode;
      };
      gtk3.extraCss = mkDefault gtkCss;
      gtk4.extraCss = mkDefault gtkCss;
    };

    dconf.settings = mkIf (desktopEnabled && cfg.applySystemTheme) {
      "org/gnome/desktop/interface" = {
        color-scheme =
          if darkMode
          then "prefer-dark"
          else "prefer-light";
        gtk-theme = resolvedGtkTheme;
      };
    };

    qt = mkIf (desktopEnabled && cfg.applySystemTheme) {
      enable = mkDefault true;
      platformTheme.name = mkDefault "gtk3";
    };

    xdg.configFile."ghostty/themes/zdesktop" = mkIf (desktopEnabled && cfg.applySystemTheme) {
      text = ghosttyTheme;
    };

    programs.ghostty.settings.theme = mkIf (desktopEnabled && cfg.applySystemTheme) (mkDefault "zdesktop");
  };
}
