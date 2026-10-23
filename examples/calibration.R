# Synthetic calibration and QC example.
library(metronautica)

# Construct known synthetic signals ----
t0 <- as.POSIXct("2026-01-01", tz = "UTC")
seconds <- (0:5999)/100
test_vm <- 1 + 0.2 * sin(2 * pi * 0.17 * seconds) + 0.003 * seconds
meta <- list(acquisition = list(fs_derived_hz = 100, full_scale_range_g = 16))
test <- as_accel_tbl(t0 + seconds, rep(0, 6000), rep(0, 6000), test_vm, meta)
reference <- as_accel_tbl(t0 + seconds, rep(0, 6000), rep(0, 6000), 0.02 + 1.1 * test_vm, meta)

# Construct matching demonstration stages ----
stage <- function(x) list(full = x, stages = list(rpm_50 = x), meta = accel_meta(x))

# Recover known linear mapping ----
fit <- dm_fit_vm_calibration(stage(test), stage(reference), select_by = "linear", fit_unit = "window",
    window_s = 5)
fit$summary[, c("vm_calibration_intercept", "vm_calibration_slope")]

# Apply calibration; refresh signal diagnostics ----
calibrated <- dm_apply_vm_calibration_tbl(attach_qc(test), fit$summary)
is.null(accel_meta(calibrated)$processing$qc)  # Previous QC was removed
calibrated <- attach_qc(calibrated)  # Diagnostics for changed signal
accel_meta(calibrated)$processing$signal_pipeline
