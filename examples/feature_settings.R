# Canonical feature-settings recipe.
# Use the installed offline fixture.
# Set processing and aggregation explicitly.
library(metronautica)

# Load installed example recording ----
path <- system.file("extdata", "example_motion.csv", package = "metronautica", mustWork = TRUE)
x <- parse_raw_auto(path)

# Select example feature pipelines ----
configuration <- list(measures = c("VM", "ENMO", "MAD", "SVMBP_069_10"), epoch_s = 5, fs_hz = 100, svmbp_nyquist_action = "stop",
    quiet = TRUE)
five_seconds <- do.call(compute_accel_summaries, c(list(accel_input = x), configuration))
five_seconds$data_wide  # VM: g; remaining features: mg.

# Compare alternative epoch durations ----
configuration_10s <- configuration
configuration_10s$epoch_s <- 10
ten_seconds <- do.call(compute_accel_summaries, c(list(accel_input = x), configuration_10s))
nrow(five_seconds$data_wide)  # 4
nrow(ten_seconds$data_wide)  # Two epochs after longer aggregation.

# Supply explicit AI noise variance.
# Synthetic variance: 0.001^2 / 2.
# Estimate noise for real recordings.

# Request additional available features ----
other <- compute_accel_summaries(x, measures = c("ODBA", "VEDBA", "PDBA", "SVMGS", "SVMGSEC", "SVMGMEAN",
    "ROCAM", "AI", "ZANGLE", "ZANGLE_CHANGE"), epoch_s = 5, odba_running_mean_window_s = 3, ai_noise_var = 0.001^2/2,
    quiet = TRUE)
head(other$data_long)
other$data_long[other$data_long$measure == "AI", ]
# Features can label epochs differently.
# Exact joins retain unmatched cells.
# Inspect timestamps before joining.

# Standalone filtering changes input processing.

# Inspect separate axis filtering ----
filtered <- filter_accel_tbl(x, cutoff = 10)
qc_accel_tbl(filtered)[c("n_samples", "median_dt_ms", "invalid_axis")]
# SVMBP filters its own axes.

# Record resolved MIMS/AI settings.
# Retain configuration and session information.

# Save results and resolved settings ----
output_file <- tempfile(fileext = ".rds")
saveRDS(list(results = five_seconds, configuration = configuration, input_metadata = accel_meta(x), session = utils::sessionInfo()),
    output_file)
names(readRDS(output_file))
unlink(output_file)  # Remove temporary example output.
