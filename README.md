# Metronautica

Metronautica: Navigate wearable triaxial accelerometer signals into transparent metrology and reports.

Parse wearable recordings, inspect signal quality, characterise measurement response
and extract acceleration features. Developed for a research article under submission;
associated analyses and data are in [WAM](https://github.com/miltheo/wam).

[Getting started](docs/GETTING_STARTED.md) &middot; [Recording examples](docs/REAL_DATA_EXAMPLES.md) &middot; [PDF reference](docs/metronautica-reference.pdf) &middot; [Browser guide](docs/index.html)

## Processing workflow

![Metronautica workflow: parsing with QC, static and dynamic characterisation, features and reports; optional calibration and reassessment.](docs/assets/workflow-dark.svg)

[Native recordings](#native-recordings "GENEActiv/SENS BIN; Axivity CWA/AX3 CSV; ActiGraph GT3X/LEAP CSV/LEAP AGSD; HBK G-Link CSV.") &rarr;
[Acceleration tibble](#acceleration-tibble "time: POSIXct, UTC; ax_g, ay_g, az_g: numeric acceleration in g; attached meta: acquisition settings, provenance and QC.") &rarr;
[Static](#static-characterisation) &rarr; [Dynamic](#dynamic-characterisation) &rarr;
[Features](#feature-extraction-and-visual-comparison) &rarr; [Reports](#metrology-and-feature-reports).
[Optional calibration](#optional-calibration) returns to assessment with refreshed QC.

Each assessment can also be called independently. Open the browser guide locally
for clickable diagram navigation.

<a name="installation"></a>
## Installation

Install dependencies in R:

```r
install.packages(c("tibble", "dplyr", "data.table", "digest", "jsonlite",
                   "signal", "ggplot2", "ggrepel", "scales"))
```

Download this repository, then install its source directory from R:

```r
install.packages("path/to/metronautica", repos = NULL, type = "source")
```

Alternatively, run `R CMD INSTALL .` from the repository root in a terminal.
Optional decoder and plotting packages are listed in [Getting Started](docs/GETTING_STARTED.md#optional-packages).

<a name="quick-start"></a>
## Quick start

Run the installed offline example to inspect QC, calculate ENMO/MAD and see their
returned values and settings:

```r
library(metronautica)
example("getting-started", package = "metronautica")
```

For a native recording:

```r
accel <- parse_raw_auto("path/to/recording.agsd", return = "bundle", qc = TRUE)
accel_meta(accel)$processing$qc
features <- compute_accel_summaries(accel, measures = c("ENMO", "MAD"), epoch_s = 5)
head(features$data_wide)
```

[Worked static and dynamic examples with plots](docs/GETTING_STARTED.md#real-recording-examples)
use separately distributed samples. Ordinary package use requires neither WAM nor downloads.

<a name="native-recordings"></a>
## Native recordings

`parse_raw_auto()` detects the format and applies its documented decoder.
QC is enabled by default and attached as `meta$processing$qc` (`primary-five`).

| Device | Supported input |
|---|---|
| ActiGraph LEAP | AGSD, exported CSV |
| ActiGraph wGT3X-BT / GT9X Link | GT3X |
| Axivity AX3 | CWA, exported CSV |
| GENEActiv / SENS motion | BIN |
| HBK G-Link | Exported CSV |

See [decoder requirements and limits](docs/GETTING_STARTED.md#optional-packages),
[parser documentation](docs/reference.html#parse_raw_auto) and [parser source](R/m_parsers.R).

<a name="acceleration-tibble"></a>
## Acceleration tibble

Four columns: `time` (`POSIXct`, UTC), `ax_g`, `ay_g`, `az_g` (numeric, *g*).
Attached `meta` records acquisition settings, provenance and QC; read it with
`accel_meta()`. For already decoded data, construct with `as_accel_tbl()` and
attach diagnostics with `attach_qc()`.
[Data contract](docs/reference.html#common-data-format).

<a name="static-characterisation"></a>
## Static characterisation

Select a stationary interval with an explicit start and duration.
`static_metrology_from_tbl()` returns noise, signed 1-*g* VM offset bias, drift,
Allan deviation and plots. Individual outcome functions are also available.
[Example](docs/GETTING_STARTED.md#static-characterisation) &middot; [Reference](docs/reference.html#static_metrology_from_tbl) &middot; [Source](R/m_static.R).

<a name="dynamic-characterisation"></a>
## Dynamic characterisation

Specify test/reference recordings, the excitation schedule and measurement range.
`clip_dynamic_stages()` selects stages; `dynamic_metrology_report()` returns
response slope, signed VM bias, VM integral non-linearity, composite error and plots.
[Example](docs/GETTING_STARTED.md#dynamic-characterisation) &middot; [Reference](docs/reference.html#dynamic_metrology_report) &middot; [Source](R/m_dynamic.R).

<a name="feature-extraction-and-visual-comparison"></a>
## Feature extraction and visual comparison

`compute_accel_summaries()` returns epoch features and resolved settings;
`accel_metric_*()` functions provide individual calculations.
`plot_accel_clip()` shows acceleration; `plot_processed_metric()` shows features.
Activity counts use the standalone `accel_metric_agcounts()`.
[Combined comparison example](docs/REAL_DATA_EXAMPLES.md#feature-comparison) &middot; [Feature guide](docs/REAL_DATA_EXAMPLES.md#feature-settings) &middot; [Reference](docs/reference.html#compute_accel_summaries) &middot; [Source](R/m_accel_summary_suite.R).

<a name="metrology-and-feature-reports"></a>
## Metrology and feature reports

Retain outcomes with their units, reference, tested range and processing settings.
Static results provide `summary`/`meta`; dynamic results provide `stages`/`overall`/`meta`;
feature results provide `data_long`/`data_wide`/`settings`.
[Outcome reference](docs/reference.html#measurement-definitions).

<a name="optional-calibration"></a>
## Optional calibration

Use `dm_fit_vm_calibration()` and its application helpers when additional VM
calibration is warranted. Validate benefit independently, call `attach_qc()` on
the calibrated signal, then repeat the selected assessments.
[Methods](docs/reference.html#dm_fit_vm_calibration) &middot; [Refresh QC](docs/reference.html#attach_qc) &middot; [Source](R/m_dynamic.R).

## Documentation and citation

Use `help("function_name", package = "metronautica")` in R, or the
[HTML reference](docs/reference.html) and [PDF reference](docs/metronautica-reference.pdf).
[Documentation maintenance](docs/README.md) covers repository layout, tests and builds.

[Activity-count validation](docs/ACTIGRAPH_COUNTS.md) &middot; [Citation](CITATION.cff) &middot;
**GPL-3** ([licence](LICENSE.md), [dependency notices](docs/DEPENDENCY_LICENSING.md)).
Native sample distribution, provenance and GPL-3 licensing are documented in
[WAM](https://github.com/miltheo/wam/blob/main/samples/README.md).

Maintainer: [Millen James Theophilus](https://github.com/miltheo),
[ORCID](https://orcid.org/0000-0001-9823-7177).
[Report an issue](https://github.com/miltheo/metronautica/issues) with the function
call, error, `sessionInfo()` and a reproducible input where permitted.
