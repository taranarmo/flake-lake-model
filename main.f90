PROGRAM flake_driver_program

  USE data_parameters
  USE flake_derivedtypes
  USE flake_parameters
  USE flake_paramoptic_ref
  USE flake_albedo_ref
  USE flake
  USE SfcFlx

  INTERFACE
    SUBROUTINE flake_interface ( dMsnowdt_in, I_atm_in, Q_atm_lw_in, height_u_in, height_tq_in,     &
                                 U_a_in, T_a_in, q_a_in, P_a_in,                                    &
                                 depth_w, fetch, depth_bs, T_bs, par_Coriolis, del_time,            &
                                 T_snow_in,  T_ice_in,  T_mnw_in,  T_wML_in,  T_bot_in,  T_B1_in,   &
                                 C_T_in,  h_snow_in,  h_ice_in,  h_ML_in,  H_B1_in, T_sfc_p,        &
                                 albedo_water,   albedo_ice,   albedo_snow,                         &
                                 opticpar_water, opticpar_ice, opticpar_snow,                       &
                                 T_snow_out, T_ice_out, T_mnw_out, T_wML_out, T_bot_out, T_B1_out,  &
                                 C_T_out, h_snow_out, h_ice_out, h_ML_out, H_B1_out, T_sfc_n )
      USE data_parameters
      USE flake_derivedtypes
      USE flake_parameters
      USE flake_paramoptic_ref
      USE flake_albedo_ref
      USE flake
      USE SfcFlx

      REAL(KIND = ireals), INTENT(IN) :: dMsnowdt_in, I_atm_in, Q_atm_lw_in, height_u_in, height_tq_in
      REAL(KIND = ireals), INTENT(IN) :: U_a_in, T_a_in, q_a_in, P_a_in
      REAL(KIND = ireals), INTENT(IN) :: depth_w, fetch, depth_bs, T_bs, par_Coriolis, del_time
      REAL(KIND = ireals), INTENT(IN) :: T_snow_in, T_ice_in, T_mnw_in, T_wML_in, T_bot_in, T_B1_in
      REAL(KIND = ireals), INTENT(IN) :: C_T_in, h_snow_in, h_ice_in, h_ML_in, H_B1_in, T_sfc_p
      REAL(KIND = ireals), INTENT(INOUT) :: albedo_water, albedo_ice, albedo_snow
      TYPE(opticpar_medium), INTENT(INOUT) :: opticpar_water, opticpar_ice, opticpar_snow
      REAL(KIND = ireals), INTENT(OUT) :: T_snow_out, T_ice_out, T_mnw_out, T_wML_out, T_bot_out, T_B1_out
      REAL(KIND = ireals), INTENT(OUT) :: C_T_out, h_snow_out, h_ice_out, h_ML_out, H_B1_out, T_sfc_n
    END SUBROUTINE flake_interface
  END INTERFACE

  

  ! Declare variables for input to flake_interface
  REAL(KIND = ireals) :: dMsnowdt_in, I_atm_in, Q_atm_lw_in, height_u_in, height_tq_in
  REAL(KIND = ireals) :: U_a_in, T_a_in, q_a_in, P_a_in
  REAL(KIND = ireals) :: depth_w, fetch, depth_bs, T_bs, par_Coriolis, del_time
  REAL(KIND = ireals) :: T_snow_in, T_ice_in, T_mnw_in, T_wML_in, T_bot_in, T_B1_in
  REAL(KIND = ireals) :: C_T_in, h_snow_in, h_ice_in, h_ML_in, H_B1_in, T_sfc_p

  ! Declare variables for output from flake_interface
  REAL(KIND = ireals) :: T_snow_out, T_ice_out, T_mnw_out, T_wML_out, T_bot_out, T_B1_out
  REAL(KIND = ireals) :: C_T_out, h_snow_out, h_ice_out, h_ML_out, H_B1_out, T_sfc_n

  ! Declare INOUT variables
  TYPE(opticpar_medium) :: opticpar_water, opticpar_ice, opticpar_snow
  REAL(KIND = ireals) :: albedo_water, albedo_ice, albedo_snow

  ! Initialize some dummy input values (these would typically come from a data file or another model)
  dMsnowdt_in = 0.0_ireals
  I_atm_in = 200.0_ireals
  Q_atm_lw_in = 300.0_ireals
  height_u_in = 10.0_ireals
  height_tq_in = 2.0_ireals
  U_a_in = 5.0_ireals
  T_a_in = 283.15_ireals  ! 10 C
  q_a_in = 0.005_ireals
  P_a_in = 101325.0_ireals

  depth_w = 50.0_ireals
  fetch = 1000.0_ireals
  depth_bs = 1.0_ireals
  T_bs = 277.15_ireals  ! 4 C
  par_Coriolis = 1.0E-4_ireals
  del_time = 3600.0_ireals ! 1 hour

  T_snow_in = 273.15_ireals
  T_ice_in = 273.15_ireals
  T_mnw_in = 280.15_ireals
  T_wML_in = 280.15_ireals
  T_bot_in = 277.15_ireals
  T_B1_in = 277.15_ireals
  C_T_in = 0.5_ireals
  h_snow_in = 0.0_ireals
  h_ice_in = 0.0_ireals
  h_ML_in = 5.0_ireals
  H_B1_in = 0.1_ireals
  T_sfc_p = 280.15_ireals

  albedo_water = 0.05_ireals
  albedo_ice = 0.5_ireals
  albedo_snow = 0.8_ireals

  ! Call the FLake interface subroutine
  CALL flake_interface ( dMsnowdt_in, I_atm_in, Q_atm_lw_in, height_u_in, height_tq_in,     &
                         U_a_in, T_a_in, q_a_in, P_a_in,                                    &
                         depth_w, fetch, depth_bs, T_bs, par_Coriolis, del_time,            &
                         T_snow_in,  T_ice_in,  T_mnw_in,  T_wML_in,  T_bot_in,  T_B1_in,   &
                         C_T_in,  h_snow_in,  h_ice_in,  h_ML_in,  H_B1_in, T_sfc_p,        &
                         albedo_water,   albedo_ice,   albedo_snow,                         &
                         opticpar_water, opticpar_ice, opticpar_snow,                       &
                         T_snow_out, T_ice_out, T_mnw_out, T_wML_out, T_bot_out, T_B1_out,  &
                         C_T_out, h_snow_out, h_ice_out, h_ML_out, H_B1_out, T_sfc_n )

  ! Print some output (for demonstration)
  PRINT *, "FLake Model Output:"
  PRINT *, "Updated Surface Temperature (K): ", T_sfc_n
  PRINT *, "Updated Mixed Layer Depth (m): ", h_ML_out
  PRINT *, "Updated Mixed Layer Temperature (K): ", T_wML_out

END PROGRAM flake_driver_program
