# Actual-data example for Metronautica Tibble 0.1.0.
# Only the four sample columns are required by the contract.
# The metadata, diagnostics and assessments below are optional pipeline additions.
# Requires WAM LEAP/reference native samples.
# Configure options(metronautica.sample_dir = "path/to/wam/samples") first.
library(metronautica)

# A deliberately stationary early hour provides a baseline assessment.
path <- m_load_sample_data("LEAP", "static")
info <- attr(path, "sample_info")
signal <- parse_raw_auto(path, full_scale_range_g = info$full_scale_range_g,
    time_shift_s = info$time_shift_s)
baseline <- static_metrology_from_tbl(signal,
    start_utc = info$analysis_start_utc, duration_h = 1, progress = FALSE)
retained_static <- baseline$data
accel_meta(retained_static)$processing$reports$static[[1]]$results$summary

# Dynamic assessment retains results with the tested trial and stage tables.
path <- m_load_sample_data("LEAP", "dynamic")
info <- attr(path, "sample_info")
ref_info <- attr(path, "reference_info")
signal <- parse_raw_auto(path, full_scale_range_g = info$full_scale_range_g,
    time_shift_s = info$time_shift_s)
reference <- parse_raw_auto(attr(path, "reference_file"),
    full_scale_range_g = ref_info$full_scale_range_g, time_shift_s = ref_info$time_shift_s)
schedule <- list(n_stages = 10L, stage_min = 6, buffer_min = 2,
    rpm_start = 50, rpm_step = 50, trim_start_min = 1, trim_end_min = 1)
test_clips <- do.call(clip_dynamic_stages, c(list(signal, start_utc = info$trial_start_utc), schedule))
ref_clips <- do.call(clip_dynamic_stages, c(list(reference, start_utc = ref_info$trial_start_utc), schedule))
assessment <- dynamic_metrology_report(test_clips, ref_clips,
    compute_entropy = FALSE, inspect_alignment = FALSE, add_plot = FALSE, progress = FALSE)
retained_dynamic <- assessment$data
accel_meta(retained_dynamic)$processing$reports$dynamic[[1]]$results$overall

# Alternative metrics remain derivable from the retained triaxial samples.
features <- compute_accel_summaries(retained_dynamic,
    measures = c("ENMO", "MAD", "SVMBP_069_10"), epoch_s = 5, quiet = TRUE)
counts <- accel_metric_agcounts(retained_dynamic, epoch_s = 5,
    fs_hz = accel_meta(retained_dynamic)$acquisition$fs_nominal_hz)
saveRDS(list(static_recording = retained_static, dynamic_trial = retained_dynamic,
    features = features, counts = counts), "retained_study_assessments.rds")
# attach_report = FALSE disables new attachments; plots remain separate outputs.
# One hour demonstrates the API; it is not a validated universal minimum.
