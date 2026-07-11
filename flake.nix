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
      perSystem = args: module:
        mkFlake args { perSystem = module; };

      /**
        Setup the flake inheriting both the starter and flake inputs.

        # Inputs
        `args`
        : Either an attrset of inputs or attrset of additional args
        `args.inputs`
        : Attrset of intpus
        `args.lib`
        : Function to extend nixpkgs lib

        `module`
        : A flake-parts module or file
      */
      mkFlake = args: module:
        let
          libExtensionProp = "lib";
          complexArgs = args ? "inputs" && args.inputs._type or null != "flake";

          cfgArgs =
            if complexArgs
            then removeAttrs args [libExtensionProp]
            else { inputs = args; };
          config = cfgArgs // {
            inputs = baseInputs // cfgArgs.inputs // {
              self = cfgArgs.inputs.self // {
                inputs = baseInputs.self.inputs // cfgArgs.inputs.self.inputs;
              };
            };
          };

          # Extended lib
          lib =
            if complexArgs && args ? ${libExtensionProp}
            then baseInputs.nixpkgs.lib.extend args.${libExtensionProp}
            else baseInputs.nixpkgs.lib;

          # Construct an attribute set of file stems -> corresponding file path
          # This imitates how flake-parts provide module lists
          getModuleFiles = dir:
            with builtins;
            let
              filterAttrs = builtins.filterAttrs or (pred: set:
              	removeAttrs
                  set 
                  (filter (name: !pred name set.${name}) (attrNames set))
              );
              files =
                attrNames
                  (filterAttrs (_: k: k == "regular") (readDir dir));
              mkFileRef = fileName:
                let
                  stemLen = stringLength fileName - 4;
                  otherFile = ".nix" != substring stemLen 4 fileName;
                in if otherFile then null else {
                  name = substring 0 stemLen fileName;
                  value = dir + "/${fileName}";
                };
            in listToAttrs (filter (v: v != null) (map mkFileRef files));


          flake-parts-lib = import "${baseInputs.flake-parts}/lib.nix" {
            inherit lib;
            builtinModules = getModuleFiles "${baseInputs.flake-parts}/modules";
            extraModules = getModuleFiles "${baseInputs.flake-parts}/extras";
          };
        in flake-parts-lib.mkFlake config {
          imports = [ module ./module.nix ];
        };
    };

    templates =
      builtins.mapAttrs
        (name: _: rec {
          path = ./templates + "/${name}";
          inherit (import "${path}/flake.nix") description;
        })
        (builtins.readDir ./templates);
  };
}
