{
  description = "neotest-haskell.nvim";

  inputs.flake-utils.url = "github:numtide/flake-utils";

  outputs = { self, nixpkgs, flake-utils }:
    flake-utils.lib.eachDefaultSystem (system:
      let
        pkgs = import nixpkgs { inherit system; };
        neotest-haskell-nvim = pkgs.vimUtils.buildVimPluginFrom2Nix {
          pname = "neotest-haskell-nvim";
          version = "HEAD";
          src = ./.;
        };
      in rec { defaultPackage = neotest-haskell-nvim; }) // {
        overlay = final: prev: {
          vimPlugins = prev.vimPlugins // {
            neotest-haskell-nvim = self.defaultPackage.${prev.system};
          };
        };
      };
}
