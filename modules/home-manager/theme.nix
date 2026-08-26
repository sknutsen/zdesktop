{
  config,
  lib,
  options,
  ...
}: let
  inherit (lib) mkIf mkMerge mkOption mkDefault mkOverride optionalAttrs optionalString types;

  # Beat nvf's own mkDefault (1000) so enable/name/style/transparent apply,
  # but stay below a bare assignment (100) so the host config still wins.
  mkNvfDefault = mkOverride 900;

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

  # nvf vim.theme.{name,style} for each themes.toml name. Unmapped themes
  # (and monochrome) fall back to base16 built from the terminal palette.
  nvfThemeByName = {
    nord = {name = "nord";};
    dracula = {name = "dracula";};
    gruvbox = {
      name = "gruvbox";
      style = "dark";
    };
    catppuccin = {
      name = "catppuccin";
      style = "mocha";
    };
    tokyonight = {
      name = "tokyonight";
      style = "night";
    };
    onedark = {
      name = "onedark";
      style = "dark";
    };
    solarized = {
      name = "solarized";
      style = "dark";
    };
    rosepine = {
      name = "rose-pine";
      style = "main";
    };
    everforest = {
      name = "everforest";
      style = "medium";
    };
    catppuccin-latte = {
      name = "catppuccin";
      style = "latte";
    };
    gruvbox-light = {
      name = "gruvbox";
      style = "light";
    };
    solarized-light = {
      name = "solarized";
      style = "light";
    };
    rosepine-dawn = {
      name = "rose-pine";
      style = "dawn";
    };
    tokyonight-day = {
      name = "tokyonight";
      style = "day";
    };
  };

  nvfTheme = nvfThemeByName.${cfg.theme} or {name = "base16";};

  nvfBase16Colors = {
    base00 = css "term_bg" "2E3440";
    base01 = css "normbgcolor" "434C5E";
    base02 = css "selbgcolor" "434C5E";
    base03 = css "term_color8" "4C566A";
    base04 = css "term_color7" "E5E9F0";
    base05 = css "term_fg" "D8DEE9";
    base06 = css "selfgcolor" "ECEFF4";
    base07 = css "term_color15" "ECEFF4";
    base08 = css "term_color1" "BF616A";
    base09 = css "term_color9" "BF616A";
    base0A = css "term_color3" "EBCB8B";
    base0B = css "term_color2" "A3BE8C";
    base0C = css "term_color6" "88C0D0";
    base0D = css "term_color4" "81A1C1";
    base0E = css "term_color5" "B48EAD";
    base0F = css "term_color11" "EBCB8B";
  };

  # HM ghostty uses pkgs.formats.keyValue, which stores each value as a list
  # (listsAsDuplicateKeys), e.g. background-opacity = [ 0.8 ].
  unwrapKeyValue = v:
    if builtins.isList v
    then
      if v == []
      then null
      else unwrapKeyValue (builtins.head v)
    else v;

  ghosttySettings =
    if options.programs ? ghostty
    then config.programs.ghostty.settings or {}
    else {};
  ghosttyOpacityRaw = unwrapKeyValue (
    if builtins.isAttrs ghosttySettings
    then ghosttySettings.background-opacity or 1
    else 1
  );
  ghosttyOpacity =
    if builtins.isInt ghosttyOpacityRaw || builtins.isFloat ghosttyOpacityRaw
    then ghosttyOpacityRaw
    else if builtins.isString ghosttyOpacityRaw
    then builtins.fromJSON ghosttyOpacityRaw
    else 1;
  # Neovim cannot take a fractional opacity; bg=NONE lets Ghostty's
  # already-translucent background show through.
  nvfTransparent = ghosttyOpacity < 1;

  nvfThemeSettings =
    {
      enable = mkNvfDefault true;
      name = mkNvfDefault nvfTheme.name;
      transparent = mkNvfDefault nvfTransparent;
      extraConfig = ''
        vim.opt.background = "${
          if darkMode
          then "dark"
          else "light"
        }"
        ${optionalString nvfTransparent ''
          vim.api.nvim_create_autocmd("ColorScheme", {
            group = vim.api.nvim_create_augroup("zdesktop_transparent", { clear = true }),
            callback = function()
              for _, group in ipairs({
                "Normal", "NormalNC", "NormalFloat", "SignColumn",
                "EndOfBuffer", "LineNr", "Folded", "FoldColumn",
              }) do
                vim.api.nvim_set_hl(0, group, { bg = "none" })
              end
            end,
          })
        ''}
      '';
    }
    // optionalAttrs (nvfTheme ? style) {
      style = mkNvfDefault nvfTheme.style;
    }
    // optionalAttrs (nvfTheme.name == "base16") {
      base16-colors = nvfBase16Colors;
    };

  nvfPresent = options.programs ? nvf;
  applyNvfTheme = nvfPresent && config.programs.nvf.enable && cfg.applySystemTheme;
in {
  options.zdesktop = {
    theme = mkOption {
      type = types.enum themeNames;
      default = themesData.active.theme or "nord";
      defaultText = lib.literalExpression ''(lib.importTOML ../../themes.toml).active.theme'';
      example = "nord";
      description = ''
        Theme from themes.toml. Drives zdkshell, Hyprland borders, Ghostty,
        GTK CSS, Qt (via GTK), nvf/Neovim, and the desktop color-scheme.
      '';
    };

    applySystemTheme = mkOption {
      type = types.bool;
      default = true;
      description = ''
        Apply the selected theme outside the shell: Hyprland colors, Ghostty
        palette, GTK CSS / color-scheme, Qt following GTK, and nvf/Neovim
        when `programs.nvf` is imported and enabled.

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

        nvf/Neovim: maps the selected theme to `programs.nvf.settings.vim.theme`
        (named plugin + style, or base16 from the terminal palette for
        unmapped themes such as monochrome). Enable, name, style, and
        transparent use a priority above nvf's `mkDefault` so they actually
        apply, but below a bare assignment so an explicit nvf theme in the
        host config still wins.
        Sets `vim.opt.background` from `dark_mode` so light variants (e.g.
        rose-pine dawn) load correctly.

        If Ghostty `background-opacity` is below 1, nvf `theme.transparent` is
        enabled so Neovim's background is cleared and the terminal's
        translucency shows through. Neovim cannot take a fractional opacity of
        its own; stacking an opaque `Normal` highlight on a translucent
        terminal is what looks mismatched.

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

  config = mkMerge [
    {
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
        # HM 26.05+: gtk.gtk4.theme no longer follows gtk.theme. Palette
        # theming is extraCss; gtk-theme-name is a GTK 4 workaround anyway.
        gtk4.theme = mkDefault null;
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
    }
    (optionalAttrs nvfPresent {
      programs.nvf.settings.vim.theme = mkIf applyNvfTheme nvfThemeSettings;
    })
  ];
}
