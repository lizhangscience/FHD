FUNCTION transfer_cal, obs, params, transfer_calibration, file_path_fhd=file_path_fhd,silent=silent,error=error,_Extra=extra
IF size(transfer_calibration,/type) EQ 7 THEN BEGIN
  cal_file_use=transfer_calibration
  IF file_test(cal_file_use,/directory) THEN BEGIN
    fhd_save_io,file_path_fhd=file_path_fhd,transfer=transfer_calibration,var='cal',path_use=cal_file_use2,_Extra=extra
    cal_file_use2+='.sav'
    IF file_test(cal_file_use2) THEN cal_file_use=cal_file_use2 ELSE BEGIN
      print,'File:'+cal_file_use2+' not found!'
      error=1
      RETURN,fhd_struct_init_cal(obs,params)
    ENDELSE
  ENDIF ELSE BEGIN
    IF file_test(cal_file_use) EQ 0 THEN BEGIN
      fhd_save_io,file_path_fhd=cal_file_use,var='cal',path_use=cal_file_use2,_Extra=extra
      cal_file_use2+='.sav'
      IF file_test(cal_file_use2) THEN cal_file_use=cal_file_use2 ELSE BEGIN
        print,'File:'+cal_file_use2+' not found!'
        error=1
        RETURN,fhd_struct_init_cal(obs,params)
      ENDELSE
    ENDIF
  ENDELSE
  print, "Transferring calibration from: " + cal_file_use
  CASE StrLowCase(Strmid(cal_file_use[0],3,/reverse)) OF
    '.sav':BEGIN
      cal=getvar_savefile(cal_file_use,'cal')
    END
    '.txt':BEGIN
      textfast,gain_arr,/read,file_path=cal_file_use
      gain_arr_ptr=Ptr_new(gain_arr)
      cal=fhd_struct_init_cal(obs,params,calibration_origin=cal_file_use,gain_arr_ptr=gain_arr_ptr,_Extra=extra)
    END
    '.npz':BEGIN
      gain_arr=read_numpy(cal_file_use)
      gain_arr_ptr=Ptr_new(gain_arr)
      cal=fhd_struct_init_cal(obs,params,calibration_origin=cal_file_use,gain_arr_ptr=gain_arr_ptr,_Extra=extra)
    END
    '.npy':BEGIN
      gain_arr=read_numpy(cal_file_use)
      gain_arr_ptr=Ptr_new(gain_arr)
      cal=fhd_struct_init_cal(obs,params,calibration_origin=cal_file_use,gain_arr_ptr=gain_arr_ptr,_Extra=extra)
    END
    'fits':BEGIN ;calfits format
      cal = calfits_read(cal_file_use,obs,params,silent=silent,_Extra=extra)
    END
    ELSE: BEGIN
      print,'Unknown file format: ',cal_file_use
      error=1
      RETURN,fhd_struct_init_cal(obs,params)
    ENDELSE
  ENDCASE
ENDIF ELSE BEGIN
    print, "Transferring existing cal structure for calibration."
    cal = pointer_copy(transfer_calibration)
ENDELSE

calculate_cal_stats, obs, cal
RETURN,cal
END
