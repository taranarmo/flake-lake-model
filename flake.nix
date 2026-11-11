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

        flakePackage = pkgs.stdenv.mkDerivation {
          pname = "flake-lake-model";
          version = "1.0.0";
          src = ./.;

          nativeBuildInputs = [ pkgs.gfortran pkgs.cmake ];

          doCheck = true;
        };

        dockerImage = pkgs.dockerTools.buildLayeredImage {
          name = "flake";
          tag = "latest";
          contents = [
            flakePackage
            pkgs.busybox
          ];
          config = {
            Entrypoint = [ "${flakePackage}/bin/flake" ];
            WorkingDir = "/workspace";
            Volumes = {
              "/workspace" = {};
            };
            Env = [
              "PATH=${flakePackage}/bin:${pkgs.busybox}/bin"
            ];
            Labels = {
              "org.opencontainers.image.title" = "FLake Lake Model";
              "org.opencontainers.image.description" = "1D Fresh-water Lake Model Fortran CLI Runtime";
              "org.opencontainers.image.url" = "https://github.com/taranarmo/flake-lake-model";
              "org.opencontainers.image.source" = "https://github.com/taranarmo/flake-lake-model";
              "org.opencontainers.image.vendor" = "FLake Community";
              "org.opencontainers.image.licenses" = "MIT";
            };
          };
          extraCommands = ''
            mkdir -p -m 1777 tmp
            mkdir -p -m 0777 workspace
            mkdir -p opt/flake
            cp -r ${./examples} opt/flake/examples
            chmod -R ugo+rX opt/flake/examples
          '';
        };

        dockerStream = pkgs.dockerTools.streamLayeredImage {
          name = "flake";
          tag = "latest";
          contents = [
            flakePackage
            pkgs.busybox
          ];
          config = {
            Entrypoint = [ "${flakePackage}/bin/flake" ];
            WorkingDir = "/workspace";
            Volumes = {
              "/workspace" = {};
            };
            Env = [
              "PATH=${flakePackage}/bin:${pkgs.busybox}/bin"
            ];
            Labels = {
              "org.opencontainers.image.title" = "FLake Lake Model";
              "org.opencontainers.image.description" = "1D Fresh-water Lake Model Fortran CLI Runtime";
              "org.opencontainers.image.url" = "https://github.com/taranarmo/flake-lake-model";
              "org.opencontainers.image.source" = "https://github.com/taranarmo/flake-lake-model";
              "org.opencontainers.image.vendor" = "FLake Community";
              "org.opencontainers.image.licenses" = "MIT";
            };
          };
          extraCommands = ''
            mkdir -p -m 1777 tmp
            mkdir -p -m 0777 workspace
            mkdir -p opt/flake
            cp -r ${./examples} opt/flake/examples
            chmod -R ugo+rX opt/flake/examples
          '';
        };
      in {
        packages.default = flakePackage;
        packages.model = flakePackage;
        packages.docker = dockerImage;
        packages.dockerStream = dockerStream;

        apps.default = {
          type = "app";
          program = "${flakePackage}/bin/flake";
        };
        apps.dockerStream = {
          type = "app";
          program = "${dockerStream}";
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
