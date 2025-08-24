{
  description = "FLake (Freshwater Lake) model - a one-dimensional lake model";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    flake-utils.url = "github:numtide/flake-utils";
  };

  outputs = { self, nixpkgs, flake-utils }:
    flake-utils.lib.eachDefaultSystem (system:
      let
        pkgs = nixpkgs.legacyPackages.${system};
        
        # Define the compilation order for the FLake model
        # The order is important due to Fortran module dependencies
        flakeSources = [
          "data_parameters.f90"
          "flake_configure.f90"
          "flake_derivedtypes.f90"
          "flake_parameters.f90"
          "flake_paramoptic_ref.f90"
          "flake_albedo_ref.f90"
          "flake.f90"
          "SfcFlx.f90"
          "src_flake_interface_1D.f90"
          "main.f90"
        ];
        
        # Define the include files for the FLake model
        flakeIncludes = [
          "flake_buoypar.incf"
          "flake_driver.incf"
          "flake_radflux.incf"
          "flake_snowdensity.incf"
          "flake_snowheatconduct.incf"
          "SfcFlx_lwradatm.incf"
          "SfcFlx_lwradwsfc.incf"
          "SfcFlx_momsenlat.incf"
          "SfcFlx_rhoair.incf"
          "SfcFlx_roughness.incf"
          "SfcFlx_satwvpres.incf"
          "SfcFlx_spechum.incf"
          "SfcFlx_wvpreswetbulb.incf"
        ];
        
        # Create the FLake derivation
        flake = pkgs.stdenv.mkDerivation {
          pname = "flake-lake-model";
          version = "1.0";
          
          src = ./.;
          
          nativeBuildInputs = [ pkgs.gfortran ];
          
          buildPhase = ''
            # Compile all Fortran source files in the correct order
            for file in ${builtins.toString flakeSources}; do
              echo "Compiling $file"
              gfortran -c "$file" || exit 1
            done
            
            # Link all object files into a single executable
            gfortran -o flake_model *.o
          '';
          
          installPhase = ''
            mkdir -p $out/bin
            cp flake_model $out/bin/
          '';
        };
      in
      {
        packages = {
          default = flake;
          flake-lake-model = flake;
        };
        
        apps = {
          default = {
            type = "app";
            program = "${flake}/bin/flake_model";
          };
          
          flake-lake-model = {
            type = "app";
            program = "${flake}/bin/flake_model";
          };
        };
        
        devShells.default = pkgs.mkShell {
          buildInputs = [ pkgs.gfortran ];
          
          shellHook = ''
            echo "FLake Lake Model development environment"
            echo "Fortran compiler available: gfortran"
            echo "To compile manually, follow this order:"
            echo "  gfortran -c ${builtins.toString flakeSources}"
            echo "  gfortran -o flake_model *.o"
          '';
        };
      }
    );
}