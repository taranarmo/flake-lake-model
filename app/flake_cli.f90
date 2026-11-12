!==============================================================================
! FLake Standalone CLI Driver
! 
! Reads namelist parameters and meteorological forcing, advances the FLake
! 1D lake model, and writes simulated temperature, mixed-layer depth,
! ice cover, and surface flux diagnostics.
!==============================================================================

PROGRAM flake_cli
  USE data_parameters, ONLY: ireals, iintegers
  USE flake_derivedtypes
  USE flake_parameters, ONLY: tpl_T_f, tpl_rho_w_r
  USE flake_paramoptic_ref
  USE flake_albedo_ref
  USE flake_configure, ONLY: lflk_botsed_use
  USE flake, ONLY: flake_driver, flake_radflux, &
    T_snow_p_flk, T_snow_n_flk, T_ice_p_flk, T_ice_n_flk, &
    T_mnw_p_flk, T_mnw_n_flk, T_wML_p_flk, T_wML_n_flk, &
    T_bot_p_flk, T_bot_n_flk, T_B1_p_flk, T_B1_n_flk, &
    C_T_p_flk, C_T_n_flk, h_snow_p_flk, h_snow_n_flk, &
    h_ice_p_flk, h_ice_n_flk, h_ML_p_flk, h_ML_n_flk, &
    H_B1_p_flk, H_B1_n_flk, Q_snow_flk, Q_ice_flk, Q_w_flk, &
    Q_bot_flk, I_atm_flk, I_snow_flk, I_ice_flk, I_w_flk, &
    I_h_flk, I_bot_flk, I_intm_0_h_flk, I_intm_h_D_flk, &
    Q_star_flk, u_star_w_flk, w_star_sfc_flk, dMsnowdt_flk
  USE SfcFlx, ONLY: SfcFlx_lwradatm, SfcFlx_lwradwsfc, SfcFlx_momsenlat, &
                    SfcFlx_spechum, c_lwrad_emis

  IMPLICIT NONE

  INTERFACE
    SUBROUTINE flake_interface(dMsnowdt_in, I_atm_in, Q_atm_lw_in, height_u_in, height_tq_in, &
                               U_a_in, T_a_in, q_a_in, P_a_in, &
                               depth_w, fetch, depth_bs, T_bs, par_Coriolis, del_time, &
                               T_snow_in, T_ice_in, T_mnw_in, T_wML_in, T_bot_in, T_B1_in, &
                               C_T_in, h_snow_in, h_ice_in, h_ML_in, H_B1_in, T_sfc_p, &
                               albedo_water, albedo_ice, albedo_snow, &
                               opticpar_water, opticpar_ice, opticpar_snow, &
                               T_snow_out, T_ice_out, T_mnw_out, T_wML_out, T_bot_out, T_B1_out, &
                               C_T_out, h_snow_out, h_ice_out, h_ML_out, H_B1_out, T_sfc_n)
      USE data_parameters, ONLY: ireals
      USE flake_derivedtypes, ONLY: opticpar_medium
      REAL(ireals), INTENT(IN) :: dMsnowdt_in, I_atm_in, Q_atm_lw_in, height_u_in, height_tq_in, &
                                  U_a_in, T_a_in, q_a_in, P_a_in, &
                                  depth_w, fetch, depth_bs, T_bs, par_Coriolis, del_time, &
                                  T_snow_in, T_ice_in, T_mnw_in, T_wML_in, T_bot_in, T_B1_in, &
                                  C_T_in, h_snow_in, h_ice_in, h_ML_in, H_B1_in, T_sfc_p, &
                                  albedo_water, albedo_ice, albedo_snow
      TYPE(opticpar_medium), INTENT(INOUT) :: opticpar_water, opticpar_ice, opticpar_snow
      REAL(ireals), INTENT(OUT) :: T_snow_out, T_ice_out, T_mnw_out, T_wML_out, T_bot_out, T_B1_out, &
                                   C_T_out, h_snow_out, h_ice_out, h_ML_out, H_B1_out, T_sfc_n
    END SUBROUTINE flake_interface
  END INTERFACE

  ! Namelist parameters
  REAL(ireals) :: del_time_lk = 86400.0_ireals
  INTEGER :: time_step_number = 100
  INTEGER :: save_interval_n = 1
  REAL(ireals) :: T_wML_in = 4.0_ireals
  REAL(ireals) :: T_bot_in = 4.0_ireals
  REAL(ireals) :: h_ML_in = 3.0_ireals
  INTEGER :: yearlength = 365
  INTEGER :: niter_per_max = 1

  REAL(ireals) :: z_wind_m(1) = 10.0_ireals
  REAL(ireals) :: z_Taqa_m(1) = 2.0_ireals
  REAL(ireals) :: z_Tw_m(1) = 0.0_ireals
  CHARACTER(LEN=256) :: meteofile = 'meteofile.dat'
  CHARACTER(LEN=256) :: outputfile = 'flake.rslt'

  REAL(ireals) :: depth_w_lk = 5.0_ireals
  REAL(ireals) :: fetch_lk = 2000.0_ireals
  LOGICAL :: sediments_on = .TRUE.
  REAL(ireals) :: depth_bs_lk = 5.0_ireals
  REAL(ireals) :: T_bs_lk = 4.0_ireals
  REAL(ireals) :: latitude_lk = 52.0_ireals
  REAL(ireals) :: c_relax_c = 0.003_ireals

  INTEGER :: nband_optic = 1
  REAL(ireals) :: frac_optic = 1.0_ireals
  REAL(ireals) :: extincoef_optic = 1.0_ireals
  REAL(ireals) :: gamin = 0.0_ireals
  REAL(ireals) :: gamax = 0.0_ireals
  REAL(ireals) :: m1 = 0.0_ireals
  REAL(ireals) :: m2 = 0.0_ireals
  REAL(ireals) :: sigm = 0.0_ireals
  LOGICAL :: variablegamma = .FALSE.
  LOGICAL :: oldreplace = .FALSE.

  NAMELIST /SIMULATION_PARAMS/ del_time_lk, time_step_number, save_interval_n, &
                               T_wML_in, T_bot_in, h_ML_in, yearlength, niter_per_max
  NAMELIST /METEO/ z_wind_m, z_Taqa_m, z_Tw_m, meteofile, outputfile
  NAMELIST /LAKE_PARAMS/ depth_w_lk, fetch_lk, sediments_on, depth_bs_lk, &
                         T_bs_lk, latitude_lk, c_relax_c
  NAMELIST /TRANSPARENCY/ nband_optic, frac_optic, extincoef_optic, &
                          gamin, gamax, m1, m2, sigm, variablegamma, oldreplace

  ! State and diagnostic variables
  REAL(ireals) :: T_snow, T_ice, T_mnw, T_wML, T_bot, T_B1, C_T, h_snow, h_ice, h_ML, H_B1, T_sfc
  REAL(ireals) :: T_snow_o, T_ice_o, T_mnw_o, T_wML_o, T_bot_o, T_B1_o, C_T_o, h_snow_o, h_ice_o, h_ML_o, H_B1_o, T_sfc_o
  REAL(ireals) :: alb_w, alb_i, alb_s
  TYPE(opticpar_medium) :: opt_w, opt_i, opt_s
  REAL(ireals) :: par_coriolis
  REAL(ireals), PARAMETER :: pi = 3.14159265358979323846_ireals
  REAL(ireals), PARAMETER :: omega_earth = 7.292115e-5_ireals
  REAL(ireals), PARAMETER :: P_a = 101325.0_ireals

  ! Meteo step inputs
  INTEGER :: istep, istep_read, num_steps_done
  REAL(ireals) :: I_atm_in, T_a_c, e_a_hPa, U_a_in, cl_tot
  REAL(ireals) :: T_a_k, e_a_Pa, q_a_in, Q_lw_in, dMsnow_in
  REAL(ireals) :: sim_time_days
  REAL(ireals) :: ufr_a, ufr_w, Wconv, Qw, Q_se, Q_la, I_w_diag, Q_lwa, Q_lww, Qbot_diag
  REAL(ireals) :: Q_mom, Q_sens, Q_lat, Q_watvap, rho_air

  ! CLI arguments and IO
  CHARACTER(LEN=256) :: nml_filename, arg, nml_dir, resolved_meteofile, resolved_outputfile
  INTEGER :: num_args, ios, slash_pos
  LOGICAL :: file_exists

  ! Check CLI arguments
  num_args = COMMAND_ARGUMENT_COUNT()
  IF (num_args >= 1) THEN
    CALL GET_COMMAND_ARGUMENT(1, arg)
    IF (TRIM(arg) == '-h' .OR. TRIM(arg) == '--help') THEN
      PRINT '(A)', 'FLake: Fresh-water Lake Model (1D CLI Driver)'
      PRINT '(A)', 'Usage:'
      PRINT '(A)', '  flake [namelist_file.nml]'
      PRINT '(A)', ''
      PRINT '(A)', 'Namelists expected in configuration file:'
      PRINT '(A)', '  &SIMULATION_PARAMS (del_time_lk, time_step_number, save_interval_n, T_wML_in, T_bot_in, h_ML_in, yearlength, niter_per_max)'
      PRINT '(A)', '  &METEO             (z_wind_m, z_Taqa_m, z_Tw_m, meteofile, outputfile)'
      PRINT '(A)', '  &LAKE_PARAMS       (depth_w_lk, fetch_lk, sediments_on, depth_bs_lk, T_bs_lk, latitude_lk, c_relax_c)'
      PRINT '(A)', '  &TRANSPARENCY      (nband_optic, frac_optic, extincoef_optic, gamin, gamax, m1, m2, sigm, variablegamma, oldreplace)'
      PRINT '(A)', ''
      PRINT '(A)', 'Example:'
      PRINT '(A)', '  flake examples/Heiligensee80-96/Heiligensee80-96.nml'
      STOP
    END IF
    nml_filename = TRIM(arg)
  ELSE
    nml_filename = 'flake.nml'
  END IF

  INQUIRE(FILE=TRIM(nml_filename), EXIST=file_exists)
  IF (.NOT. file_exists) THEN
    WRITE(*, '(A, A)') 'Error: Namelist file not found: ', TRIM(nml_filename)
    WRITE(*, '(A)') 'Run with --help for usage instructions.'
    STOP 1
  END IF

  ! Extract directory prefix of namelist file if present
  nml_dir = ''
  slash_pos = INDEX(nml_filename, '/', BACK=.TRUE.)
  IF (slash_pos > 0) THEN
    nml_dir = nml_filename(1:slash_pos)
  END IF

  ! Open and read namelist
  OPEN(UNIT=10, FILE=TRIM(nml_filename), STATUS='OLD', ACTION='READ', IOSTAT=ios)
  IF (ios /= 0) THEN
    WRITE(*, '(A, A)') 'Error opening namelist file: ', TRIM(nml_filename)
    STOP 2
  END IF

  READ(10, NML=SIMULATION_PARAMS, IOSTAT=ios)
  IF (ios /= 0) THEN
    WRITE(*, '(A)') 'Warning: could not read &SIMULATION_PARAMS namelist, using defaults'
  END IF
  REWIND(10)

  READ(10, NML=METEO, IOSTAT=ios)
  IF (ios /= 0) THEN
    WRITE(*, '(A)') 'Warning: could not read &METEO namelist, using defaults'
  END IF
  REWIND(10)

  READ(10, NML=LAKE_PARAMS, IOSTAT=ios)
  IF (ios /= 0) THEN
    WRITE(*, '(A)') 'Warning: could not read &LAKE_PARAMS namelist, using defaults'
  END IF
  REWIND(10)

  READ(10, NML=TRANSPARENCY, IOSTAT=ios)
  IF (ios /= 0) THEN
    WRITE(*, '(A)') 'Warning: could not read &TRANSPARENCY namelist, using defaults'
  END IF
  CLOSE(10)

  ! Resolve paths for meteofile and outputfile
  resolved_meteofile = TRIM(meteofile)
  INQUIRE(FILE=TRIM(resolved_meteofile), EXIST=file_exists)
  IF (.NOT. file_exists .AND. LEN_TRIM(nml_dir) > 0) THEN
    resolved_meteofile = TRIM(nml_dir) // TRIM(meteofile)
    INQUIRE(FILE=TRIM(resolved_meteofile), EXIST=file_exists)
  END IF

  IF (.NOT. file_exists) THEN
    WRITE(*, '(A, A)') 'Error: Meteorological forcing file not found: ', TRIM(meteofile)
    STOP 3
  END IF

  resolved_outputfile = TRIM(outputfile)
  IF (LEN_TRIM(nml_dir) > 0 .AND. INDEX(resolved_outputfile, '/') == 0) THEN
    resolved_outputfile = TRIM(nml_dir) // TRIM(outputfile)
  END IF

  ! Validate simulation inputs
  IF (save_interval_n <= 0) THEN
    WRITE(*, '(A)') 'Warning: save_interval_n must be positive. Defaulting to 1.'
    save_interval_n = 1
  END IF
  IF (extincoef_optic <= 0.0_ireals) THEN
    WRITE(*, '(A)') 'Warning: extincoef_optic must be positive. Defaulting to 1.0.'
    extincoef_optic = 1.0_ireals
  END IF
  IF (nband_optic < 1 .OR. nband_optic > 10) THEN
    WRITE(*, '(A)') 'Warning: nband_optic must be between 1 and 10. Defaulting to 1.'
    nband_optic = 1
  END IF

  ! Coriolis parameter
  par_coriolis = 2.0_ireals * omega_earth * SIN(latitude_lk * pi / 180.0_ireals)

  ! Initialize lake variables
  T_sfc  = T_wML_in + tpl_T_f
  T_wML  = T_wML_in + tpl_T_f
  T_bot  = T_bot_in + tpl_T_f
  h_ML   = h_ML_in
  C_T    = 0.5_ireals
  T_mnw  = T_wML - (1.0_ireals - h_ML/depth_w_lk) * C_T * (T_wML - T_bot)
  h_ice  = 0.0_ireals
  h_snow = 0.0_ireals
  T_ice  = tpl_T_f
  T_snow = tpl_T_f

  lflk_botsed_use = sediments_on
  IF (sediments_on) THEN
    H_B1 = depth_bs_lk
    T_B1 = T_bs_lk + tpl_T_f
  ELSE
    H_B1 = 0.0_ireals
    T_B1 = tpl_T_f
  END IF

  opt_w = opticpar_water_ref
  opt_w%extincoef_optic(1) = extincoef_optic
  opt_i = opticpar_ice_opaque
  opt_s = opticpar_snow_opaque
  alb_w = albedo_water_ref
  alb_i = albedo_whiteice_ref
  alb_s = albedo_whiteice_ref

  ! Open meteo forcing file
  OPEN(UNIT=20, FILE=TRIM(resolved_meteofile), STATUS='OLD', ACTION='READ', IOSTAT=ios)
  IF (ios /= 0) THEN
    WRITE(*, '(A, A)') 'Error opening meteo file: ', TRIM(resolved_meteofile)
    STOP 4
  END IF

  ! Open output result file
  OPEN(UNIT=30, FILE=TRIM(resolved_outputfile), STATUS='REPLACE', ACTION='WRITE', IOSTAT=ios)
  IF (ios /= 0) THEN
    WRITE(*, '(A, A)') 'Error opening output file: ', TRIM(resolved_outputfile)
    STOP 5
  END IF

  ! Write file headers
  WRITE(30, '(A)') 'Results from FLAKE simulations.'
  WRITE(30, '(A)') ' No     time         Ts            Tm            Tb            ufr_a         ufr_w         Wconv         Qw            Q_se          Q_la          I_w           Q_lwa         Q_lww         h_ML          C_T           H_B1          T_B1         Qbot           H_ice        H_snow        T_ice         T_snow      Extinction_Coeff'

  ! Output initial state at t = 0
  WRITE(30, '(1X, I5, 23(1X, G13.5e4))') &
    0, 0.0_ireals, &
    T_sfc - tpl_T_f, T_wML - tpl_T_f, T_bot - tpl_T_f, &
    0.0_ireals, 0.0_ireals, 0.0_ireals, &
    0.0_ireals, 0.0_ireals, 0.0_ireals, &
    0.0_ireals, 0.0_ireals, 0.0_ireals, &
    h_ML, C_T, H_B1, T_B1 - tpl_T_f, &
    0.0_ireals, h_ice, h_snow, &
    0.0_ireals, 0.0_ireals, &
    opt_w%extincoef_optic(1)

  num_steps_done = 0

  ! Time stepping simulation loop
  DO istep = 1, time_step_number
    READ(20, *, IOSTAT=ios) istep_read, I_atm_in, T_a_c, e_a_hPa, U_a_in, cl_tot
    IF (ios /= 0) THEN
      WRITE(*, '(A, I6, A)') 'Notice: End of meteo data reached at step ', istep - 1, '.'
      EXIT
    END IF

    T_a_k   = T_a_c + tpl_T_f
    e_a_Pa  = e_a_hPa * 100.0_ireals
    q_a_in  = SfcFlx_spechum(e_a_Pa, P_a)
    Q_lw_in = -SfcFlx_lwradatm(T_a_k, e_a_Pa, cl_tot, cl_tot)
    dMsnow_in = 0.0_ireals

    CALL flake_interface(dMsnow_in, I_atm_in, Q_lw_in, z_wind_m(1), z_Taqa_m(1), &
                         U_a_in, T_a_k, q_a_in, P_a, &
                         depth_w_lk, fetch_lk, depth_bs_lk, T_bs_lk + tpl_T_f, par_coriolis, del_time_lk, &
                         T_snow, T_ice, T_mnw, T_wML, T_bot, T_B1, &
                         C_T, h_snow, h_ice, h_ML, H_B1, T_sfc, &
                         alb_w, alb_i, alb_s, opt_w, opt_i, opt_s, &
                         T_snow_o, T_ice_o, T_mnw_o, T_wML_o, T_bot_o, T_B1_o, &
                         C_T_o, h_snow_o, h_ice_o, h_ML_o, H_B1_o, T_sfc_o)

    ! Diagnostics
    CALL SfcFlx_momsenlat(z_wind_m(1), z_Taqa_m(1), fetch_lk, &
                          U_a_in, T_a_k, q_a_in, T_sfc, P_a, h_ice, &
                          Q_mom, Q_sens, Q_lat, Q_watvap)
    rho_air = P_a / (287.058_ireals * T_a_k)
    ufr_a   = SQRT(MAX(0.0_ireals, -Q_mom / rho_air))
    ufr_w   = u_star_w_flk
    Wconv   = w_star_sfc_flk
    Qw      = Q_w_flk
    Q_se    = Q_sens
    Q_la    = Q_lat
    I_w_diag = I_w_flk
    Q_lwa   = Q_lw_in
    Q_lww   = -SfcFlx_lwradwsfc(T_sfc)
    Qbot_diag = Q_bot_flk

    ! Update state for next step
    T_snow = T_snow_o
    T_ice  = T_ice_o
    T_mnw  = T_mnw_o
    T_wML  = T_wML_o
    T_bot  = T_bot_o
    T_B1   = T_B1_o
    C_T    = C_T_o
    h_snow = h_snow_o
    h_ice  = h_ice_o
    h_ML   = h_ML_o
    H_B1   = H_B1_o
    T_sfc  = T_sfc_o

    num_steps_done = num_steps_done + 1
    sim_time_days = REAL(istep, KIND=ireals) * del_time_lk / 86400.0_ireals

    IF (MOD(istep, save_interval_n) == 0) THEN
      WRITE(30, '(1X, I5, 23(1X, G13.5e4))') &
        istep, sim_time_days, &
        T_sfc - tpl_T_f, T_wML - tpl_T_f, T_bot - tpl_T_f, &
        ufr_a, ufr_w, Wconv, &
        Qw, Q_se, Q_la, &
        I_w_diag, Q_lwa, Q_lww, &
        h_ML, C_T, H_B1, T_B1 - tpl_T_f, &
        Qbot_diag, h_ice, h_snow, &
        T_ice - tpl_T_f, T_snow - tpl_T_f, &
        opt_w%extincoef_optic(1)
    END IF
  END DO

  CLOSE(20)
  CLOSE(30)

  WRITE(*, '(" End of calculation, number of time steps: ", F10.0)') REAL(num_steps_done, KIND=ireals)
  WRITE(*, '(" Results are written to:  ", A)') TRIM(resolved_outputfile)

END PROGRAM flake_cli
