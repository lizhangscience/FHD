PRO plot_cals_sub,freq_arr,gains_A,gains_B,filename=filename,phase=phase,real_vs_imaginary=real_vs_imaginary,$
    tile_A=tile_A,tile_B=tile_B,tile_use=tile_use,tile_exist=tile_exist,tile_names=tile_names,$
    obsname=obsname,plot_pos=plot_pos,cal_plot_charsize=cal_plot_charsize,cal_plot_symsize=cal_plot_symsize,cal_plot_resize=cal_plot_resize

cgPS_Open,filename,scale_factor=2,/quiet,/nomatch

IF Keyword_Set(gains_B) THEN n_pol=2 ELSE n_pol=1
n_tiles=N_Elements(tile_names)

width = plot_pos[1,0]-plot_pos[0,0]
height = abs(plot_pos[16,1]-plot_pos[0,1])

xtickv=[ceil(min(freq_arr)/10)*10,floor(max(freq_arr)/10)*10]
xtickname=strtrim(round(xtickv),2)
xrange=[min(freq_arr)-(max(freq_arr)-min(freq_arr))/8,max(freq_arr)+(max(freq_arr)-min(freq_arr))/8]
IF Keyword_Set(phase) THEN BEGIN
    ytickv=[-!pi,0,!pi]
    ytickname=['-!9p!X','0','!9p!X']
    yrange=[-1.5*!pi,1.5*!pi]
ENDIF ELSE BEGIN
    IF n_pol GT 1 THEN max_amp = mean(abs([gains_A,gains_B])) + 2*stddev(abs([gains_A,gains_B])) $
        ELSE max_amp = Mean(abs(gains_A)) + 2*stddev(abs(gains_A))
    yrange=[0,max_amp]
    ytickv=[0,max_amp/2,max_amp]
ENDELSE

gain_type=size(gains_A,/type)
FOR tile_i=0L,n_tiles-1 DO BEGIN
    tile_name=tile_names[tile_i]
;    rec=Floor(tile_name/10)
;    tile=tile_name mod 10
    
    IF tile_exist[tile_i] EQ 0  THEN BEGIN
      ; no tile found... must have been flagged in pre-processing
      axiscolor='grey'
      cgplot,1,title=strtrim(tile_name,2),XTICKFORMAT="(A1)",YTICKFORMAT="(A1)",position=plot_pos[tile_i,*],$
        /noerase,charsize=cal_plot_charsize,axiscolor=axiscolor
    ENDIF ELSE BEGIN
      CASE 1 OF
        Keyword_Set(phase): BEGIN
          gain_vals_A=phunwrap(atan(gains_A[*,tile_i],/phase)) 
          IF n_pol GT 1 THEN gain_vals_B=phunwrap(atan(gains_B[*,tile_i],/phase)) 
        END
        Keyword_Set(real_vs_imaginary): BEGIN
          n_pol=2
          gain_vals_A=Real_part(gains_A[*,tile_i])
          gain_vals_B=Real_part(gains_B[*,tile_i])
        END
        ELSE: BEGIN
          IF gain_type GE 6 THEN gain_vals_A=abs(gains_A[*,tile_i]) ELSE gain_vals_A=gains_A[*,tile_i]
          
          IF n_pol GT 1 THEN IF gain_type GE 6 THEN gain_vals_B=abs(gains_B[*,tile_i]) ELSE gain_vals_B=gains_B[*,tile_i]
        ENDELSE  
      ENDCASE
      IF tile_use[tile_i] EQ 0 THEN axiscolor='red' ELSE axiscolor='black'
      IF ~(tile_i mod 16) THEN BEGIN
        IF (tile_i gt (n_tiles-17)) THEN BEGIN
          ; both axes
          cgplot,freq_arr,gain_vals_A,color='blue',title=strtrim(tile_name,2),$
            xticks=1,xtickv=xtickv,xtickname=xtickname,yticks=2,ytickv=ytickv,position=plot_pos[tile_i,*],$
            yticklen=0.04,yrange=yrange,xrange=xrange,charsize=cal_plot_charsize,/noerase,axiscolor=axiscolor,psym=3,symsize=cal_plot_symsize
        ENDIF ELSE BEGIN
          ; just the y-axis
          cgplot,freq_arr,gain_vals_A,color='blue',title=strtrim(tile_name,2),$
            xticks=1,xtickv=xtickv,XTICKFORMAT="(A1)",yticks=2,ytickv=ytickv,position=plot_pos[tile_i,*],$
            yticklen=0.04,yrange=yrange,xrange=xrange,charsize=cal_plot_charsize,/noerase,axiscolor=axiscolor,psym=3,symsize=cal_plot_symsize
        ENDELSE
      ENDIF ELSE BEGIN
        IF (tile_i gt (n_tiles-17)) THEN BEGIN
          ; just x-axis
          cgplot,freq_arr,gain_vals_A,color='blue',title=strtrim(tile_name,2),$
            xticks=1,xtickv=xtickv,yticks=2,ytickv=ytickv,YTICKFORMAT="(A1)",position=plot_pos[tile_i,*],$
            yticklen=0.04,yrange=yrange,xrange=xrange,charsize=cal_plot_charsize,/noerase,axiscolor=axiscolor,psym=3,symsize=cal_plot_symsize
        ENDIF ELSE BEGIN
          ; No axes
          cgplot,freq_arr,gain_vals_A,color='blue',title=strtrim(tile_name,2),$
            xticks=1,xtickv=xtickv,XTICKFORMAT="(A1)",yticks=2,ytickv=ytickv,YTICKFORMAT="(A1)",position=plot_pos[tile_i,*],yrange=yrange,xrange=xrange,$
            yticklen=0.04,charsize=cal_plot_charsize,/noerase,axiscolor=axiscolor,psym=3,symsize=cal_plot_symsize
        ENDELSE
      ENDELSE
      IF n_pol GT 1 THEN cgoplot,freq_arr,gain_vals_B,color='red',psym=3,symsize=cal_plot_symsize
    ENDELSE
ENDFOR

cgtext,.4,max(plot_pos[*,3]+height/4),obsname,/normal
cgPS_Close,/png,Density=300,Resize=cal_plot_resize,/allow_transparent,/nomessage

END