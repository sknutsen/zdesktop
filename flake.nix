{
  description = "zdesktop flake";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs?ref=nixos-unstable";

    quickshell = {
      url = "git+https://git.outfoxxed.me/outfoxxed/quickshell";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs = inputs @ {
    self,
    nixpkgs,
    quickshell,
  }: let
    supportedSystems = ["x86_64-linux" "x86_64-darwin" "aarch64-linux" "aarch64-darwin"];
    forAllSystems = nixpkgs.lib.genAttrs supportedSystems;
    nixpkgsFor = forAllSystems (system: import nixpkgs {inherit system;});

    quickshell = system: inputs.quickshell.packages.${system}.default;
  in {
    homeManagerModules = {
      zdkshell = {
        pkgs,
        lib,
        ...
      }: {
        imports = [./modules/home-manager/zdkshell.nix];

        programs.zdkshell = {
          package = lib.mkDefault inputs.quickshell.packages.${pkgs.system}.default;
          configPackage = lib.mkDefault self.packages.${pkgs.system}.zdkshell-config;
        };
      };

      zdkhypr = {
        imports = [./modules/home-manager/zdkhypr.nix];
      };

      default = {
        imports = [
          self.homeManagerModules.zdkshell
          self.homeManagerModules.zdkhypr
        ];
      };
    };

    packages = forAllSystems (system: let
      pkgs = nixpkgsFor.${system};
      qs = inputs.quickshell.packages.${system}.default;
      zdkshell = pkgs.callPackage ./packages/zdkshell.nix {
        quickshell = qs;
      };
    in {
      zdkshell = zdkshell.default; # wrapper binary
      zdkshell-config = zdkshell.config; # bare config path for HM
      zdkhypr-config = zdkshell.config; # bare config path for HM
      default = zdkshell.default;
    });

    # Add dependencies that are only needed for development
    devShells = forAllSystems (system: let
      pkgs = nixpkgsFor.${system};
    in {
      default = pkgs.mkShell {
        buildInputs = with pkgs; [
          (quickshell system)
        ];
      };
    });
  };
}
# quickshell --path ./shell/

