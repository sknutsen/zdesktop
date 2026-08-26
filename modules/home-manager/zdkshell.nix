{
  config,
  lib,
  pkgs,
  ...
}: let
  inherit (lib) mkIf mkEnableOption mkPackageOption mkOption types;

  cfg = config.programs.zdkshell;
  desktop = config.zdesktop;

  replaceTomlSection = contents: sectionName: newSection: let
    inherit (lib.strings) trim;
    header = "[${sectionName}]";
    lines = lib.splitString "\n" contents;
    acc =
      lib.foldl' (
        state: line: let
          trimmed = trim line;
          isHeader = lib.hasPrefix "[" trimmed;
        in
          if state.phase == "before"
          then
            if trimmed == header
            then {
              phase = "in";
              found = true;
              lines = state.lines ++ [newSection];
            }
            else {
              inherit (state) phase found;
              lines = state.lines ++ [line];
            }
          else if state.phase == "in"
          then
            if isHeader && trimmed != header
            then {
              phase = "after";
              found = true;
              lines = state.lines ++ [line];
            }
            else state
          else {
            inherit (state) phase found;
            lines = state.lines ++ [line];
          }
      ) {
        phase = "before";
        found = false;
        lines = [];
      }
      lines;
    joined = lib.concatStringsSep "\n" acc.lines;
  in
    if acc.found
    then joined
    else newSection + "\n\n" + contents;

  activeSection = ''
    [active]
    theme = "${desktop.theme}"
    apply_system_theme = ${lib.boolToString desktop.applySystemTheme}
  '';

  themesToml = pkgs.writeText "themes.toml" (
    replaceTomlSection (builtins.readFile ../../themes.toml) "active" activeSection
  );
in {
  imports = [
    ./theme.nix
    (lib.mkAliasOptionModule ["programs" "zdkshell" "theme"] ["zdesktop" "theme"])
    (lib.mkAliasOptionModule ["programs" "zdkshell" "applySystemTheme"] ["zdesktop" "applySystemTheme"])
  ];

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

    xdg.configFile."zdesktop/themes.toml".source = themesToml;
  };
}
