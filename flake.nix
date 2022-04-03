{
  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixpkgs-unstable";
    poetry2nix = {
      url = "github:nix-community/poetry2nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    futils.url = "github:numtide/flake-utils";
  };

  outputs = { self, nixpkgs, poetry2nix, futils } @ inputs:
    let
      inherit (nixpkgs) lib;
      inherit (lib) recursiveUpdate;
      inherit (futils.lib) eachDefaultSystem defaultSystems;

      nixpkgsFor = lib.genAttrs defaultSystems (system: import nixpkgs {
        inherit system;
        overlays = [ poetry2nix.overlay ];
      });
    in
    (eachDefaultSystem (system:
      let
        pkgs = nixpkgsFor.${system};
      in
      {
        devShell = pkgs.mkShell {
          buildInputs = with pkgs; [
            (pkgs.poetry2nix.mkPoetryEnv {
              projectDir = self;

              overrides = pkgs.poetry2nix.overrides.withDefaults (self: super: {
                ansible = super.ansible.overridePythonAttrs (old: {
                  prePatch = "";
                });

                iso8601 = super.iso8601.overridePythonAttrs (old: {
                  buildInputs = old.buildInputs ++ [ self.poetry ];
                });
              });
            })
            git
            go
            jsonnet
            jsonnet-bundler
            openssl
            poetry
            pre-commit
            shellcheck
            terraform
            vault
            velero
          ];

          shellHook = ''
            source ./config.sh
          '';
        };
      }
    ));
}
