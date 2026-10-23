# Getting started

Load the installed package with `library(metronautica)`; sourcing scripts is unnecessary.

## Offline example

This synthetic 20-second recording requires no downloads or optional packages.

<!-- EXAMPLE:offline:start -->
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

```
<!-- EXAMPLE:offline:end -->

The result contains four five-second ENMO/MAD epochs in m*g*. Keep `settings`
with the values; `data_long` preserves feature timestamps and `data_wide` joins
exact labels.

## Your own recording

```r
accel <- parse_raw_auto("path/to/recording.agsd", return = "bundle", qc = TRUE)
accel_meta(accel)$processing$qc
features <- compute_accel_summaries(accel, measures = c("ENMO", "MAD"), epoch_s = 5)
```

ENMO and MAD are defaults; `measures` selects
[other features](reference.html#compute_accel_summaries).
Inspect QC and acquisition metadata before selecting intervals. Diagnostics flag
recording properties; they do not repair or remove observations.

## Optional packages

| Operation | Requirement or supported scope |
|---|---|
| LEAP AGSD | Built-in: LEAP v2, dataVersion 3, firmware 2.1.0.106, 128 Hz, calibrationMethod 2 |
| Modern GT3X native-precision decoding | `read.gt3x` 1.2.0; other layouts/settings require explicit legacy mode |
| GENEActiv BIN | `GENEAread` |
| Unsupported fast AX3 CWA layouts | `GGIRread` fallback |
| Interactive plots | `plotly` |
| MIMS-unit | `MIMSunit` |
| Dynamic entropy diagnostics | `TSEntropies` |

Install only the required packages; functions do not install dependencies.
[Parser reference](reference.html#parse_raw_auto) defines decoder settings and limits.

## Real recording examples

These single-unit examples use LEAP and its paired HBK reference: a 24-hour
stationary interval and the first 78-minute dynamic trial, including ten stages
and adjustment periods. They demonstrate application, not device equivalence or
behavioural validation.

Obtain the selected compressed attachments and `sample_index.csv` from the
[WAM sample guide](https://github.com/miltheo/wam/blob/main/samples/README.md).
A repository clone excludes recording payloads. Configure their local directory:

```r
options(metronautica.sample_dir = "path/to/wam/samples")
```

The loader restores checksum-verified files under `metronautica-samples/`.
[Sample retrieval](REAL_DATA_EXAMPLES.md#sample-retrieval) covers remote configuration;
no download URL is set by default.

## Static characterisation

<!-- EXAMPLE:static:start -->
```r
library(metronautica)

# Retrieve native recording ----
path <- m_load_sample_data(device = "LEAP", type = "static")
info <- attr(path, "sample_info")
stationary <- parse_raw_auto(path, return = "bundle", time_shift_s = info$time_shift_s, full_scale_range_g = info$full_scale_range_g)
static_result <- static_metrology_from_tbl(stationary, start_utc = info$analysis_start_utc, duration_h = 24,
    progress = FALSE)
static_result$summary
static_result$drift_plot
static_result$allan_plot

```
<!-- EXAMPLE:static:end -->

![LEAP static example: signed VM drift over the selected 24 hours and axis-specific Allan deviation.](assets/examples/static-characterisation.png)

Left: one-second VM means and fitted drift. Right: axis-specific Allan deviation.
No additional filtering or dynamic VM calibration is applied. Stationarity must
be established separately.

## Dynamic characterisation

<!-- EXAMPLE:dynamic:start -->
```r
library(metronautica)

# Retrieve native recording ----
path <- m_load_sample_data(device = "LEAP", type = "dynamic")
info <- attr(path, "sample_info")
ref_info <- attr(path, "reference_info")

# Parse test and reference signals ----
test <- parse_raw_auto(path, return = "bundle", time_shift_s = info$time_shift_s, full_scale_range_g = info$full_scale_range_g)
reference <- parse_raw_auto(attr(path, "reference_file"), return = "bundle", time_shift_s = ref_info$time_shift_s,
    full_scale_range_g = ref_info$full_scale_range_g)

# Specify identical excitation schedules ----
test_stages <- clip_dynamic_stages(test, start_utc = info$trial_start_utc, n_stages = 10L, stage_min = 6,
    buffer_min = 2, rpm_start = 50, rpm_step = 50, trim_start_min = 1, trim_end_min = 1)
ref_stages <- clip_dynamic_stages(reference, start_utc = ref_info$trial_start_utc, n_stages = 10L, stage_min = 6,
    buffer_min = 2, rpm_start = 50, rpm_step = 50, trim_start_min = 1, trim_end_min = 1)

# Compare retained dynamic stages ----
dynamic_result <- dynamic_metrology_report(test_stages, ref_stages, test_axis_fsr_g = info$full_scale_range_g,
    ref_axis_fsr_g = ref_info$full_scale_range_g, compute_entropy = FALSE, inspect_alignment = FALSE,
    add_plot = TRUE, progress = FALSE)
dynamic_result$stages
dynamic_result$overall
dynamic_result$plots$vm_mean_vs_rpm
dynamic_result$plots$linearity_vs_rpm

```
<!-- EXAMPLE:dynamic:end -->

![LEAP dynamic example: stage-mean VM and reference-based VM integral non-linearity across ten stages.](assets/examples/dynamic-characterisation.png)

Each six-minute stage loses one minute at each end. Plots show stage-mean VM
and reference-based VM integral non-linearity without additional filtering or
calibration. Catalogue shifts are applied separately to test and reference;
index-based pairing does not correct timestamps.

## Next steps

[Compare features](REAL_DATA_EXAMPLES.md#feature-comparison) or
[fit and assess calibration](REAL_DATA_EXAMPLES.md#calibration).
