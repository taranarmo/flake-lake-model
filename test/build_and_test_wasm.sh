#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT_DIR="$(cd "${SCRIPT_DIR}/.." && pwd)"
SRC_DIR="${ROOT_DIR}/src"
BUILD_DIR="${ROOT_DIR}/build_wasm"

echo "=== Building and Testing FLake with LFortran for WebAssembly ==="

command -v lfortran >/dev/null 2>&1 || { echo "Error: lfortran is not found in PATH"; exit 1; }
command -v llc >/dev/null 2>&1 || { echo "Error: llc (LLVM compiler) is not found in PATH"; exit 1; }
command -v wasm-ld >/dev/null 2>&1 || { echo "Error: wasm-ld is not found in PATH"; exit 1; }
command -v node >/dev/null 2>&1 || { echo "Error: node is not found in PATH"; exit 1; }

mkdir -p "${BUILD_DIR}"
rm -f "${BUILD_DIR}"/*.o "${BUILD_DIR}"/*.mod "${BUILD_DIR}"/*.ll "${BUILD_DIR}"/flake.wasm
cd "${BUILD_DIR}"

echo "Compiling Fortran 90 modules with lfortran..."
# NOTE: all modules are compiled with plain `lfortran -c` (emitting .mod files
# and native objects that are discarded); lfortran then emits the complete
# program - the interface and every used module's code and state - into the
# single flake_interface object. DO NOT link separate per-module objects:
# lfortran re-emits used modules' globals into each object, so multi-object
# linking would duplicate the physics state instead of sharing it.
for mod in data_parameters.f90 flake_derivedtypes.f90 flake_parameters.f90 \
           flake_configure.f90 flake_albedo_ref.f90 flake_paramoptic_ref.f90 \
           flake.f90 SfcFlx.f90; do
  lfortran -c "${SRC_DIR}/${mod}"
done

echo "Generating LLVM IR for flake_interface..."
lfortran --show-llvm -c "${SRC_DIR}/src_flake_interface_1D.f90" > flake.ll

echo "Compiling LLVM IR to WebAssembly object file..."
llc -march=wasm32 -filetype=obj flake.ll -o flake.o

echo "Linking WebAssembly binary..."
wasm-ld --no-entry --export-all --import-undefined flake.o -o flake.wasm

echo "Running WASM runtime verification test..."
node "${SCRIPT_DIR}/test_wasm.js" "${BUILD_DIR}/flake.wasm"

echo "=== LFortran WASM verification completed successfully! ==="
