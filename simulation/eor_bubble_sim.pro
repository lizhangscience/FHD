FUNCTION eor_bubble_sim, obs, jones, select_radius=select_radius, bubble_fname=bubble_fname, beam_threshold=beam_threshold, allow_sidelobe_sources=allow_sidelobe_sources, dat=dat 

;Opening an HDF5 file and extract relevant data
if keyword_set(bubble_fname) THEN hdf5_fname = bubble_fname ELSE message, "Missing bubble file path"
if not keyword_set(beam_threshold) then beam_threshold = 0.05
if keyword_set(allow_sidelobe_sources) THEN beam_threshold = 0.01
if not keyword_set(select_radius) THEN  select_radius = 20     ; Degrees

dimension=obs.dimension
elements= obs.elements

f_id = H5F_OPEN(hdf5_fname)
dset_id_eor  = H5D_OPEN(f_id, '/spectral_info/spectrum')
dspace_id_eor = H5D_GET_SPACE(dset_id_eor)

freq_hpx = H5_GETDATA(hdf5_fname, '/spectral_info/freq')

dims = REVERSE(H5S_GET_SIMPLE_EXTENT_DIMS(dspace_id_eor))
nside=NPIX2NSIDE(dims[0])
nfreq_hpx = dims[1]

n_pol=obs.n_pol

; Identify the healpix pixels within select_radius of the primary beam
ang2vec,obs.obsdec,obs.obsra,cen_coords,/astro
Query_disc,nside,cen_coords,select_radius,inds_select,npix_sel,/deg
print, 'selection radius (degrees) ', select_radius
print, "Npix_selected: ", npix_sel

; Limit the range of frequencies in the uvf cube to the range of the obs
freq_arr = (*obs.baseline_info).freq
lim = minmax(freq_arr)
freq_inds = where((freq_hpx GT lim[0]) and (freq_hpx LT lim[1]) )
freq_hpx = freq_hpx[freq_inds]
nfreq_hpx = n_elements(freq_hpx)

;; Extract only these healpix indices from the file.
;H5S_SELECT_ELEMENTS, dspace_id_eor, hpx_inds, /RESET

print, "Reading HDF5 file with EoR Healpix Cube"
t0 = systime(/seconds)
if n_elements(dat) eq 0 then dat = H5D_READ(dset_id_eor, FILE_SPACE=dpsace_id_eor)
print, 'HDF5 reading time = ', systime(/seconds) - t0, ' seconds'

; Interpolate in frequency:
dat_interp = Fltarr(obs.n_freq,npix_sel)
t0=systime(/seconds)
for hpx_i=0,npix_sel-1 DO dat_interp[*,hpx_i] = Interpol(dat[freq_inds,inds_select[hpx_i]],freq_hpx,freq_arr, /spline)
print, 'Frequency interpolation complete: ', systime(/seconds) - t0
hpx_arr = Ptrarr(obs.n_freq)
for fi=0, obs.n_freq-1 DO hpx_arr[fi] = ptr_new(reform(dat_interp[fi,*]))


H5S_CLOSE, dspace_id_eor
H5D_CLOSE, dset_id_eor
H5F_CLOSE, f_id

model_uv_arr=Ptrarr(n_pol,obs.n_freq, /allocate)
t0 = systime(/seconds)
print, 'Healpix Interpolation'
model_stokes_arr = healpix_interpolate(hpx_arr,obs,nside=nside,hpx_inds=inds_select,/from_kelvin)
print, 'Hpx_interpolate timing: ', systime(/seconds) - t0

FOR fi=0, obs.n_freq-1 do begin    ; 30 seconds for 203 channels
   model_tmp=Ptrarr(n_pol,/allocate)
   *model_tmp[0] = *model_stokes_arr[fi]
   FOR pol_i=1,n_pol-1 DO *model_tmp[pol_i]=Fltarr(obs.dimension,obs.elements)
   model_arr = stokes_cnv(model_tmp, jones, /inverse)
   Ptr_free, model_tmp

   FOR pol_i=0,n_pol-1 DO BEGIN
       model_uv=fft_shift(FFT(fft_shift(*model_arr[pol_i]),/inverse))
       *model_uv_arr[pol_i,fi]=model_uv
   ENDFOR
   Ptr_free,model_arr

ENDFOR

return, model_uv_arr

END
