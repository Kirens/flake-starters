{ lib, inputs, ... }: {
  imports = [ inputs.devenv.flakeModule ];
  systems = import inputs.systems;

  perSystem = { pkgs, ... }:
    let
      # A nix that inherits the devenv-root bound by the flake invocation
      nix = pkgs.writeShellScriptBin "nix" ''
        nix="$(which -a nix | sed -n 2p)"
        if [ -z "$nix" ]
        then
          echo 'No nix found in $PATH' >&2
          exit 1
        fi

        collected=()
        while true
        do
          collected+=("$1")
          arg="$1"
          shift
          case "$arg" in
            -*) : ;;
            flake) collected+=("$1"); shift ;;&
            run|build) break ;;
            *) exec -a "$0" "$nix" "''${collected[@]}" "$@"
          esac
        done
        exec -a "$0" "$nix" "''${collected[@]}" --override-input devenv-root \
          'file+file://${lib.escapeShellArg inputs.devenv-root}' "$@"
      '';
    in {
      devenv.modules = [ ({ config, ... }: {
        # Override the default nix
        packages = [ nix ];
        # Use the actual devenv defined name
        enterShell = "export name=${lib.escapeShellArg config.name}";
        # Prevent accidental impure invocations
        devenv.root =
          let root = builtins.readFile inputs.devenv-root.outPath;
          in if builtins ? currentSystem
          then throw "Trying to run impure devenv"
          else lib.mkIf (root != "") root;
      }) ];
  };
}
