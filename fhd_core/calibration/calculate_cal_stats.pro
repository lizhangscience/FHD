PRO calculate_cal_stats, obs, cal

  ;Statistics for metadata reporting
  nc_pol=cal.n_pol
  cal_gain_avg=Fltarr(nc_pol)
  cal_res_avg=Fltarr(nc_pol)
  cal_res_restrict=Fltarr(nc_pol)
  cal_res_stddev=Fltarr(nc_pol)
  FOR pol_i=0,nc_pol-1 DO BEGIN
    tile_use_i=where((*obs.baseline_info).tile_use,n_tile_use)
    freq_use_i=where((*obs.baseline_info).freq_use,n_freq_use)
    IF n_tile_use EQ 0 OR n_freq_use EQ 0 THEN CONTINUE
    gain_ref=extract_subarray(*cal.gain[pol_i],freq_use_i,tile_use_i)
    gain_res=extract_subarray(*cal_res.gain[pol_i],freq_use_i,tile_use_i)
    cal_gain_avg[pol_i]=Mean(Abs(gain_ref))
    cal_res_avg[pol_i]=Mean(Abs(gain_res))
    resistant_mean,Abs(gain_res),2,res_mean
    cal_res_restrict[pol_i]=res_mean
    cal_res_stddev[pol_i]=Stddev(Abs(gain_res))
  ENDFOR
  cal.mean_gain=cal_gain_avg
  cal.mean_gain_residual=cal_res_avg
  cal.mean_gain_restrict=cal_res_restrict
  cal.stddev_gain_residual=cal_res_stddev
