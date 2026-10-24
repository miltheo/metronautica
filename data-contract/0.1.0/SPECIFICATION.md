# Metronautica Tibble

A sample-level acceleration data contract for retaining signals and supporting later analyses

Specification version 0.1.0 · Metronautica 0.1.0 · 23 October 2026

## 1 Required data contract

The Metronautica Tibble retains sample timestamps and triaxial acceleration for later analysis. Its four data columns are the only required fields. Metadata, diagnostics, reports and bundle wrappers described below are optional implementations of the Metronautica pipeline.

### 1.1 Structure and representation

as_accel_tbl() constructs an accel_tbl inheriting from tbl_df, with an empty meta list by default. Compatible four-column tibbles and data frames also conform; no class tag, meta attribute or version field is required.

Required column names and order: time, ax_g, ay_g, az_g. Columns have equal length, with one row per decoded observation.

Axes are numeric acceleration in g; 1 g = 9.80665 m/s². time is POSIXct. UTC is the storage convention; the constructor preserves supplied instants, timezone and sample order. Invalid observations remain available for diagnostics. Structural conformance does not establish signal quality, calibration or suitability for an analysis.

Minimal construction without metadata

```r
x <- as_accel_tbl(time, ax_g, ay_g, az_g)
```

### 1.2 Required data columns

| Field | Type | Description |
| --- | --- | --- |
| time | POSIXct | Sample timestamp. Parsers store UTC. Duplicates, backward steps and invalid timestamps are retained for diagnostics; downstream functions require suitable timing. |
| ax_g | numeric | Acceleration on device X axis in g. |
| ay_g | numeric | Acceleration on device Y axis in g. |
| az_g | numeric | Acceleration on device Z axis in g. |

## 2 Optional pipeline metadata

Optional metadata is stored as attr(x, 'meta'), a list with file, acquisition and processing sections read by accel_meta(x). Every field below is a pipeline implementation field and may be absent when unknown or not produced. Parser bundles use list(data = x, meta = accel_meta(x)), with synchronised metadata. Some analyses require settings or explicit arguments beyond the core contract.

### 2.1 File metadata

| Field | Type | Description |
| --- | --- | --- |
| source_path | character | Input file path used for parsing. |
| source_name | character | Basename of the input file. |
| format | character | Detected or declared native format, e.g. actigraph_leap_agsd. |
| bytes | numeric | File size in bytes. |
| hash_sha256 | character | SHA-256 digest of the input file for integrity and reproducibility. |
| parser | character | Primary parsing engine (package or spec label). |
| parser_version | character | Package version or spec version string for traceability. |
| parsed_utc | character | UTC timestamp when the file was parsed. |
| warnings | character vector | Non-fatal parsing warnings (empty if none). |
| auto_parser | character | Automatic parser dispatcher name. |
| auto_parser_version | character | Dispatcher version; device-specific decoding details may also be recorded under processing. |

### 2.2 Acquisition metadata

| Field | Type | Description |
| --- | --- | --- |
| start_utc | POSIXct (UTC) | Minimum timestamp in decoded data. |
| end_utc | POSIXct (UTC) | Maximum timestamp in decoded data. |
| fs_nominal_hz | numeric | Nominal sampling rate from device header if available. |
| fs_derived_hz | numeric | Usually inverse median positive inter-sample interval. LEAP AGSD uses its nominal packet-reconstruction rate. Neither independently validates the device clock. |
| full_scale_range_g | numeric | Full-scale range in g (e.g., +/-8 g becomes 16 g). User-supplied or read from header when supported. |
| units | character | Acceleration unit label, fixed to 'g'. |
| device_vendor | character | Device vendor name (e.g., ActivInsights, SENS, Axivity, ActiGraph). |
| device_model | character | Device model family (e.g., GENEActiv, SENS motion, AX3/AX6, GT3X/GT3X+). |
| device_id | character | Device serial or unique identifier when available. |
| sensor_vendor | character | Optional sensor vendor field (user-supplied). |
| sensor_model | character | Optional sensor model field (user-supplied). |
| time_tz_declared | character | Time-zone declaration retained from the source, if available. |
| time_tz_parsed | character | Time-zone interpretation used during parsing; canonical output is UTC. |
| time_tz_source | character | Evidence for timestamp interpretation, e.g. container_epoch or unknown. |
| time_shift_s | numeric | Explicit shift applied to decoded timestamps, in seconds. |

### 2.3 Processing metadata

| Field | Type | Description |
| --- | --- | --- |
| parser_library | list | Parser/dispatcher name and version. |
| calibration | list | Decoding status, scale/calibration application, coefficient sources, applied_by, details, notes and caveats. Application does not establish physical traceability. |
| decode_notes | character | Critical decoding decisions and current QC scope. |
| qc | list | Post-decode primary-five signal diagnostics (Section 3). |
| history | list | Processing events, where recorded; e.g. clipping, filtering or researcher calibration. |
| reports | list | Attached static/dynamic assessment lists when enabled (Section 4). |

## 3 Optional signal diagnostics

Diagnostics are the recommended minimum workflow assessment, not required contract fields. The primary-five ruleset describes integrity, sample timing, axis-zero proportions, unusual cross-axis sequences and near-limit observations. parse_raw_auto attaches it at meta$processing$qc by default (qc = TRUE); as_accel_tbl does not. Use attach_qc for an existing table. Diagnostics do not remove, repair or certify samples; unknown range makes near-limit results unavailable.

| Field | Type | Description |
| --- | --- | --- |
| ruleset | character | Diagnostic definition identifier: primary-five. |
| n_samples | integer | Number of observations in the assessed table. |
| missing_time | numeric | Number of non-finite sample timestamps. |
| duplicate_time | numeric | Duplicated finite timestamps; each repeat after its first occurrence is counted. |
| backward_time | numeric | Consecutive finite time steps with dt < 0; duplicates are reported separately. |
| invalid_axis | numeric | Total non-finite X/Y/Z values. |
| median_dt_ms, iqr_dt_ms, longest_dt_ms | numeric | Median, IQR and maximum finite positive inter-sample interval, in milliseconds. |
| zero_x_n, zero_y_n, zero_z_n | numeric | Counts of finite exact zeros on each axis. |
| finite_x_n, finite_y_n, finite_z_n | numeric | Per-axis finite-value denominators. |
| zero_x_pct, zero_y_pct, zero_z_pct | numeric | 100 times exact-zero count divided by that axis's finite-value count. |
| all_zero_samples, all_zero_sequence | numeric, logical | Count of simultaneous finite X=Y=Z=0 samples and whether a qualifying adjacent pair exists (Section 3.1). |
| equal_nonzero_samples, equal_nonzero_sequence | numeric, logical | Count of finite X=Y=Z≠0 samples and whether a qualifying adjacent pair exists. |
| limit_g, near_limit_fraction | numeric | Per-axis limit = full_scale_range_g/2; near-limit fraction = 0.98. Invalid/unknown range gives NA limit. |
| near_limit_n, finite_axis_n | numeric | Pooled count of finite axis values with \|axis\| ≥ 0.98 × limit_g, and total finite X/Y/Z values. |
| near_limit_pct | numeric | 100 × near_limit_n/finite_axis_n; NA when range is unknown or no finite axes exist. |

### 3.1 Sequence checks and scope

A sequence requires at least two adjacent qualifying samples with finite timestamps, finite axes and a positive intervening time step. No minimum-duration run, gap-threshold count or saturation-duration summary is returned. Near-limit observations do not establish clipping or its cause. External subsetting can leave stale diagnostics; package static/dynamic clipping recomputes QC, while filtering/calibration invalidates it.

## 4 Optional assessment records

Static and dynamic records are optional pipeline attachments. static_metrology_from_tbl, static_noise_summary_from_tbl and dynamic_metrology_report default to attach_report = TRUE; FALSE adds no record. Assessments append to meta$processing$reports$static or $dynamic, each a list of records. Capture the returned data: inputs are not changed in place. Assessment schema_version = "1" versions the report structure independently of this 0.1.0 data contract.

| Field | Type | Description |
| --- | --- | --- |
| schema_version, type, function_name | character | Record schema version 1; static or dynamic; generating function. |
| created_utc, software | POSIXct, list | Assessment creation time in UTC; package and R versions. |
| status | character | current for the assessed source state and selection; historical after package signal/selection changes. |
| source, selection | list | File/acquisition/processing provenance and assessed window/stage bounds and sample counts. |
| settings, results, diagnostics | list | Calculation settings, numeric result tables and assessed-selection QC. Full static reports retain summary, Allan and one_hz tables; noise-only reports retain summary; dynamic reports retain stages and overall. |
| reference | list or NULL | Dynamic reference provenance and assessed selections; NULL for static reports. |
| invalidated_by | character vector | Present after invalidation: selection_changed or signal_or_selection_changed. Records remain as provenance. |

Static results return the complete input table as data and the assessed window as clipped_data; both carry the record. Dynamic results return data (the full test clip, otherwise its data table or concatenated matched stages) and the enriched test_clips bundle. Bundle metadata remain synchronised. Numerical calculations are unchanged by attachment.

Records exclude plots, raw signal copies and recursive parent metadata. Plots remain separate function outputs. Package clipping marks inherited records historical; filtering/calibration does likewise. External edits may leave stale records. A record's scope is its explicit assessed selection, not every sample in the retained signal.

## 5 Parser implementation notes

GENEActiv (.bin): parsed with GENEAread. full_scale_range_g may be inferred from Measurement_Range if present, or overridden by user.

SENS (.bin): fixed-record binary with scale_g_per_lsb (default 0.0078125 g per LSB). No header; full_scale_range_g is user-supplied when required.

Axivity (.cwa): built-in fast decoder for supported layouts, with GGIRread fallback. AX3 CSV exports are also supported.

ActiGraph (.gt3x): parsed with read.gt3x; native precision is the default, with an explicit legacy three-decimal mode. Supply measurement range when absent and needed for diagnostics.

ActiGraph LEAP: direct AGSD decoding applies stored coefficients and retains nominal packet-relative timestamps and gaps; validated layouts are documented in the package. CSV exports are also supported. HBK G-Link CSV is supported for reference recordings.

## 6 Related documentation

The help topics help("metronautica-tibble") and help("common-data-format") describe this contract.

[Specification index](../README.md) · [Reference summary](../../docs/reference.html#common-data-format) · [Minimal runnable example](../../examples/tibble_minimal.R) · [Native-recording retention example](../../examples/data_contract.R)
