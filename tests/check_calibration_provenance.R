# Calibration provenance and QC checks.
library(metronautica)
local({
    fails <- function(expr) inherits(try(force(expr), silent = TRUE), "try-error")
    x <- as_accel_tbl(as.POSIXct("2026-01-01", tz = "UTC") + (0:999)/100, rep(7, 1000), rep(0, 1000),
        rep(0, 1000), list(acquisition = list(fs_derived_hz = 100, full_scale_range_g = 16)))
    x <- attach_qc(x)
    cal <- data.frame(vm_calibration_intercept = 0, vm_calibration_slope = 2, vm_calibration_quadratic = 0,
        vm_calibration_direction = "ref_on_test")
    changed <- dm_apply_vm_calibration_tbl(x, cal)
    stopifnot(identical(changed$ax_g, rep(14, 1000)), identical(changed$time, x$time), is.null(accel_meta(changed)$processing$qc),
        accel_meta(changed)$processing$signal_pipeline == "calibrated", accel_meta(changed)$processing$history[[1]]$operation ==
            "dynamic_vm_calibration", accel_meta(attach_qc(changed))$processing$qc$near_limit_n == 1000,
        accel_meta(x)$processing$qc$near_limit_n == 0)
    parsed <- list(data = x, meta = accel_meta(x), qc = accel_meta(x)$processing$qc)
    result <- dm_apply_vm_calibration_tbl(parsed, cal)
    stopifnot(identical(result$data$ax_g, changed$ax_g), is.null(result$qc), identical(result$meta, accel_meta(result$data)))
    stage <- list(full = x, stages = list(rpm_50 = x, rpm_100 = NULL), meta = accel_meta(x), qc = list(stale = TRUE))
    for (fn in list(dm_apply_vm_calibration_tbl, dm_apply_vm_calibration_bundle)) {
        result <- fn(stage, cal)
        stopifnot(identical(result$full$ax_g, changed$ax_g), identical(result$stages$rpm_50$ax_g, changed$ax_g),
            is.null(result$stages$rpm_100), identical(result$meta, accel_meta(result$full)), is.null(result$qc),
            is.null(accel_meta(result$stages$rpm_50)$processing$qc))
    }
    for (bad in list(NA_real_, NaN, Inf, "2", c(1, 2))) {
        invalid <- as.list(cal)
        invalid$vm_calibration_slope <- bad
        stopifnot(fails(dm_apply_vm_calibration_tbl(x, invalid)), fails(dm_apply_vm_calibration_bundle(stage,
            invalid)))
    }
    stopifnot(fails(dm_apply_vm_calibration_tbl(x, cal[FALSE, ])), fails(dm_apply_vm_calibration_tbl(x,
        rbind(cal, cal))), fails(dm_apply_vm_calibration_tbl(x, cal[, "vm_calibration_slope", drop = FALSE])),
        fails(dm_apply_vm_calibration_tbl(x, transform(cal, vm_calibration_direction = "test_on_ref"))))
    stopifnot(identical(dm_apply_vm_calibration_bundle(parsed, cal)$data$ax_g, changed$ax_g))
    cat("Calibration arithmetic, container preservation, provenance, stale-QC invalidation and invalid-row errors passed.\n")
})
