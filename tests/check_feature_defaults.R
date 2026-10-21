library(metronautica)
local({
    fails<-function(expr) inherits(try(force(expr),silent=TRUE),'try-error')
    fs<-100; s<-(0:11999)/fs
    plain<-tibble::tibble(time=as.POSIXct('2026-01-01',tz='UTC')+s,
        ax_g=.1*sin(2*pi*2*s),ay_g=.2*cos(2*pi*2*s),az_g=1+.15*sin(2*pi*3*s))
    x<-as_accel_tbl(plain$time,plain$ax_g,plain$ay_g,plain$az_g,
        list(acquisition=list(fs_derived_hz=fs,full_scale_range_g=16)))
    no_range<-compute_accel_summaries(plain,quiet=TRUE)
    stopifnot(is.na(no_range$settings$dynamic_range_g),
        no_range$settings$dynamic_range_source=='unavailable',
        is.null(no_range$settings$ai),is.null(no_range$settings$mims))
    stopifnot(fails(compute_accel_summaries(plain,measures='MIMS',quiet=TRUE)),
        fails(compute_accel_summaries(plain,measures='AI',quiet=TRUE)))
    for(bad in list(0,-1,NA_real_,Inf,c(8,16),'16')) {
        stopifnot(fails(compute_accel_summaries(x,dynamic_range_g=bad,quiet=TRUE)))
    }
    for(bad in list(-1,NA_real_,Inf,c(0,1),'0')) {
        stopifnot(fails(accel_metric_ai(x,5,fs,ai_noise_var=bad)))
    }
    ai<-compute_accel_summaries(plain,measures='AI',ai_noise_var=1e-6,quiet=TRUE)
    stopifnot(ai$settings$ai$noise_var_g2==1e-6,
        ai$settings$ai$noise_source=='supplied',ai$settings$ai$scale=='absolute',
        ai$settings$ai$epoch_summary=='sum',ai$settings$ai$base_window_s==1)
    z<-accel_metric_ai(plain,5,fs,ai_noise_var=0)
    stopifnot(attr(z,'settings')$noise_source=='supplied',attr(z,'ai_noise_var_used')==0)
    for(mode in c('window_start','quiet_segments')) {
        stationary<-plain;stationary$ax_g<-stationary$ay_g<-0;stationary$az_g<-1
        est<-compute_accel_summaries(if(mode=='quiet_segments')stationary else plain,
            measures='AI',ai_noise_mode=mode,quiet=TRUE)
        stopifnot(est$settings$ai$noise_source==mode,is.finite(est$settings$ai$noise_var_g2))
    }
    stopifnot(fails(accel_metric_ai(plain,5,fs,ai_noise_mode='quiet_segments')),
        fails(accel_metric_ai(plain[1:50,],5,fs,ai_noise_mode='window_start')))
    short<-accel_metric_ai(plain[1:2000,],5,fs,ai_noise_mode='window_start')
    stopifnot(attr(short,'settings')$noise_window_requested_s==30,
        attr(short,'settings')$noise_window_s==20)
    invalid<-plain;invalid$ax_g<-invalid$ay_g<-invalid$az_g<-NA_real_
    stopifnot(fails(accel_metric_ai(invalid,5,fs,ai_noise_mode='window_start')))
    if(requireNamespace('MIMSunit',quietly=TRUE)) {
        default<-compute_accel_summaries(x,measures='MIMS',quiet=TRUE)
        explicit<-compute_accel_summaries(x,measures='MIMS',dynamic_range_g=16,
            mims_cutoffs=c(.2,5),quiet=TRUE)
        override<-compute_accel_summaries(x,measures='MIMS',dynamic_range_g=8,quiet=TRUE)
        stopifnot(identical(default$data_long,explicit$data_long),
            identical(default$settings$mims$cutoffs_hz,c(.2,5)),
            default$settings$mims$range_source=='metadata',
            explicit$settings$mims$range_source=='argument',
            identical(override$settings$mims$dynamic_range_limits_g,c(-4,4)))
        direct<-accel_metric_mims(plain,5,16)
        stopifnot(identical(attr(direct,'settings')$cutoffs_hz,c(.2,5)),
            nzchar(attr(direct,'settings')$implementation_version))
    }
    cat('Feature default, failure, override and resolved-settings checks passed.\n')
})
