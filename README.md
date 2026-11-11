# FLake: Fresh-water Lake Model

FLake is a 1D thermodynamic bulk lake parameterization scheme designed for numerical weather prediction, climate models, and limnological applications. It simulates the evolving vertical temperature profile and energy budget of fresh-water lakes of varying depths.

An interactive browser-based runtime compiled to WebAssembly is available at [flake-lake-model-wasm](https://github.com/taranarmo/flake-lake-model-wasm) ([Live Simulator](https://taranarmo.github.io/flake-lake-model-wasm/)).

## Model Overview

FLake uses a two-layer representation of the lake water column:
- An upper mixed layer with uniform temperature.
- A stratified thermocline extending from the base of the mixed layer to the lake bottom, parameterised through the concept of self-similarity of the temperature-depth curve.
- Thermodynamic modules for ice and snow cover.
- A thermally active sediment layer module.

## Building

### Requirements
- Fortran 90 compiler (`gfortran` 9+)
- CMake 3.16+ (or GNU Make)

### With CMake
```bash
cmake -B build
cmake --build build
ctest --test-dir build --output-on-failure
```

### With GNU Make
```bash
make
make test
```

### With Nix
```bash
nix build
# or run an interactive shell
nix develop
```

## Running Simulations

The CLI binary accepts a Fortran namelist (`.nml`) file:

```bash
./build/flake examples/Heiligensee80-96/Heiligensee80-96.nml
```

Verification test cases from the IGB Berlin validation suite are included under `examples/`:
- `Heiligensee80-96` (shallow polymictic lake)
- `Mueggelsee80-96` (shallow lake with wind fetch)
- `Stechlin94-98` (deep dimictic lake)

## Docker Container Runtime

A reproducible, minimal OCI container image is provided for running simulations without needing local Fortran or CMake toolchains.

### Quick Start with Docker

Run a local simulation by mounting your working directory into `/workspace`:

```bash
docker run --rm -v $(pwd):/workspace ghcr.io/taranarmo/flake-lake-model:latest lake.nml
```

Run one of the built-in benchmark cases directly from the container's `/opt/flake/examples`:

```bash
docker run --rm ghcr.io/taranarmo/flake-lake-model:latest /opt/flake/examples/Heiligensee80-96/Heiligensee80-96.nml
```

Display CLI usage and options:

```bash
docker run --rm ghcr.io/taranarmo/flake-lake-model:latest --help
```

### Reproducible Build with Nix

The primary container image is built hermetically using Nix (`dockerTools.buildLayeredImage` / `streamLayeredImage`), providing fine-grained reproducible layers with zero non-deterministic timestamps:

```bash
# Build tarball and load into Docker daemon
make docker
# or: nix build .#docker && docker load < result

# Or stream layers directly into Docker without intermediate disk tarball:
make docker-stream
# or: nix run .#dockerStream | docker load

# Test container execution
make docker-test
```

### Build with Standard Dockerfile

For environments without Nix, a multi-stage Alpine-based `Dockerfile` is also included:

```bash
docker build -t flake:latest .
docker run --rm flake:latest /opt/flake/examples/Stechlin94-98/Stechlin94-98.nml
```

## Repository Structure

- `src/`: Core Fortran 90 modules and boundary flux parameterizations.
- `app/`: Standalone CLI driver executable.
- `examples/`: Validation namelists, meteorological forcing files, and reference outputs.

## License

MIT License. See [LICENSE](LICENSE) for details.
