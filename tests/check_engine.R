# Independent known-signal checks, runnable after R CMD INSTALL.
# These verify arithmetic and software behaviour; they are not human validation.
library(metronautica)
e <- asNamespace("metronautica")
checks <- list()
check <- function(name, ok) {
    checks[[length(checks)+1L]] <<- data.frame(check=name, passed=isTRUE(ok))
    if (!isTRUE(ok)) stop("FAILED: ",name)
}
same <- function(a,b,tol=1e-9) {
    if(is.numeric(a) && is.numeric(b)) { a<-as.numeric(a); b<-as.numeric(b) }
    isTRUE(all.equal(a,b,tolerance=tol,check.attributes=FALSE))
}
fs <- 100; n <- 12000L; seconds <- (0:(n-1L))/fs
t0 <- as.POSIXct("2026-01-01 00:00:00",tz="UTC")
meta <- list(acquisition=list(fs_nominal_hz=fs,fs_derived_hz=fs,full_scale_range_g=16),
             provenance=list(source="synthetic; no participant data"))
x <- as_accel_tbl(t0+seconds,0.2+0.1*sin(2*pi*2*seconds),
                  0.3*cos(2*pi*2*seconds),1+0.2*sin(2*pi*3*seconds),meta)
check("common format and units", inherits(x,"accel_tbl") &&
      identical(names(x),c("time","ax_g","ay_g","az_g")))
check("metadata preserved",identical(accel_meta(x)$provenance,meta$provenance))
before <- x; q <- qc_accel_tbl(x)
check("integrity diagnostics do not mutate the signal",identical(x,before))
check("sample count and finite denominator",q$n_samples==n && q$finite_axis_n==3*n)
check("timestamp sampling interval",abs(q$median_dt_ms-10)<1e-3)
y <- clip_bundle(x,start_time=t0,duration_s=10)
check("generic clip includes both endpoints",nrow(y)==1001L)
check("clip invalidates inherited whole-recording QC",is.null(accel_meta(y)$processing$qc))
check("clip leaves input unchanged",identical(x,before))
check("static clip has exclusive endpoint",nrow(e$static_clip(x,t0,10/3600))==1000L)
check("invalid clip fails",inherits(try(clip_bundle(x,t0,end_time=t0-1),silent=TRUE),"try-error"))
st <- static_metrology_from_tbl(x,start_utc=t0,duration_h=1/30,progress=FALSE)
check("public static assessment returns one summary",nrow(st$summary)==1L && nrow(st$clipped_data)==n)
check("public static assessment preserves acquisition provenance",identical(st$meta$provenance,meta$provenance))
cl <- clip_dynamic_stages(x,t0,n_stages=1,stage_min=1,buffer_min=0,rpm_start=50,rpm_step=50,
                           trim_start_min=0,trim_end_min=0)
check("public dynamic clipping selects expected stage",length(cl$stages)==1L && nrow(cl$stages[[1]])==6000L)

# An affine amplitude transformation supplies known slope/intercept. A small
# deterministic residual also exercises the full-range error denominators.
ref_vm <- 1.5+0.3*sin(2*pi*2*seconds)
test_vm <- 0.1+1.1*ref_vm+0.005*cos(2*pi*7*seconds)
ref <- as_accel_tbl(t0+seconds,rep(0,n),rep(0,n),ref_vm,meta)
test <- as_accel_tbl(t0+seconds,rep(0,n),rep(0,n),test_vm,meta)
bundle <- function(z) list(stages=list(stage_50=z),meta=accel_meta(z))
out <- dynamic_metrology_report(bundle(test),bundle(ref),test_axis_fsr_g=16,
       ref_axis_fsr_g=16,compute_entropy=FALSE,add_plot=FALSE,
       progress=FALSE,inspect_alignment=FALSE)
fit <- stats::lm(test_vm~ref_vm); residual <- test_vm-stats::predict(fit)
check("dynamic response slope",same(out$stages$response_slope,unname(coef(fit)[2])))
check("dynamic response intercept",same(out$stages$response_intercept,unname(coef(fit)[1])))
check("scale factor error is slope minus one",same(out$stages$scale_factor_error,unname(coef(fit)[2])-1))
check("signed mean VM bias",same(out$stages$vm_bias_vs_reference,mean(test_vm-ref_vm)))
check("stage linearity full-span denominator",same(out$stages$linearity_error_vs_reference,
      100*max(abs(residual))/(sqrt(3)*16)))
check("composite half-span denominator",same(out$overall$composite_error,
      100*max(abs(residual))/(sqrt(3)*16/2)))
check("epoch repeatability uses five-second means",same(out$stages$repeatability_error_cv,
      sd(tapply(test_vm,floor(seconds/5),mean))/mean(tapply(test_vm,floor(seconds/5),mean))))
check("spectral diagnostic recovers known frequency",abs(out$stages$dominant_frequency-2)<0.01)

noise <- e$static_axis_noise_metrics(x)
check("static raw sample SD",same(noise$x_sd_g,sd(x$ax_g)))
fit_noise <- lm(x$ax_g~seconds)
check("detrended residual SD uses n minus two",same(noise$x_detrended_sd_g,stats::sigma(fit_noise)))
check("near-zero CV guard",is.na(e$static_cv_percent(.01,0)))
d1 <- tibble::tibble(elapsed_h=(0:600)/3600, vm_mean=1.01+.002*(0:600)/3600,
                     ax_mean=0.01+.002*(0:600)/3600,ay_mean=0,az_mean=1)
check("static drift in g per hour",same(e$static_drift(d1)$vm_drift_g_per_h,.002))
check("first-window VM offset",same(e$static_offset_vm_5min(d1),mean(d1$vm_mean[0:600<=300])-1))
av <- e$allan_nonoverlap(1:20,fs_hz=1,tau_s=2)
cluster <- colMeans(matrix(1:20,nrow=2))
check("non-overlapping Allan deviation",same(av$adev,sqrt(mean(diff(cluster)^2)/2)))

# These independent formulas exercise epochs, clipping of negative ENMO and mg.
z <- compute_accel_summaries(x,measures=c("VM","ENMO","MAD"),epoch_s=5,quiet=TRUE)
vm <- sqrt(x$ax_g^2+x$ay_g^2+x$az_g^2)
bin <- floor(seconds/5)
check("VM epoch arithmetic",same(z$data_wide$VM,tapply(vm,bin,mean)))
check("ENMO sample rectification then epoch mean",same(z$data_wide$ENMO,1000*tapply(pmax(vm-1,0),bin,mean)))
check("MAD epoch mean amplitude deviation",same(z$data_wide$MAD,
      1000*tapply(vm,bin,function(a)mean(abs(a-mean(a))))))
filtered <- filter_accel_tbl(x,cutoff=10)
expected <- signal::filtfilt(signal::butter(4,2*10/((sqrt(2)-1)^(0.5/4))/fs),x$ax_g)
check("forward-backward filter matches specified implementation",same(filtered$ax_g,expected,1e-12))
check("filter preserves source provenance",identical(accel_meta(filtered)$provenance,meta$provenance))
check("filter invalidates inherited QC",is.null(accel_meta(filtered)$processing$qc))
check("invalid Nyquist cutoff fails",inherits(try(filter_accel_tbl(x,49),silent=TRUE),"try-error"))
check("frequency feature interface absent",!exists("peak_magnitude_epochs",e,inherits=FALSE) &&
      !exists("modal_frequency",e,inherits=FALSE))
# Independent rounded vendor values from selected mechanical-test records.
fixture_root<-system.file("extdata",package="metronautica")
fixture<-readRDS(file.path(fixture_root,"leap_reference.rds"))
leap<-parse_raw_auto(file.path(fixture_root,"leap_reference.agsd"),return="bundle",full_scale_range_g=16)
actual<-as.matrix(leap$data[,c("ax_g","ay_g","az_g")])
check("LEAP actual packed bytes match vendor values at export precision",all(round(actual,3)==fixture$expected_g_3dp))
expected_time<-rep(fixture$record_timestamps,each=128L)+rep((0:127)/128,times=length(fixture$record_timestamps))
check("LEAP packet timestamps and sample order",same(as.numeric(leap$data$time),expected_time,1e-12))
check("LEAP gaps are retained without imputation",nrow(leap$data)==2048L && leap$meta$processing$leap_agsd_parser$recording_gaps$count>0)
check("LEAP nominal rate is not relabelled clock validation",leap$meta$acquisition$fs_nominal_hz==128)
check("unsupported LEAP calibration rate is rejected",inherits(try(e$leap_agsd_calibration(fixture$calibration,64),silent=TRUE),"try-error"))
result <- do.call(rbind,checks)
dest <- Sys.getenv("METRONAUTICA_VALIDATION_OUTPUT")
if (nzchar(dest)) {dir.create(dest,recursive=TRUE,showWarnings=FALSE)
    write.csv(result,file.path(dest,"known_signal_checks.csv"),row.names=FALSE)}
cat(nrow(result),"independent engine checks passed\n")
