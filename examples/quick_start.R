# Complete native-recording workflow.
# Configure metronautica.sample_dir before running.
library(metronautica)

# Static characterisation

# Retrieve native recording ----
path <- m_load_sample_data(device = "LEAP", type = "static")
info <- attr(path, "sample_info")
stationary <- parse_raw_auto(
    path, return = "bundle", time_shift_s = info$time_shift_s,
    full_scale_range_g = info$full_scale_range_g)
static_result <- static_metrology_from_tbl(
    stationary, start_utc = info$analysis_start_utc,
    duration_h = 24, progress = FALSE)
static_result$summary
static_result$drift_plot
static_result$allan_plot
# Retain the assessed recording ----
stationary <- static_result$data
accel_meta(stationary)$processing$reports$static[[1]]$results$summary

# Dynamic characterisation

# Retrieve native recording ----
path <- m_load_sample_data(device = "LEAP", type = "dynamic")
info <- attr(path, "sample_info")
ref_info <- attr(path, "reference_info")

# Parse test and reference signals ----
test <- parse_raw_auto(
    path, return = "bundle", time_shift_s = info$time_shift_s,
    full_scale_range_g = info$full_scale_range_g)
reference <- parse_raw_auto(
    attr(path, "reference_file"), return = "bundle",
    time_shift_s = ref_info$time_shift_s,
    full_scale_range_g = ref_info$full_scale_range_g)

# Specify identical excitation schedules ----
test_stages <- clip_dynamic_stages(
    test, start_utc = info$trial_start_utc,
    n_stages = 10L, stage_min = 6, buffer_min = 2,
    rpm_start = 50, rpm_step = 50, trim_start_min = 1, trim_end_min = 1)
ref_stages <- clip_dynamic_stages(
    reference, start_utc = ref_info$trial_start_utc,
    n_stages = 10L, stage_min = 6, buffer_min = 2,
    rpm_start = 50, rpm_step = 50, trim_start_min = 1, trim_end_min = 1)

# Compare retained dynamic stages ----
dynamic_result <- dynamic_metrology_report(
    test_stages, ref_stages, test_axis_fsr_g = info$full_scale_range_g,
    ref_axis_fsr_g = ref_info$full_scale_range_g,
    compute_entropy = FALSE, inspect_alignment = FALSE,
    add_plot = TRUE, progress = FALSE)
dynamic_result$stages
dynamic_result$overall
dynamic_result$plots$vm_mean_vs_rpm
dynamic_result$plots$linearity_vs_rpm
# Retain the assessed trial ----
test_stages <- dynamic_result$test_clips
retained <- dynamic_result$data

# Save samples and assessments ----
saveRDS(retained, "dynamic_trial.rds")
retained <- readRDS("dynamic_trial.rds")

# Feature extraction

# Select and compute example features ----
# Defaults: ENMO and MAD.
# Alternatives: see feature identifiers.
features <- compute_accel_summaries(
    retained, measures = c("ENMO", "MAD"), epoch_s = 5)
head(features$data_wide)
features$settings$metric_units
if (requireNamespace("plotly", quietly = TRUE)) {
    plot_processed_metric(features, "ENMO")
}
