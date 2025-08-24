# Nix Flake for FLake Lake Model

This project now includes a Nix flake for building and running the FLake lake model.

## Usage

### Build the package

```bash
nix build .#flake-lake-model
./result/bin/flake_model
```

### Run directly

```bash
nix run .#flake-lake-model
```

### Development environment

```bash
nix develop
```

This will drop you into a shell with `gfortran` available and provide instructions for manual compilation.

## Flake Structure

- `packages.default` and `packages.flake-lake-model`: The compiled FLake model executable
- `apps.default` and `apps.flake-lake-model`: Runnable app version of the model
- `devShells.default`: Development environment with gfortran

## Implementation Details

The flake correctly handles the Fortran module dependencies by compiling files in the proper order:
1. `data_parameters.f90`
2. `flake_configure.f90`
3. `flake_derivedtypes.f90`
4. `flake_parameters.f90`
5. `flake_paramoptic_ref.f90`
6. `flake_albedo_ref.f90`
7. `flake.f90`
8. `SfcFlx.f90`
9. `src_flake_interface_1D.f90`
10. `main.f90`

It also includes all the required `.incf` include files.