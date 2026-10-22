# Recording and processing guide

[Getting started](GETTING_STARTED.md) · [Function reference](reference.html) · [PDF](metronautica-reference.pdf)

Worked code and plot previews are in [Getting Started](GETTING_STARTED.md#real-recording-examples).
This guide covers sample retrieval and processing choices.

## Sample retrieval

`m_load_sample_data()` accepts `device = "LEAP"`, `"AX3"`, `"SENS"` or `"GENEActiv"`
and `type = "static"` or `"dynamic"`. Static recordings cover the selected 24 hours;
dynamic recordings include all ten stages of the first primary trial. They retain
native payloads and stored coefficients, with boundary handling documented in provenance.
They are selected recording intervals, not complete original downloads.

The compressed recordings are separate WAM release attachments, outside Git history.
Before running an example, place the required attachments beside `sample_index.csv`
and set `options(metronautica.sample_dir = "path/to/samples")`. A repository clone
without attachments is insufficient. Alternatively, explicitly configure
`options(metronautica.sample_base_url = "https://…/release-asset-directory")` with
an actual published release directory. No URL is configured by default.

Dynamic retrieval includes the HBK reference unless `include_reference = FALSE`.
The returned path carries `sample_info`, `reference_file` and `reference_info`
attributes. Use each file's own time shift and measurement span when parsing.
The reference requires its documented +3600-second shift; do not apply the
wearable's shift to it. No clock-rate correction is inferred.

Compressed and restored SHA-256 checksums are verified. Identical local outputs
are reused; different existing files are protected unless `overwrite = TRUE`.
The default destination is `metronautica-samples/`; each recording has a JSON
provenance sidecar. [Loader parameters](reference.html#m_load_sample_data).

## Assessment intervals

Static assessment requires an explicit start and duration. Incomplete boundary
coverage warns; that check does not establish stationarity or internal continuity.
Full static parsing can require several minutes and substantial memory.

Dynamic assessment requires the full stage schedule and both trims. Apply any
intended filtering before constructing stage bundles. Filtering or generic clipping
of a stage bundle modifies `full`, leaving its existing `stages` unchanged.
[Container contracts](reference.html#implementation-guide).

A test-axis peak-to-peak measurement span is required for normalised dynamic
errors: 16 g means -8 to +8 g. Observed signal extrema do not establish this span.
Review time alignment independently of sample-index matching.
[Dynamic methods](reference.html#dynamic_metrology_report).

## Feature settings

Epoch duration, rate, axis filtering, calibration state and aggregation define a
feature pipeline. Retain `settings` with the results. Use the direct
`accel_metric_*()` functions for individual calculations.

| Feature or operation | Required decision |
|---|---|
| Activity Index | Supply stationary per-axis noise variance (`ai_noise_var`, g²), estimated with `compute_ai_noise_var_from_static()`; noise-floor SD is a different quantity |
| MIMS | Supply the configured measurement span; default passband is 0.2-5 Hz; request alternatives explicitly |
| Band-pass SVM | Specify cutoffs; invalid Nyquist limits error by default; explicit clipping and applied cutoffs are recorded |
| Activity counts | Use `accel_metric_agcounts()`; `AG` is not a summary selector; custom filters require separate interpretation |
| Processed-signal plotting | `plot_processed_metric()` reads units from summary settings; bare tables require an explicit unit label |

Sample-level features, Activity Index and MIMS can label epochs differently.
`data_wide` joins exact timestamps; additional rows and unpaired cells do not
necessarily indicate missing acceleration. Inspect intervals before joining or
comparing features, and do not replace unpaired values with zero.
[Feature parameters](reference.html#compute_accel_summaries).

## Calibration

`dm_fit_vm_calibration()` fits linear/quadratic VM mappings in the specified
regression direction. Apply only test-to-reference coefficients using the
application helpers. The scalar mapping preserves vector direction; it is not
an axis-specific calibration. Application invalidates inherited QC. Re-run
`attach_qc()` and assess benefit on an independent recording before retaining
the calibration. [Calibration methods](reference.html#dm_fit_vm_calibration).

## Results and reporting

Static results return summaries, one-second means, Allan curves and plots;
dynamic results return stage/pooled outcomes and plots; feature results return
long/wide tables and settings. Keep the reference, interval, measurement range,
signal state, timing assumptions, units and settings with the results.

Within-stage epoch-mean VM variability is distinct from repeated-trial
repeatability. Error estimates are not a complete uncertainty budget. WAM
provides cohort-level analyses and equivalence tests.
[Canonical definitions](reference.html#measurement-definitions).
