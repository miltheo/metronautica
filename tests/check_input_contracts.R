library(metronautica)
local({
    fails<-function(expr)inherits(try(force(expr),silent=TRUE),'try-error')
    fs<-100;s<-(0:5999)/fs;t0<-as.POSIXct('2026-01-01',tz='UTC')
    meta<-list(acquisition=list(fs_derived_hz=fs,full_scale_range_g=16))
    x<-as_accel_tbl(t0+s,.1*sin(2*pi*2*s),.2*cos(2*pi*3*s),1+.15*sin(2*pi*s),meta)
    b<-list(data=x,meta=meta);cl<-list(full=x,stages=list(rpm_50=x),meta=meta)
    calls<-list(
        accel_metric_vm=list(epoch_s=5),accel_metric_enmo=list(epoch_s=5),
        accel_metric_mad=list(epoch_s=5),accel_metric_odba=list(epoch_s=5,fs_hz=fs),
        accel_metric_svmg=list(epoch_s=5,fs_hz=fs),
        accel_metric_svmbp=list(epoch_s=5,fs_hz=fs),
        accel_metric_rocam=list(epoch_s=5,fs_hz=fs),
        accel_metric_ai=list(epoch_s=5,fs_hz=fs,ai_noise_var=1e-6),
        accel_metric_z_angle=list(epoch_s=5),
        accel_metric_z_angle_change=list(epoch_s=5,fs_hz=fs),
        static_1hz_means=list(),static_axis_noise_metrics=list(),static_allan=list(),
        compute_ai_noise_var_from_static=list())
    for(n in names(calls)) {
        run<-function(input)do.call(getExportedValue('metronautica',n),c(list(input),calls[[n]]))
        expected<-run(x)
        for(input in list(b,cl))stopifnot(identical(run(input),expected))
    }
    stopifnot(identical(accel_meta(b),accel_meta(x)),
        identical(qc_accel_tbl(b),qc_accel_tbl(cl)),
        identical(filter_accel_tbl(b,10)$data$ax_g,filter_accel_tbl(x,10)$ax_g))
    malformed<-x;malformed$time<-as.numeric(malformed$time)
    stopifnot(fails(accel_metric_enmo(malformed,5)))
    malformed<-x;malformed$ax_g<-as.character(malformed$ax_g)
    stopifnot(fails(qc_accel_tbl(malformed)),fails(static_allan(list(data=malformed))))
    for(bad in list(0,-1,Inf,NA_real_,c(1,2),'1')) {
        stopifnot(fails(compute_ai_noise_var_from_static(x,window_s=bad)),
            fails(compute_ai_noise_var_from_static(x,fs_hz=bad)),
            fails(compute_ai_noise_var_from_static(x,use_middle_prop=bad)))
    }
    stopifnot(fails(compute_ai_noise_var_from_static(x,use_middle_prop=2)),
        fails(compute_ai_noise_var_from_static(x,window_s=.001)),
        fails(compute_ai_noise_var_from_static(x[1:5,])))
    empty<-x;empty$ax_g<-empty$ay_g<-empty$az_g<-NA_real_
    stopifnot(fails(compute_ai_noise_var_from_static(empty)))
    stopifnot(nrow(accel_metric_agcounts(x,5,fs))==nrow(x)/(5*fs),
        fails(compute_accel_summaries(x,measures='AG')),
        !grepl('agcounts',packageDescription('metronautica')$Suggests,fixed=TRUE))
    cat('Public raw-input table/parser/clip contracts and invalid stationary-noise arguments passed.\n')
})
