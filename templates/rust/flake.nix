{
  description = "";

  inputs = {
    devenv-root = { url = "file+file:///dev/null"; flake = false; };
    flake-starters.url = "github:Kirens/flake-starters";
    flake-starters.inputs = {
      devenv-root.follows = "devenv-root";
      # nixpkgs.url = "github:NixOS/nixpkgs/nixos-25.05";
      # systems.url = "github:nix-systems/default";
    };

    rust-overlay.url = "github:oxalica/rust-overlay";
    rust-overlay.inputs.nixpkgs.follows = "flake-starters/nixpkgs";
  };

  outputs = i0: i0.flake-starters.lib.perSystem i0 {
    devenv.shells.default = {
      name = "rust env";
      languages.rust = {
        enable = true;
        # When selecting non-nixpkgs channels devenv will use rust-overlay input
        channel = "stable";
      };
    };
  };
}
