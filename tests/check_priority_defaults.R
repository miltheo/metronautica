library(metronautica)
local({
    fails<-function(expr)inherits(try(force(expr),silent=TRUE),'try-error')
    t0<-as.POSIXct('2026-01-01',tz='UTC');fs<-20;s<-(0:2399)/fs
    x<-as_accel_tbl(t0+s,.1*sin(2*pi*2*s),.2*cos(2*pi*3*s),1+.15*sin(2*pi*s),
        list(acquisition=list(fs_derived_hz=fs,full_scale_range_g=16)))
    stopifnot(fails(static_clip(x,t0)),fails(static_metrology_from_tbl(x,start_utc=t0)),
        fails(clip_dynamic_stages(x,t0)))
    selected<-static_clip(x,t0,1/30)
    coverage<-accel_meta(selected)$processing$static_window
    stopifnot(coverage$requested_boundaries_covered,coverage$n_samples==2400,
        coverage$requested_duration_h==1/30,!coverage$internal_continuity_checked)
    warned<-FALSE
    short<-withCallingHandlers(static_clip(x,t0,1),warning=function(w){
        warned<<-TRUE;invokeRestart('muffleWarning')})
    stopifnot(warned,!accel_meta(short)$processing$static_window$requested_boundaries_covered,
        identical(selected$ax_g,x$ax_g))
    cl<-clip_dynamic_stages(x,t0,n_stages=2,stage_min=.5,buffer_min=.25,
        rpm_start=50,rpm_step=50,trim_start_min=.1,trim_end_min=.1)
    stopifnot(identical(cl$schedule$rpm,c(50,100)),all(vapply(cl$stages,nrow,integer(1))==360))
    stopifnot(fails(accel_metric_svmbp(x,5,20)),
        fails(compute_accel_summaries(x,measures='SVMBP',quiet=TRUE)))
    clipped<-compute_accel_summaries(x,measures='SVMBP',svmbp_nyquist_action='clip',quiet=TRUE)
    bp<-clipped$settings$bandpass$SVMBP
    stopifnot(identical(bp$requested_cutoffs_hz,c(.2,15)),
        identical(bp$applied_cutoffs_hz,c(.2,9.9)),bp$nyquist_action=='clip')
    direct<-accel_metric_svmbp(x,5,20,nyquist_action='clip',quiet=TRUE)
    stopifnot(identical(attr(direct,'settings')$applied_cutoffs_hz,c(.2,9.9)))
    bundle<-function(z)list(full=z,stages=list(rpm_50=z),meta=accel_meta(z))
    run<-function(a,b,... )dynamic_metrology_report(bundle(a),bundle(b),
        compute_entropy=FALSE,add_plot=FALSE,inspect_alignment=FALSE,progress=FALSE,...)
    no_range<-x;attr(no_range,'meta')<-NULL
    stopifnot(fails(run(no_range,x)))
    for(bad in list(0,-1,NA_real_,Inf,c(8,16),'16')) {
        stopifnot(fails(run(x,x,test_axis_fsr_g=bad)),
            fails(run(x,x,ref_axis_fsr_g=bad)),fails(m_dynamic_response(x,x,bad)))
    }
    dyn<-run(x,no_range)
    stopifnot(dyn$meta$range_source$test=='metadata',
        dyn$meta$range_source$reference=='unavailable',is.null(dyn$meta$comparison_plot_ylim),
        dyn$meta$pairing=='evenly_spaced_sample_index')
    values<-compute_accel_summaries(x,measures=c('VM','ENMO','MAD','AI'),
        ai_noise_var=1e-6,vm_unit='g',enmo_mg=FALSE,quiet=TRUE)
    stopifnot(values$settings$metric_units[['VM']]=='g',
        values$settings$metric_units[['ENMO']]=='g',values$settings$metric_units[['MAD']]=='mg')
    if(requireNamespace('plotly',quietly=TRUE)) {
        axis_title<-function(p) {
            value<-p$x$layout$yaxis$title
            if(is.list(value))value$text else value
        }
        a<-plotly::plotly_build(plot_processed_metric(values,'VM'))
        b<-plotly::plotly_build(plot_processed_metric(values,'MAD'))
        stopifnot(axis_title(a)=='VM (g)',axis_title(b)=='MAD (mg)',
            fails(plot_processed_metric(values$data_wide,'VM')))
        explicit<-plotly::plotly_build(plot_processed_metric(values$data_wide,'VM',unit='g'))
        stopifnot(axis_title(explicit)=='VM (g)')
    }
    cat('Explicit schedules/durations, static coverage, strict Nyquist/range and plot-unit checks passed.\n')
})
