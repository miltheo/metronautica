# Offline features and epoch labels.
library(metronautica)

# Construct offline acceleration example ----
fs <- 100
seconds <- (0:1999)/fs
meta <- list(acquisition = list(
    fs_nominal_hz = fs, fs_derived_hz = fs, full_scale_range_g = 16))
x <- as_accel_tbl(
    as.POSIXct("2026-01-01", tz = "UTC") + seconds,
    0.2 * sin(2 * pi * 2 * seconds),
    0.2 * cos(2 * pi * 2 * seconds),
    rep(1, length(seconds)), meta)

# Attach signal diagnostics ----
x <- attach_qc(x, scope = "synthetic 20-second recording")
accel_meta(x)$processing$qc[c("n_samples", "median_dt_ms")]

# Compute default example features ----
# Defaults: ENMO and MAD.
# Alternatives: see feature identifiers.
features <- compute_accel_summaries(
    x, measures = c("ENMO", "MAD"), epoch_s = 5,
    fs_hz = fs, quiet = TRUE)
head(features$data_wide)
features$settings$metric_units
stopifnot(nrow(features$data_wide) == 4)

# AI uses bin-start labels.
# Zero variance disables noise subtraction.

# Compare differing epoch labels ----
mixed <- compute_accel_summaries(
    x, measures = c("ENMO", "AI"), epoch_s = 5,
    fs_hz = fs, ai_noise_var = 0, quiet = TRUE)
table(mixed$data_long$measure)  # Four epochs per feature
nrow(mixed$data_wide)  # Eight rows: different timestamp labels
stopifnot(nrow(mixed$data_wide) == 8)
