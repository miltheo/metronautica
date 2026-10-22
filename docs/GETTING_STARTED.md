# Getting started

[Workflow](../README.md#processing-workflow) &middot; [Function reference](reference.html) &middot; [PDF](metronautica-reference.pdf)

Load the installed package with `library(metronautica)`. Individual scripts do not
need to be sourced. Start offline, then substitute a native recording.

## Offline example

This synthetic 20-second example requires no external recordings or optional
packages. It demonstrates the interface, not stationary noise or behavioural validity.

<!-- EXAMPLE:offline:start -->
```r
library(metronautica)
fs <- 100
seconds <- (0:1999) / fs
meta <- list(acquisition = list(fs_nominal_hz = fs,
    fs_derived_hz = fs, full_scale_range_g = 16))
x <- as_accel_tbl(as.POSIXct("2026-01-01", tz = "UTC") + seconds,
    .2 * sin(2*pi*2*seconds), .2 * cos(2*pi*2*seconds),
    rep(1, length(seconds)), meta)
x <- attach_qc(x, scope = "synthetic 20-second recording")
accel_meta(x)$processing$qc[c("n_samples", "median_dt_ms")]

features <- compute_accel_summaries(x, measures = c("ENMO", "MAD"),
    epoch_s = 5, fs_hz = fs, quiet = TRUE)
head(features$data_wide)
features$settings$metric_units
stopifnot(nrow(features$data_wide) == 4)

```
<!-- EXAMPLE:offline:end -->

The result contains four five-second ENMO/MAD epochs in m*g*. `data_long` retains
feature-specific timestamps; `data_wide` joins exact timestamp labels. Keep
`settings` with the values. The complete installed example also demonstrates
mixed-feature timestamp conventions:

```r
example("getting-started", package = "metronautica")
```

## Your own recording

```r
accel <- parse_raw_auto("path/to/recording.agsd", return = "bundle", qc = TRUE)
accel_meta(accel)$processing$qc
features <- compute_accel_summaries(accel, measures = c("ENMO", "MAD"), epoch_s = 5)
```

Inspect QC and acquisition metadata before selecting the assessment interval.
QC flags recording properties; it does not repair or remove observations.
See the [data contract](reference.html#common-data-format) for table/bundle structure.

## Optional packages

| Operation | Requirement or supported scope |
|---|---|
| LEAP AGSD | Built-in; LEAP v2, dataVersion 3, firmware 2.1.0.106, 128 Hz, calibrationMethod 2 |
| Modern GT3X native-precision decoding | `read.gt3x` 1.2.0; other layouts/settings require the documented explicit legacy route |
| GENEActiv BIN | `GENEAread` |
| Unsupported fast AX3 CWA layouts | Optional `GGIRread` fallback |
| Interactive raw/feature plots | `plotly` |
| MIMS-unit | `MIMSunit` |
| Dynamic entropy diagnostics | `TSEntropies` |

Install only those needed for the selected function. Package functions do not
install dependencies. [Parser options](reference.html#parse_raw_auto).

## Real recording examples

The examples below use one LEAP unit and its paired HBK reference. They are
single-unit demonstrations, not between-device inference or behavioural validation.
Static data cover the selected 24 hours; dynamic data retain the first 78-minute
trial, including ten stages and adjustment periods.

Obtain the selected compressed recording attachments and `sample_index.csv` from
WAM and place them together in a local directory. A WAM clone alone does not include
the excluded recording payloads. Set the directory before running the examples:

```r
options(metronautica.sample_dir = "path/to/wam/samples")
```

No default download URL is configured. [Sample retrieval and provenance](REAL_DATA_EXAMPLES.md#sample-retrieval)
explains local files and explicit release URLs. The loader writes checksum-verified
copies under `metronautica-samples/` in the current project.

## Static characterisation

<!-- EXAMPLE:static:start -->
```r
library(metronautica)
path <- m_load_sample_data(device = "LEAP", type = "static")
info <- attr(path, "sample_info")
stationary <- parse_raw_auto(path, return = "bundle",
    time_shift_s = info$time_shift_s,
    full_scale_range_g = info$full_scale_range_g)
static_result <- static_metrology_from_tbl(stationary,
    start_utc = info$analysis_start_utc, duration_h = 24, progress = FALSE)
static_result$summary
static_result$drift_plot
static_result$allan_plot

```
<!-- EXAMPLE:static:end -->

![LEAP static example: signed VM drift over the selected 24 hours and axis-specific Allan deviation.](assets/examples/static-characterisation.png)

The left panel shows one-second VM means and their fitted drift; the right shows
axis-specific Allan deviation. No additional filtering or dynamic VM calibration
is applied. Panel titles are shortened for display. Interpretation requires
stationary conditions; the function does not establish stationarity.

## Dynamic characterisation

<!-- EXAMPLE:dynamic:start -->
```r
library(metronautica)
path <- m_load_sample_data(device = "LEAP", type = "dynamic")
info <- attr(path, "sample_info")
ref_info <- attr(path, "reference_info")
test <- parse_raw_auto(path, return = "bundle",
    time_shift_s = info$time_shift_s,
    full_scale_range_g = info$full_scale_range_g)
reference <- parse_raw_auto(attr(path, "reference_file"), return = "bundle",
    time_shift_s = ref_info$time_shift_s,
    full_scale_range_g = ref_info$full_scale_range_g)
test_stages <- clip_dynamic_stages(test, start_utc = info$trial_start_utc,
    n_stages = 10L, stage_min = 6, buffer_min = 2, rpm_start = 50, rpm_step = 50,
    trim_start_min = 1, trim_end_min = 1)
ref_stages <- clip_dynamic_stages(reference, start_utc = ref_info$trial_start_utc,
    n_stages = 10L, stage_min = 6, buffer_min = 2, rpm_start = 50, rpm_step = 50,
    trim_start_min = 1, trim_end_min = 1)
dynamic_result <- dynamic_metrology_report(test_stages, ref_stages,
    test_axis_fsr_g = info$full_scale_range_g,
    ref_axis_fsr_g = ref_info$full_scale_range_g,
    compute_entropy = FALSE, inspect_alignment = FALSE, add_plot = TRUE,
    progress = FALSE)
dynamic_result$stages
dynamic_result$overall
dynamic_result$plots$vm_mean_vs_rpm
dynamic_result$plots$linearity_vs_rpm

```
<!-- EXAMPLE:dynamic:end -->

![LEAP dynamic example: stage-mean VM and reference-based VM integral non-linearity across ten stages.](assets/examples/dynamic-characterisation.png)

All ten stages are retained, with one minute removed from each end of each
six-minute stage. The plots show stage-mean VM and reference-based VM integral
non-linearity. Timestamp shifts come from the sample catalogue. Alignment and
entropy diagnostics are disabled explicitly in this example; pairing and error
calculations use the documented functions. No additional filtering or dynamic VM
calibration is applied. Index-based pairing is not timestamp correction.

## Next steps

- [Combined feature comparison over one dynamic trial](REAL_DATA_EXAMPLES.md#feature-comparison).
- [Feature settings and output interpretation](REAL_DATA_EXAMPLES.md#feature-settings).
- [Calibration and independent reassessment](REAL_DATA_EXAMPLES.md#calibration).
- [Activity-count validation](ACTIGRAPH_COUNTS.md).
- [Function parameters, methods and units](reference.html).
