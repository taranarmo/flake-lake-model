{
  description = "FLake - Fresh-water Lake Model (Fortran core and CLI driver)";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    flake-utils.url = "github:numtide/flake-utils";
  };

  outputs = { self, nixpkgs, flake-utils }:
    flake-utils.lib.eachDefaultSystem (system:
      let
        pkgs = import nixpkgs { inherit system; };
      in {
        packages.default = pkgs.stdenv.mkDerivation {
          pname = "flake-lake-model";
          version = "1.0.0";
          src = ./.;

          nativeBuildInputs = [ pkgs.gfortran pkgs.cmake ];

          buildPhase = ''
            cmake -B build -DCMAKE_INSTALL_PREFIX=$out
            cmake --build build -j$NIX_BUILD_CORES
          '';

          checkPhase = ''
            ctest --test-dir build --output-on-failure
          '';

          installPhase = ''
            cmake --install build
          '';

          doCheck = true;
        };

        packages.wasm = pkgs.stdenv.mkDerivation {
          pname = "flake-wasm";
          version = "1.0.0";
          src = ./.;

          nativeBuildInputs = [
            pkgs.lfortran
            pkgs.llvmPackages.llvm
            pkgs.llvmPackages.lld
            pkgs.nodejs
          ];

          buildPhase = ''
            patchShebangs test/
            ./test/build_and_test_wasm.sh
          '';

          installPhase = ''
            mkdir -p $out/bin
            cp build_wasm/flake.wasm $out/bin/
          '';
        };

        devShells.default = pkgs.mkShell {
          packages = with pkgs; [
            gfortran
            cmake
            ninja
            gnumake
            lfortran
            llvmPackages.llvm
            llvmPackages.lld
            nodejs
          ];
        };
      }
    );
}
