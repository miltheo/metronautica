# Recording and processing guide

Start with the [static and dynamic examples](GETTING_STARTED.md#real-recording-examples).
Use this guide for sample retrieval, feature settings and calibration.

## Sample retrieval

[WAM](https://github.com/miltheo/wam/blob/main/samples/README.md) maintains recording
contents, provenance, distribution and licensing. `m_load_sample_data()` accepts
LEAP, AX3, SENS or GENEActiv, with `type = "static"` or `"dynamic"`:

```r
options(metronautica.sample_dir = "path/to/wam/samples")
path <- m_load_sample_data(device = "LEAP", type = "dynamic")
```

For remote retrieval, explicitly set `metronautica.sample_base_url` to the published
release-attachment directory. No URL is preconfigured.

Dynamic samples include the HBK reference unless `include_reference = FALSE`.
Returned attributes are `sample_info`, `reference_file` and `reference_info`.
Parse each file with its own time shift and span: the reference requires +3600 s,
not the wearable shift. No clock-rate correction is inferred.

The loader verifies compressed/restored SHA-256 checksums, reuses identical files
and protects different targets unless `overwrite = TRUE`. Recordings and JSON
sidecars are written to `metronautica-samples/` by default.
[Loader parameters](reference.html#m_load_sample_data).

## Assessment intervals

| Assessment | Requirements |
|---|---|
| Static | Explicit start and duration. Incomplete boundary coverage warns; stationarity and internal continuity require separate checks. Full recordings can take several minutes and substantial memory to parse. |
| Dynamic | Full stage schedule, start/end trims and a configured test-axis peak-to-peak span: 16 *g* means -8 to +8 *g*. Observed extrema cannot substitute for acquisition limits. Review time alignment separately from sample-index matching. |

Filter or clip the recording **before** constructing stage bundles: these operations
change `full` but leave existing `stages` unchanged. Calibration application processes
both. [Container contracts](reference.html#implementation-guide).

## Feature settings

A feature pipeline specifies epoch duration, sampling rate, axis filtering,
calibration state and aggregation. Retain its resolved `settings`.

| Feature or operation | Required decision |
|---|---|
| Activity Index | Supply stationary mean-axis noise variance (`ai_noise_var`, *g*²), estimated with `compute_ai_noise_var_from_static()`; noise-floor SD is a different quantity |
| MIMS | Supply the configured measurement span; default passband 0.2-5 Hz |
| Band-pass SVM | Specify cutoffs; invalid Nyquist limits error by default; explicit clipping and applied cutoffs are recorded |
| Activity counts | Use `accel_metric_agcounts()`; `AG` is not a summary selector; custom filters require separate interpretation |
| Feature plots | `plot_processed_metric()` reads summary units; bare tables require a unit label |

Activity Index, MIMS and sample-level features can use different
[epoch labels](#epoch-labels). Check intervals before joining; do not zero-fill
unpaired values.

<details>
<summary>Code: feature settings</summary>

[feature_settings.R](../examples/feature_settings.R): epochs, feature families,
filtering and saving settings using the offline fixture.

<!-- EXAMPLE:settings:start -->
```r
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
```
<!-- EXAMPLE:settings:end -->

</details>

## Feature comparison

The same LEAP trial is processed with ENMO, mean gravity-subtracted SVM,
band-pass SVM and MAD. Comparable ranges share a panel; MAD uses a separate scale.
Values remain in m*g* without amplitude normalisation. Solid/dashed lines distinguish
coincident ENMO/SVM traces.

<details>
<summary>Code: feature comparison</summary>

[feature_comparison.R](../examples/feature_comparison.R) requires the dynamic sample.

<!-- EXAMPLE:comparison:start -->
```r
# Canonical real-recording comparison and plot.
# Requires configured WAM sample attachments.
library(metronautica)
library(ggplot2)

# Load native trial sample ----
path <- m_load_sample_data(device = "LEAP", type = "dynamic", include_reference = FALSE)
info <- attr(path, "sample_info")
recording <- parse_raw_auto(path, return = "bundle", time_shift_s = info$time_shift_s, full_scale_range_g = info$full_scale_range_g)

# Select and compute feature pipelines ----
comparison <- compute_accel_summaries(recording, measures = c("ENMO", "SVMGMEAN", "SVMBP_069_10", "MAD"),
    epoch_s = 5, epoch_anchor = "start", quiet = TRUE)
comparison$settings$metric_units

# Group compatible feature scales ----
plot_data <- comparison$data_long
main_panel <- "ENMO, mean gravity-subtracted SVM and band-pass SVM"
plot_data$panel <- factor(ifelse(plot_data$measure == "MAD", "MAD", main_panel), levels = c(main_panel,
    "MAD"))

# Mark scheduled excitation intervals ----
start <- as.POSIXct(info$trial_start_utc, tz = "UTC")
stages <- data.frame(start = start + (0:9) * 8 * 60, end = start + (0:9) * 8 * 60 + 6 * 60, rpm = seq(50,
    500, 50))

# Plot features over shared time ----
comparison_plot <- ggplot(plot_data, aes(time, value, colour = measure, linetype = measure)) +
    geom_rect(data = stages,
        aes(xmin = start, xmax = end, ymin = -Inf, ymax = Inf), inherit.aes = FALSE, fill = "grey92", colour = NA) +
    geom_line(linewidth = 0.5) +
    geom_text(data = stages, aes(x = start + 3 * 60, y = Inf, label = paste(rpm,
        "RPM")), inherit.aes = FALSE, vjust = 1.4, size = 2.7) +
    facet_wrap(~panel, ncol = 1, scales = "free_y") +
    scale_colour_manual(values = c(ENMO = "#0072B2", SVMGMEAN = "#D55E00", SVMBP_069_10 = "#009E73",
        MAD = "#CC79A7"), breaks = c("ENMO", "SVMGMEAN", "SVMBP_069_10", "MAD"), labels = c("ENMO", "Mean gravity-subtracted SVM",
        "Band-pass SVM (0.69-10 Hz)", "MAD")) +
    guides(colour = guide_legend(override.aes = list(linetype = c("solid",
        "22", "solid", "solid")))) +
    scale_linetype_manual(values = c(ENMO = "solid", SVMGMEAN = "22", SVMBP_069_10 = "solid",
        MAD = "solid"), guide = "none") +
    scale_x_datetime(date_labels = "%H:%M", date_breaks = "10 min",
        timezone = "UTC", expand = expansion(mult = c(0, 0.01))) +
    scale_y_continuous(expand = expansion(mult = c(0.03,
        0.18))) +
    labs(x = "Time (UTC)", y = expression("Epoch mean (m" * italic(g) * ")"), colour = NULL,
        title = "LEAP: feature pipelines over one dynamic trial", subtitle = paste("Five-second epochs; native decoded signal;",
        "no additional VM calibration")) +
    theme_bw(base_size = 11) +
    theme(legend.position = "bottom",
        strip.text.y = element_text(angle = 0), strip.background = element_rect(fill = "white"))
comparison_plot
```
<!-- EXAMPLE:comparison:end -->

</details>

![Four feature pipelines over the same LEAP dynamic trial, grouped by their observed ranges.](assets/examples/feature-comparison.png)

Shading marks six-minute excitation stages; adjustment intervals remain visible.
Five-second epochs use start labels. Only band-pass SVM receives its 0.69-10 Hz
axis filter; no additional VM calibration is applied. This within-recording
comparison establishes neither device equivalence nor behavioural validity.

## Epoch labels

Equal epoch durations need not produce equal labels. For 20 seconds at 100 Hz,
five-second centre-labelled ENMO epochs occur at 2.49, 7.49, 12.49 and 17.49 s;
AI labels occur at 2, 7, 12 and 17 s. The exact-timestamp wide join has eight rows.
These unpaired cells do not necessarily indicate missing acceleration.

<details>
<summary>Code: epoch labels</summary>

[offline_workflow.R](../examples/offline_workflow.R).

<!-- EXAMPLE:epochs:start -->
```r
# Offline features and epoch labels.
library(metronautica)

# Construct offline acceleration example ----
fs <- 100
seconds <- (0:1999)/fs
meta <- list(acquisition = list(fs_nominal_hz = fs, fs_derived_hz = fs, full_scale_range_g = 16))
x <- as_accel_tbl(as.POSIXct("2026-01-01", tz = "UTC") + seconds, 0.2 * sin(2 * pi * 2 * seconds), 0.2 *
    cos(2 * pi * 2 * seconds), rep(1, length(seconds)), meta)

# Attach signal diagnostics ----
x <- attach_qc(x, scope = "synthetic 20-second recording")
accel_meta(x)$processing$qc[c("n_samples", "median_dt_ms")]

# Compute default example features ----
# Defaults: ENMO and MAD.
# Alternatives: see feature identifiers.
features <- compute_accel_summaries(x, measures = c("ENMO", "MAD"), epoch_s = 5, fs_hz = fs, quiet = TRUE)
head(features$data_wide)
features$settings$metric_units
stopifnot(nrow(features$data_wide) == 4)

# AI uses bin-start labels.
# Zero variance disables noise subtraction.

# Compare differing epoch labels ----
mixed <- compute_accel_summaries(x, measures = c("ENMO", "AI"), epoch_s = 5, fs_hz = fs, ai_noise_var = 0,
    quiet = TRUE)
table(mixed$data_long$measure)  # Four epochs per feature
nrow(mixed$data_wide)  # Eight rows: different timestamp labels
stopifnot(nrow(mixed$data_wide) == 8)
```
<!-- EXAMPLE:epochs:end -->

</details>

## Calibration

`dm_fit_vm_calibration()` fits linear/quadratic VM mappings in the selected
regression direction. Application requires test-to-reference coefficients and
preserves vector direction; it is a scalar VM mapping, not axis calibration.
Refresh invalidated QC with `attach_qc()` and validate benefit independently.

<details>
<summary>Code: calibration and QC</summary>

[calibration.R](../examples/calibration.R) recovers a known synthetic VM mapping.

<!-- EXAMPLE:calibration:start -->
```r
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
```
<!-- EXAMPLE:calibration:end -->

</details>

## Results and reporting

Retain the reference, interval, measurement range, signal state, timing assumptions,
units and settings. Within-stage epoch-mean VM variability differs from
trial-to-trial repeatability; error estimates are not a complete uncertainty budget.
[Outcome definitions](reference.html#measurement-definitions) distinguish these quantities.
