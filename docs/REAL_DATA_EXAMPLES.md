# Native study recordings

These examples use controlled laboratory recordings, not behavioural validation
data. Samples contain one study unit per device model, rather than the full study
cohort. Native files retain the original measurement packets or rows and stored
calibration coefficients. The WAM sample provenance records the source, checksum,
analysis window and container bookkeeping changes.

## Locate the samples

The full native recordings are distributed separately by WAM. For sibling local
checkouts, configure the directory below (adjust it to your project):

```r
# For sibling source checkouts; adjust this path for your project.
options(metronautica.sample_dir =
    "../wam/samples")
```

The loader also accepts a fixed HTTPS WAM release-asset directory through
`base_url` or `metronautica.sample_base_url`; there is no default download URL. The package does not download data on installation
or loading. Small bundled examples/tests run without WAM or internet access.

## Parse, inspect and compute features

```r
library(metronautica)
path <- m_load_sample_data(device = "LEAP", type = "dynamic")
info <- attr(path, "sample_info")
accel <- parse_raw_auto(path, return = "bundle",
    time_shift_s = info$time_shift_s,
    full_scale_range_g = info$full_scale_range_g)
accel_meta(accel)$processing$qc
plot_accel_clip(accel, include_vm = TRUE)
enmo <- compute_accel_summaries(accel, measures = "ENMO", epoch_s = 5)
plot_processed_metric(enmo, "ENMO")
```

Replace `LEAP` with `AX3`, `SENS` or `GENEActiv` to use another device. GENEActiv
requires the optional GENEAread package. The SENS sample's documented timestamp
shift is applied explicitly above. Quality control is enabled by default and does
not remove or repair observations. Plots require the optional plotly package.

## Static characterisation

```r
path <- m_load_sample_data(device = "LEAP", type = "static")
info <- attr(path, "sample_info")
stationary <- parse_raw_auto(path, return = "bundle",
    time_shift_s = info$time_shift_s,
    full_scale_range_g = info$full_scale_range_g)
window <- static_clip(stationary, start_utc = info$analysis_start_utc,
                      duration_h = 24)
one_second <- static_1hz_means(window)
static_offset_vm_5min(one_second)  # g
drift <- static_drift(one_second)  # slopes in g/h
noise <- static_noise_summary_from_tbl(window,
    start_utc = info$analysis_start_utc, duration_h = 24)
allan <- static_allan(window)
plot_static_drift_vm(one_second, drift$fit_vm)
plot_static_allan(allan)
```

The static files cover the complete analysed 24 hours; decoding and processing
may take several minutes and substantial memory. Native boundary records can
extend slightly beyond the analysis window, which is selected explicitly here.
`static_metrology_from_tbl()` combines these calculations if a full report is
preferred. See each function's help for output fields and normalisation.

## Dynamic characterisation against the primary reference

```r
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
response <- dynamic_metrology_report(test_stages, ref_stages,
    test_axis_fsr_g = info$full_scale_range_g,
    ref_axis_fsr_g = ref_info$full_scale_range_g,
    compute_entropy = FALSE, inspect_alignment = FALSE, add_plot = FALSE,
    progress = FALSE)
response$stages
response$overall
```

The files retain the entire 78-minute first primary trial: ten six-minute stages
at 50-500 RPM and nine two-minute adjustments. The example explicitly removes
one minute at each end of each stage, as in the study; it does not modify the
native sample files. Set both trim arguments to zero to inspect full stages.
The reference requires its own +3600-second shift to use the study time base.

The response implementation matches unequal sample counts by nearest positions
on a sample-index grid. Clock shifts and alignment checks are separate from that
calculation. With one unit and one trial, the example demonstrates calculation,
not between-unit inference, trial-to-trial repeatability or device equivalence.
`m_dynamic_response()` provides the regression and error outcomes for a single
pair of vector-magnitude signals without constructing a full report.

## File storage

The loader copies local or explicitly downloads gzip-compressed native files, then restores them under
`metronautica-samples/` by default. It verifies checksums and writes a JSON sidecar.
Identical files are reused; different existing files are protected unless
`overwrite = TRUE`. Set `include_reference = FALSE` to omit the paired reference.
No full study data directory or study repository is required to run these examples.
