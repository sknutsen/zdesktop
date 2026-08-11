{
  description = "zdesktop flake";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs?ref=nixos-unstable";

    quickshell = {
      # add ?ref=<tag> to track a tag
      url = "git+https://git.outfoxxed.me/outfoxxed/quickshell";

      # THIS IS IMPORTANT
      # Mismatched system dependencies will lead to crashes and other issues.
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs = inputs @ {
    self,
    nixpkgs,
    quickshell,
  }: let
    # System types to support.
    supportedSystems = ["x86_64-linux" "x86_64-darwin" "aarch64-linux" "aarch64-darwin"];

    # Helper function to generate an attrset '{ x86_64-linux = f "x86_64-linux"; ... }'.
    forAllSystems = nixpkgs.lib.genAttrs supportedSystems;

    # Nixpkgs instantiated for supported system types.
    nixpkgsFor = forAllSystems (system: import nixpkgs {inherit system;});

    quickshell = system: inputs.quickshell.packages.${system}.default;
  in {
    homeManagerModules = {
      zdkshell = import ./modules/home-manager/zdkshell.nix {inherit inputs;};
      default = self.homeManagerModules.zdkshell;
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

