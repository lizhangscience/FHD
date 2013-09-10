FUNCTION mwa_tile_beam_generate,antenna_gain_arr,antenna_beam_arr,obsaz=obsaz,obsza=obsza,$
    frequency=frequency,polarization=polarization,$
    psf_dim=psf_dim,psf_resolution=psf_resolution,kbinsize=kbinsize,$
    normalization=normalization,xvals=xvals,yvals=yvals,$
    dimension=dimension,elements=elements,za_arr=za_arr,az_arr=az_arr,delay_settings=delay_settings,_Extra=extra

compile_opt idl2,strictarrsubs  
;indices of antenna_gain_arr correspond to these antenna locations:
;         N
;    0  1  2  3
;    
;    4  5  6  7  
;W                E
;    8  9  10 11   
;    
;    12 13 14 15 
;         S
;polarization 0: x, 1: y
;angle offset is the rotation of the entire tile in current coordinates in DEGREES
; (this should be the rotation between E-W or N-S and Ra-Dec)
kbinsize_use=kbinsize;/psf_resolution

IF N_Elements(normalization) EQ 0 THEN normalization=1.
psf_dim=Float(psf_dim)
;psf_dim2=psf_dim*psf_resolution
psf_dim2=dimension
degpix_use=!RaDeg/(kbinsize_use*psf_dim2) 
IF N_Elements(xvals) EQ 0 THEN xvals=(meshgrid(psf_dim2,psf_dim2,1)-psf_dim2/2.)*degpix_use
IF N_Elements(yvals) EQ 0 THEN yvals=(meshgrid(psf_dim2,psf_dim2,2)-psf_dim2/2.)*degpix_use
IF (N_Elements(obsaz)EQ 0) OR (N_Elements(obsza) EQ 0) THEN BEGIN
    x1=reform(xvals[*,psf_dim2/2.]) & x1i=where(x1)
    y1=reform(yvals[psf_dim2/2.,*]) & y1i=where(y1)
    x0=interpol(x1i,x1[x1i],0.)
    y0=interpol(y1i,y1[y1i],0.)
    za=Interpolate(za_arr,x0,y0,cubic=-0.5)
    az=Interpolate(az_arr,x0,y0,cubic=-0.5)
ENDIF ELSE BEGIN
    za=obsza
    az=obsaz
ENDELSE
;za=za_arr[psf_dim2/2.,psf_dim2/2.]
;az=az_arr[psf_dim2/2.,psf_dim2/2.]

antenna_spacing=1.1 ;meters (design) ;1.071
antenna_length=29.125*2.54/100. ;meters (measured)
antenna_height=0.35 ;meters (rumor)

Kconv=(2.*!Pi)*(frequency/299792458.) ;wavenumber (radians/meter)
;Kconv=(frequency/299792458.) ;wavenumber (radians/meter)
wavelength=299792458./frequency

IF Keyword_Set(antenna_beam_arr) THEN IF Keyword_Set(*antenna_beam_arr[0]) THEN BEGIN
    tile_beam=fltarr(psf_dim2,psf_dim2)
    FOR i=0,15 DO tile_beam+=*antenna_beam_arr[i]*antenna_gain_arr[i]
    tile_beam*=normalization
    tile_beam=tile_beam
    RETURN,tile_beam
ENDIF
xc_arr0=Reform((meshgrid(4,4,1))*antenna_spacing,16)
xc_arr=xc_arr0-Mean(xc_arr0) ;dipole east position (meters)
yc_arr0=Reform(Reverse(meshgrid(4,4,2),2)*antenna_spacing,16)
yc_arr=yc_arr0-Mean(yc_arr0) ;dipole north position (meters)
zc_arr=Fltarr(16)

term_A=Tan(az*!DtoR)
term_B=za*!DtoR
xc=Sqrt((term_B^2.)/(1+term_A^2.))
yc=term_A*xc
za_arr_use=Reform(za_arr,(psf_dim2)^2.)
az_arr_use=Reform(az_arr,(psf_dim2)^2.)

;!!!THIS SHOULD REALLY BE READ IN FROM A FILE!!!
;beamformer phase setting (meters) 
IF not Ptr_valid(delay_settings) THEN BEGIN
    D0_d=xc_arr0*sin(za*!DtoR)*Sin(az*!DtoR)+yc_arr0*Sin(za*!DtoR)*Cos(az*!DtoR) 
    D0_d/=299792458.*4.35E-10 ;435 picoseconds is base delay length unit
    D0_d=Round(D0_d) ;round to nearest real delay setting
    D0_d*=299792458D*4.35E-10
ENDIF ELSE D0_d=*delay_settings*299792458.*4.35E-10
D0_d=Float(D0_d)

proj_east=Reform(xvals,(psf_dim2)^2.)
proj_north=Reform(yvals,(psf_dim2)^2.)
proj_z=Cos(za_arr_use*!DtoR)

;phase of each dipole for the source (relative to the beamformer settings)
D_d=(proj_east#xc_arr+proj_north#yc_arr+proj_z#zc_arr-replicate(1,(psf_dim2)^2.)#D0_d*!Radeg);/Kconv
D_d=Reform(D_d,psf_dim2,psf_dim2,16)

;groundplane=2.*Sin(Cos(za_arr_use*!DtoR)#(Kconv*(antenna_height+zc_arr))) ;looks correct
;groundplane=Reform(groundplane,psf_dim2,psf_dim2,16)

groundplane=2.*Sin(Cos(za_arr_use*!DtoR)*(Kconv*(antenna_height)))
groundplane=Reform(groundplane,psf_dim2,psf_dim2)

;fudge_factor=0.5
;groundplane=Max(groundplane)*(1-fudge_factor)+groundplane*fudge_factor

projection=1.

;leakage_xtoy=0.
;leakage_ytox=0.

ii=Complex(0,1)
;;IF polarization EQ 0 THEN pol=Cos(xvals*!DtoR-xc)^2. ELSE pol=Cos(yvals*!DtoR-yc)^2.
;IF polarization EQ 0 THEN pol=Cos(xvals*!DtoR-xc) ELSE pol=Cos(yvals*!DtoR-yc)
;;IF polarization EQ 0 THEN pol=(1.-((xvals*!DtoR-xc)^2.)/2.)>0. ELSE pol=(1.-((yvals*!DtoR-yc)^2.)/2.)>0.

;dipole_gain_arr=groundplane*projection*Exp(-ii*Kconv*D_d*!DtoR)
dipole_gain_arr=Exp(-ii*Kconv*D_d*!DtoR)

;dipole_gain_arr=groundplane*projection*Exp(-ii*D_d*!DtoR)
;horizon_test=where(abs(za_arr_use) GE 90.,n_horizon_test)
;horizon_mask=fltarr(psf_dim2,psf_dim2)+1
;IF n_horizon_test GT 0 THEN horizon_mask[horizon_test]=0    

;horizon_test=Region_grow(za_arr,psf_dim2*(1.+psf_dim2)/2.,thresh=[0,89.])
;horizon_mask=fltarr(psf_dim2,psf_dim2)
;horizon_mask[horizon_test]=1.

IF not Keyword_Set(antenna_beam_arr) THEN antenna_beam_arr=Ptrarr(16,/allocate)
FOR i=0,15 DO BEGIN
    *antenna_beam_arr[i]=dipole_gain_arr[*,*,i]*groundplane;*pol
ENDFOR

tile_beam=fltarr(psf_dim2,psf_dim2)
FOR i=0,15 DO tile_beam+=*antenna_beam_arr[i]*antenna_gain_arr[i]

tile_beam*=normalization;*horizon_mask;*uv_mask

;tile_beam=tile_beam>0.
RETURN,tile_beam

END