# Metronautica

Direct R functions for wearable accelerometer parsing, primary-five
signal diagnostics, clipping, static and dynamic characterisation, filtering,
and time-domain acceleration features. The package is GPL-3.

## Offline first use

Run `example("getting-started", package = "metronautica")` for a complete
synthetic workflow without external recordings or optional packages. The
installed guide and PDF cover input construction, diagnostics, features,
settings and mixed-feature timestamps. `as_accel_tbl()` preserves supplied
metadata; it does not attach QC or infer sampling frequency.

## Install and start

Install the dependencies in DESCRIPTION and run `R CMD INSTALL .` from this folder.

The larger study samples are hosted separately by WAM. For local sibling
checkouts, configure their location once before running the examples:

```r
# For sibling source checkouts; adjust this path for your project.
options(metronautica.sample_dir =
    "../wam/samples")
library(metronautica)
path <- m_load_sample_data(device = "LEAP", type = "dynamic")
info <- attr(path, "sample_info")
accel <- parse_raw_auto(path, return = "bundle",
                        time_shift_s = info$time_shift_s,
                        full_scale_range_g = info$full_scale_range_g)
accel_meta(accel)$processing$qc
enmo <- compute_accel_summaries(accel, measures = "ENMO", epoch_s = 5)
plot_processed_metric(enmo, "ENMO")
```

QC is enabled by default; `qc = FALSE` skips it. Results are stored in
`meta$processing$qc`, with `ruleset = "primary-five"`. Diagnostics do not repair,
remove or reorder samples. Plotting requires the optional plotly package.
The automatic parser identity is recorded as `"m_parsers"` in
`meta$file$auto_parser` and `meta$processing$parser_library$name`.
`meta$file$parser` identifies the device-specific decoder.

## Source layout

All engine R code is directly in `R/`, without subfolders:

| Script | Functions and purpose |
|---|---|
| `m_parsers.R` | Native decoders, common data format, metadata; validated LEAP conversion |
| `m_qc.R` | Primary-five diagnostics, attachment and invalidation |
| `m_accel_clipper.R` | Generic time-window clipping and provenance |
| `m_static.R` | Stationary noise, offset, drift and Allan deviation |
| `m_dynamic.R` | Dynamic stage clipping, reference comparisons and VM calibration |
| `m_filter.R` | Forward-backward Butterworth filtering |
| `m_accel_summary_suite.R` | Direct time-domain features and epoch summaries |
| `m_agcounts.R` | Published-filter and custom-cutoff activity counts |
| `m_plotter.R` | Raw and processed interactive signal plots |
| `m_sample_data.R` | Copy native study samples into a project |

The installed package loads all ten scripts. Functions do not install dependencies.

## Calculation scope

Functions calculate features and metrological outcomes for supplied recordings
and selected intervals. Callers select calibration, processing and assessment
settings. Dynamic clipping requires explicit stage counts, durations, RPM values
and trims; static clipping requires an explicit duration.

## Individual calculations

```r
one_second <- static_1hz_means(accel)
drift <- static_drift(one_second)
allan <- static_allan(accel)
enmo_epochs <- accel_metric_enmo(accel, epoch_s = 5)
```

Use an appropriate stationary input for the static examples. Combined assessments
remain available through `static_metrology_from_tbl()` and
`dynamic_metrology_report()`. Direct feature functions return the same calculation
used by `compute_accel_summaries()`, without running a study workflow.

## Native sample data

`device` accepts LEAP, AX3, SENS or GENEActiv; `type` accepts static or dynamic.
Static samples cover the analysed 24-hour period. Dynamic samples retain the
continuous first primary trial, with all ten full stages and adjustment periods.
Native packet/page payloads and stored coefficients are preserved. Container
bookkeeping and boundary padding are recorded in WAM's `samples/provenance.json`.
The loader verifies checksums and writes the native file plus a provenance JSON
sidecar under `metronautica-samples/` in the current project by default.

Dynamic samples also copy the matching primary HBK G-Link-200 reference by default.
`attr(path, "reference_file")` gives its path; `attr(path, "reference_info")` gives
its metadata, including the required +3600-second timestamp shift. Set
`include_reference = FALSE` to copy only the wearable recording.

Compressed native samples are distributed as WAM release attachments, outside Git
history. For offline use, place the selected attachments in WAM's `samples/`
directory alongside its catalogue. They are not installed with this R package. The package retains their small
catalogue and checksums, plus small offline calculation/parser fixtures.
A fixed WAM release-asset URL can be supplied as `base_url`
or `options(metronautica.sample_base_url = release_asset_url)`. No download URL is configured by default. Downloads occur only when the sample loader is called;
installation and ordinary processing never require WAM or network access.

The loader retrieves only the requested recording and, for dynamic data, the
reference. Identical restored files are reused offline; an existing different
file is protected unless `overwrite = TRUE`. Both compressed and restored
checksums are verified before a target is replaced. `sample_dir` (or
`options(metronautica.sample_dir = path)`) remains the offline route.
The data are controlled laboratory recordings, not behavioural validation.
GENEActiv parsing requires GENEAread. SENS timestamp shifts are explicitly
supplied from sample_info rather than inferred from the signal.

## Reference documentation

R help in `man/` and [the standard R PDF manual](metronautica-reference.pdf)
document the actual direct functions. [Measurement definitions](MEASUREMENT_DEFINITIONS.md)
retain the approved technical definitions. Rebuild the PDF with
`Rscript tools/build_manual.R`; run the numerical checks with
`Rscript tools/validate.R` after installing the package.

[Worked real-data examples](REAL_DATA_EXAMPLES.md) cover static characterisation and all ten
dynamic stages against the primary reference. The same examples are included in
`help("native-study-examples")` and the PDF reference manual.

## Using the package with WAM

Install this package before running WAM's setup checks. WAM uses public package
functions. Its numbered study
commands start from cohort master sheets; they do not substitute the package's
single-unit sample recordings for the study inputs. Study statistics and supplementary spectral methods are documented in WAM and
the associated research article under submission.


## MIMS, measurement range and Activity Index settings

`MIMS` defaults to the upstream 0.2-5 Hz passband. Request the altered
passband with `mims_cutoffs = c(0.2, 10)`; neither option changes the
underlying MIMSunit calculation. MIMS requires the configured peak-to-peak
axis measurement span: `dynamic_range_g = 16` means -8 to +8 g. An explicit
argument takes precedence over valid `acquisition$full_scale_range_g`
metadata. Missing range information errors for MIMS; ENMO and MAD do not
require it. The observed signal extrema are not a measurement-range estimate.

Activity Index requires `ai_noise_var` by default: the stationary mean
per-axis noise variance in g squared, not the maximum-axis noise-floor SD.
For a verified stationary recording `stationary`, estimate it with:

```r
noise <- compute_ai_noise_var_from_static(stationary)
features <- compute_accel_summaries(recording, measures = "AI",
    ai_noise_var = noise$ai_noise_var)
features$settings$ai
```

The absolute scale and sum of one-second values remain the defaults.
Explicit `ai_noise_mode = "window_start"` opts into estimation from the
initial window (30 seconds by default); this requires a stationary start.
`ai_noise_mode = "quiet_segments"` opts into a signal-based quiet selection,
which does not establish stationarity. Estimation failures error; an explicit
`ai_noise_var = 0` deliberately disables noise subtraction. A supplied variance
takes precedence over estimation. For calibrated signals, use an appropriate
stationary variance on the same signal scale.

Summary outputs include `settings$mims`, `settings$ai`, and the resolved range
and source. Direct MIMS and Activity Index results carry a `settings`
attribute; the existing Activity Index `ai_noise_var_used` attribute remains.
Save the complete call, input provenance and session information as well.


## Explicit experiment settings and plotting

Static clipping and reports require `duration_h`; there is no assumed 24-hour
assessment. `meta$processing$static_window` records requested bounds, actual
sample bounds/span, sample count and whether the requested boundaries are
covered to within one estimated sampling interval. Incomplete boundary coverage
warns. This check does not establish internal continuity or stationarity.

`clip_dynamic_stages()` requires the number and duration of stages, buffer,
initial RPM, RPM increment and both trims explicitly. For the companion study:

```r
schedule <- list(n_stages = 10L, stage_min = 6, buffer_min = 2,
    rpm_start = 50, rpm_step = 50, trim_start_min = 1, trim_end_min = 1)
stages <- do.call(clip_dynamic_stages,
    c(list(x = recording, start_utc = trial_start), schedule))
```

Dynamic range-normalised outcomes require a valid test measurement span,
explicitly supplied or from metadata; 16 means -8 to +8 g. Invalid supplied
spans error. Missing reference span is reported as unavailable because it does
not normalise test-device errors. Reference pairing uses the documented sample-index method.

Band-pass features default to `svmbp_nyquist_action = "stop"` in the summary
function (`nyquist_action = "stop"` in the direct helper). Explicit `"clip"`
retains the historical behaviour. Requested and applied cutoffs are returned in
`settings$bandpass`, or the direct result's `settings` attribute.

`plot_processed_metric(features, "ENMO")` resolves the unit from
`features$settings$metric_units`. For a bare table, supply `unit` explicitly.
Labels do not convert values. Dynamic comparison plot limits are automatic
unless `comp_plot_ylim` is supplied. Plot limits do not modify numerical results.


## Calibration provenance and input contracts

Calibration applies the fitted VM polynomial and axis-scaling calculation. Valid coefficients must be one finite row mapping
test VM to reference VM. Invalid coefficients raise an error. A parser or dynamic bundle is accepted and its
container type is preserved. Every calibrated table records the coefficients,
calibrated signal state and a history event; inherited QC is invalidated.
Call `attach_qc()` explicitly to diagnose the modified signal.

`compute_ai_noise_var_from_static()` accepts the same acceleration table,
parser-bundle and clip-bundle forms as the feature functions. Invalid window, rate or retained-fraction inputs raise errors. The returned object is a list of variance, SD,
per-window estimates and settings, not a scalar.

The reference manual includes an implementation guide linking framework stages,
source functions and the approved manuscript definitions. Each diagnostic group
and relevant processing parameter is explained with units and calculation role.



## Standalone activity counts

`accel_metric_agcounts()` computes the published ActiGraph count pipeline with
exact filter coefficients by default. Supply `lower_hz` and `upper_hz` together
for a modified causal bandpass; coefficients and processing settings accompany
the output. This function is separate from `compute_accel_summaries()`; its `AG`
selector remains disabled. No agcounts or Python dependency is installed or used.

```r
counts <- accel_metric_agcounts(accel, epoch_s = 5, fs_hz = 128)
modified <- accel_metric_agcounts(accel, epoch_s = 5, fs_hz = 128,
                                 lower_hz = 0.69, upper_hz = 10)
attr(counts, "settings")
```

GT3X parsing defaults to native precision. Pass `precision = "legacy_3dp"` to
`parse_raw_auto()` when reproducing the earlier rounded conversion. Native
precision currently uses the guarded read.gt3x 1.2.0 modern-container decoder;
older formats retain the explicit legacy route. Parsing retains timestamp gaps.
Counts reject gaps by default; explicit fill/padding policies are recorded and
affected epochs are flagged. Custom count thresholds require separate validation.
See the count help page and the validation guide in `ACTIGRAPH_COUNTS.md`.

Maintainer: [Millen J. Theophilus](https://github.com/miltheo).

## Containers and epoch timestamps

`static_clip()` returns a table for table or bundle input. `clip_dynamic_stages()`
creates a stage bundle. Filtering or generic clipping of a stage bundle modifies
only its `full` recording; existing `stages` and `schedule` remain unchanged.
Filter the recording before constructing stages for metrology.

`compute_accel_summaries()` help lists all accepted feature identifiers and units.
Sample-level features, Activity Index and MIMS can use different timestamp labels.
The wide output joins exact labels, so extra rows and unpaired cells can occur
without missing acceleration. Inspect each feature's intervals before combining
results; do not replace unpaired values with zero. See `help("getting-started")`
for an executable example and the function help for field dictionaries.
