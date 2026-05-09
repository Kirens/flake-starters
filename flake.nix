{
  description = "Flake starters - devenv bootstraping";

  inputs = {
    systems.url = "github:nix-systems/default";
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";

    flake-parts.url = "github:hercules-ci/flake-parts";
    flake-parts.inputs.nixpkgs-lib.follows = "nixpkgs";

    devenv-root = { url = "file+file:///dev/null"; flake = false; };
    devenv.url = "github:cachix/devenv";
    # devenv has a huge footprint, but none seem essential when we use it as a flake module
    devenv.inputs = {
      nixpkgs.follows = "";
      cachix.follows = "";
      crate2nix.follows = "";
      flake-compat.follows = "";
      flake-parts.follows = "";
      ghostty.follows = "";
      nix.follows = "";
      nixd.follows = "";
      rust-overlay.follows = "";
    };

    # Not sure if needed, maybe used by devenv for tests?
    nix2container.url = "github:nlewo/nix2container";
    nix2container.inputs.nixpkgs.follows = "nixpkgs";
    mk-shell-bin.url = "github:rrbutani/nix-mk-shell-bin";
  };

  outputs = baseInputs: {
    lib = rec {
      perSystem = flakeInputs: module:
        mkFlake flakeInputs { perSystem = module; };

      mkFlake = flakeInputs: module:
        let
          cfgArgs =
            if flakeInputs ? inputs
            then flakeInputs
            else { inputs = flakeInputs; };
          config = cfgArgs // {
            inputs = baseInputs // cfgArgs.inputs // {
              self = cfgArgs.inputs.self // {
                inputs = baseInputs.self.inputs // cfgArgs.inputs.self.inputs;
              };
            };
          };
        in baseInputs.flake-parts.lib.mkFlake config {
          imports = [ module ./module.nix ];
        };
    };

    templates =
      let mkDesc = n: d: { path = ./templates + "/${n}"; description = d; };
      in builtins.mapAttrs mkDesc {
        default = "Basic project using flake-starters and direnv";
        node = "Javascript project flake-starters and direnv";
        rust = "Rust project using flake-starters, direnv and rust-overlay";
      };
  };
}
