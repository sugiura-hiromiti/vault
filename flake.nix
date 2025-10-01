{
  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixpkgs-unstable";
    flake-utils.url = "github:numtide/flake-utils";
  };

  outputs =
    {
      self,
      nixpkgs,
      flake-utils,
    }:
    flake-utils.lib.eachDefaultSystem (
      system:
      let
        pkgs = nixpkgs.legacyPackages.${system};
      in
      {
        devShells.default = pkgs.mkShell {
          buildInputs = with pkgs; [
            zenn-cli
          ];

          shellHook = ''
            echo -e "\033[1;32m\noutput environment loaded"
            echo -e "System: ${system}"
            echo -e "zenn-cli:     $(which cargo 2>/dev/null || echo 'not found')\033[0m"
          '';
        };
      }
    );
}
