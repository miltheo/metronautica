# Native recording trace examples.
library(metronautica)

# Static trace
path <- m_load_sample_data("LEAP", "static")
stationary <- parse_raw_auto(path, full_scale_range_g = 16)
segment <- clip_bundle(stationary, start_time = attr(path, "sample_info")$analysis_start_utc, duration_s = 10)
plot_accel_clip(segment, include_vm = TRUE, title = "LEAP: 10-second static segment")

# Dynamic trace
path <- m_load_sample_data("LEAP", "dynamic", include_reference = FALSE)
motion <- parse_raw_auto(path, full_scale_range_g = 16)
plot_accel_clip(motion, include_vm = TRUE, title = "LEAP: ten-stage dynamic trial")

# Signal diagnostics
head(motion, 3)
qc <- accel_meta(motion)$processing$qc
qc[c("n_samples", "median_dt_ms", "near_limit_pct")]

# Feature extraction
features <- compute_accel_summaries(
    motion, measures = c("ENMO", "SVMGMEAN", "SVMBP_069_10", "MAD"),
    epoch_s = 5, epoch_anchor = "start", quiet = TRUE)
head(features$data_wide)
features$settings$metric_units

# Processed feature trace
plot_processed_metric(features, "ENMO", title = "LEAP: ENMO, five-second epochs")
