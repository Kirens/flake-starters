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
  };

  outputs = i0: i0.flake-starters.lib.perSystem i0 {
    devenv.shells.default = {
      name = "node env";
      languages.javascript = {
        enable = true;
        pnpm.enable = true;
      };
    };
  };
}
