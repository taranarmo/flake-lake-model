#!/usr/bin/env node

/**
 * Verification test for FLake WebAssembly build.
 * Validates module instantiation, export of flake_interface,
 * memory buffer allocation, and physics step execution.
 */

const fs = require('fs');
const path = require('path');

const wasmPath = process.argv[2] || path.join(__dirname, 'flake.wasm');

if (!fs.existsSync(wasmPath)) {
  console.error(`Error: WebAssembly binary not found at ${wasmPath}`);
  process.exit(1);
}

const wasmBytes = fs.readFileSync(wasmPath);

const imports = {
  env: {
    _lfortran_datan: Math.atan,
    _lfortran_dlog: Math.log,
    _lfortran_get_default_allocator: () => 0,
    exp: Math.exp,
    pow: Math.pow,
    _lcompilers_snprintf_alloc: () => 0,
    _lcompilers_runtime_error_exit: (code) => {
      throw new Error(`FLake WASM runtime error exit: ${code}`);
    },
    _lcompilers_runtime_error: (msg) => {
      throw new Error(`FLake WASM runtime error: ${msg}`);
    },
    exit: (code) => {
      throw new Error(`FLake WASM exit called with code: ${code}`);
    }
  }
};

WebAssembly.instantiate(wasmBytes, imports).then(({ instance }) => {
  const exp = instance.exports;

  if (typeof exp.flake_interface !== 'function') {
    console.error("FAILED: flake_interface is not exported from WASM module.");
    process.exit(1);
  }

  if (exp.__wasm_call_ctors) {
    exp.__wasm_call_ctors();
  }

  const memory = exp.memory;
  let mv = new DataView(memory.buffer);

  // Allocate 64-bit float slots in linear memory.
  // Start well above the module's static data: __heap_base (exported via
  // --export-all) marks the beginning of the free heap region. A fixed low
  // base such as 4096 can collide with the module's data segment, which
  // grows as more module state becomes stored (non-PARAMETER) variables.
  const heapBaseGlobal = exp.__heap_base;
  let ptr = (heapBaseGlobal && typeof heapBaseGlobal.value === "number")
    ? Math.ceil(heapBaseGlobal.value / 8) * 8
    : 0;

  function allocDouble(val = 0.0) {
    // Grow the memory if the allocation would exceed its bounds; growth
    // detaches the old buffer, so the view must be re-created.
    if (ptr + 8 > memory.buffer.byteLength) {
      memory.grow(1);
      mv = new DataView(memory.buffer);
    }
    const p = ptr;
    ptr += 8;
    mv.setFloat64(p, val, true);
    return p;
  }

  function allocOptic(extin = 1.0) {
    // Match wasm32 ABI layout for TYPE(opticpar_medium):
    // 4-byte integer nband_optic + 4-byte alignment padding +
    // 10 * 8-byte frac_optic + 10 * 8-byte extincoef_optic = 168 bytes.
    const size = 168;
    while (ptr + size > memory.buffer.byteLength) {
      memory.grow(1);
      mv = new DataView(memory.buffer);
    }
    const p = ptr;
    ptr += size;
    mv.setInt32(p, 1, true);
    mv.setFloat64(p + 8, 1.0, true);
    for (let i = 1; i < 10; i++) {
      mv.setFloat64(p + 8 + i * 8, 0.0, true);
    }
    mv.setFloat64(p + 88, extin, true);
    for (let i = 1; i < 10; i++) {
      mv.setFloat64(p + 88 + i * 8, 1e7, true);
    }
    return p;
  }

  const K = 273.15;

  // Atmospheric forcing
  const p_dMsnowdt_in = allocDouble(0.0);
  const p_I_atm_in    = allocDouble(150.0); // W/m2
  const p_Q_atm_lw_in = allocDouble(300.0); // W/m2
  const p_height_u_in = allocDouble(10.0);  // m
  const p_height_tq_in = allocDouble(2.0);  // m
  const p_U_a_in      = allocDouble(3.5);   // m/s
  const p_T_a_in      = allocDouble(15.0 + K); // 15 C
  const p_q_a_in      = allocDouble(0.007); // kg/kg
  const p_P_a_in      = allocDouble(101325.0); // Pa

  // Lake properties
  const p_depth_w     = allocDouble(10.0);   // 10 m depth
  const p_fetch       = allocDouble(2000.0); // 2 km fetch
  const p_depth_bs    = allocDouble(5.0);
  const p_T_bs        = allocDouble(4.0 + K);
  const p_par_Coriolis = allocDouble(1.1e-4);
  const p_del_time    = allocDouble(3600.0); // 1 hour timestep

  // Lake state input
  const p_T_snow_in   = allocDouble(K);
  const p_T_ice_in    = allocDouble(K);
  const p_T_mnw_in    = allocDouble(12.0 + K);
  const p_T_wML_in    = allocDouble(14.0 + K);
  const p_T_bot_in    = allocDouble(6.0 + K);
  const p_T_B1_in     = allocDouble(4.0 + K);
  const p_C_T_in      = allocDouble(0.5);
  const p_h_snow_in   = allocDouble(0.0);
  const p_h_ice_in    = allocDouble(0.0);
  const p_h_ML_in     = allocDouble(3.0);
  const p_H_B1_in     = allocDouble(5.0);
  const p_T_sfc_p     = allocDouble(14.0 + K);

  // Optical and albedo parameters
  const p_albedo_water = allocDouble(0.07);
  const p_albedo_ice   = allocDouble(0.60);
  const p_albedo_snow  = allocDouble(0.70);

  const p_opticpar_water = allocOptic(0.8);
  const p_opticpar_ice   = allocOptic(1e7);
  const p_opticpar_snow  = allocOptic(1e7);

  // Output pointers
  const p_T_snow_out = allocDouble();
  const p_T_ice_out  = allocDouble();
  const p_T_mnw_out  = allocDouble();
  const p_T_wML_out  = allocDouble();
  const p_T_bot_out  = allocDouble();
  const p_T_B1_out   = allocDouble();
  const p_C_T_out    = allocDouble();
  const p_h_snow_out = allocDouble();
  const p_h_ice_out  = allocDouble();
  const p_h_ML_out   = allocDouble();
  const p_H_B1_out   = allocDouble();
  const p_T_sfc_n    = allocDouble();

  // Execute one timestep
  exp.flake_interface(
    p_dMsnowdt_in, p_I_atm_in, p_Q_atm_lw_in, p_height_u_in, p_height_tq_in,
    p_U_a_in, p_T_a_in, p_q_a_in, p_P_a_in,
    p_depth_w, p_fetch, p_depth_bs, p_T_bs, p_par_Coriolis, p_del_time,
    p_T_snow_in, p_T_ice_in, p_T_mnw_in, p_T_wML_in, p_T_bot_in, p_T_B1_in,
    p_C_T_in, p_h_snow_in, p_h_ice_in, p_h_ML_in, p_H_B1_in, p_T_sfc_p,
    p_albedo_water, p_albedo_ice, p_albedo_snow,
    p_opticpar_water, p_opticpar_ice, p_opticpar_snow,
    p_T_snow_out, p_T_ice_out, p_T_mnw_out, p_T_wML_out, p_T_bot_out, p_T_B1_out,
    p_C_T_out, p_h_snow_out, p_h_ice_out, p_h_ML_out, p_H_B1_out, p_T_sfc_n
  );

  // The memory buffer may have been detached (and a new one allocated) if the
  // module grew its memory during the call - re-create the view before reads.
  mv = new DataView(memory.buffer);

  const T_sfc_n_val = mv.getFloat64(p_T_sfc_n, true) - K;
  const T_wML_val   = mv.getFloat64(p_T_wML_out, true) - K;
  const T_bot_val   = mv.getFloat64(p_T_bot_out, true) - K;
  const h_ML_val    = mv.getFloat64(p_h_ML_out, true);

  console.log("=== FLake WebAssembly Execution Test ===");
  console.log(`Surface Temp (Ts) : ${T_sfc_n_val.toFixed(3)} °C`);
  console.log(`Mixed Layer (Tm)  : ${T_wML_val.toFixed(3)} °C`);
  console.log(`Bottom Temp (Tb)  : ${T_bot_val.toFixed(3)} °C`);
  console.log(`Mixed Layer Depth : ${h_ML_val.toFixed(3)} m`);

  if (isNaN(T_sfc_n_val) || isNaN(T_wML_val) || isNaN(T_bot_val) || isNaN(h_ML_val)) {
    console.error("FAILED: NaN encountered in simulation outputs.");
    process.exit(1);
  }

  if (T_sfc_n_val < -20 || T_sfc_n_val > 45) {
    console.error(`FAILED: Surface temperature out of physical range: ${T_sfc_n_val}`);
    process.exit(1);
  }

  if (h_ML_val < 0 || h_ML_val > 10.0) {
    console.error(`FAILED: Mixed layer depth out of range: ${h_ML_val}`);
    process.exit(1);
  }

  console.log("PASS: FLake WebAssembly simulation verification succeeded!");
}).catch(err => {
  console.error("FAILED: Error running WebAssembly verification test:", err);
  process.exit(1);
});
