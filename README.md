# FLake Lake Model

This repository contains the source code for the FLake (Freshwater Lake) model, a one-dimensional lake model designed for use in coupled climate and weather prediction systems.

## Source

The original source code was downloaded from the official FLake website: http://flake.igb-berlin.de/site/download

## License

This project is distributed under the MIT License, as stated on the official FLake website.

## Build Instructions

The FLake model is implemented in Fortran. To compile the source code, you will need a Fortran compiler (e.g., `gfortran`).

For detailed build and usage instructions, please refer to the official documentation: `FLake_Documentation_Full.pdf`.

### Nix Environment

If you are using Nix, you can enter a shell with `gfortran` available by running:

```bash
nix-shell -p gfortran
```

### Compilation Steps

Since the FLake model is a library, a simple driver program (`main.f90`) has been added to demonstrate its usage and create an executable. The compilation process involves two steps:

1.  **Compile all Fortran source files into object files:**

    ```bash
    gfortran -c data_parameters.f90 flake_derivedtypes.f90 flake_parameters.f90 flake_paramoptic_ref.f90 flake_albedo_ref.f90 flake.f90 SfcFlx.f90 src_flake_interface_1D.f90 main.f90 flake_buoypar.incf flake_driver.incf flake_radflux.incf flake_snowdensity.incf flake_snowheatconduct.incf SfcFlx_lwradatm.incf SfcFlx_lwradwsfc.incf SfcFlx_momsenlat.incf SfcFlx_rhoair.incf SfcFlx_roughness.incf SfcFlx_satwvpres.incf SfcFlx_spechum.incf SfcFlx_wvpreswetbulb.incf
    ```

2.  **Link all object files into a single executable:**

    ```bash
    gfortran -o flake_model *.o
    ```

After successful compilation, you can run the executable:

```bash
./flake_model
```

Please consult the `FLake_Documentation_Full.pdf` for more precise compilation steps and any required libraries or flags, especially for more complex use cases or integration into other systems.