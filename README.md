# Metronautica

Metronautica: Navigate wearable triaxial accelerometer signals into transparent metrology and reports.

Parse recordings, assess signal quality, characterise measurement response and
extract acceleration features. Developed for a research article under submission;
analyses and recording samples are in [WAM](https://github.com/miltheo/wam).

[Getting started](docs/GETTING_STARTED.md) | [Reference PDF](docs/metronautica-reference.pdf) | [Browser guide](docs/index.html)

## Processing workflow

![Metronautica workflow: parsing with QC, static and dynamic characterisation, features and reports; optional calibration and reassessment.](docs/assets/workflow-dark.svg)

[Native recordings](#native-recordings "GENEActiv/SENS BIN; Axivity CWA/AX3 CSV; ActiGraph GT3X/LEAP CSV/LEAP AGSD; HBK G-Link CSV.") →
[Acceleration tibble](#acceleration-tibble "time: POSIXct, UTC; ax_g, ay_g, az_g: numeric acceleration in g; attached meta: acquisition settings, provenance and QC.") →
[Static](#static-characterisation) → [Dynamic](#dynamic-characterisation) →
[Features](#feature-extraction-and-visual-comparison) → [Reports](#metrology-and-feature-reports).

Stages can run independently; [optional calibration](#optional-calibration) returns
to assessment with refreshed QC. The browser guide provides clickable diagram boxes.

## Installation

Install dependencies in R:

```r
install.packages(c("tibble", "dplyr", "data.table", "digest", "jsonlite",
                   "signal", "ggplot2", "ggrepel", "scales"))
```

Download the repository, then install its directory:

```r
install.packages("path/to/metronautica", repos = NULL, type = "source")
```

Alternatively, run `R CMD INSTALL .` from the repository root.
[Optional packages](docs/GETTING_STARTED.md#optional-packages) support selected decoders and features.

## Quick start

```r
library(metronautica)
example("getting-started", package = "metronautica")
```

For a native recording:

```r
accel <- parse_raw_auto("path/to/recording.agsd", return = "bundle", qc = TRUE)
accel_meta(accel)$processing$qc
# Defaults: ENMO and MAD.
# Other features: see reference.
features <- compute_accel_summaries(accel, measures = c("ENMO", "MAD"), epoch_s = 5)
head(features$data_wide)
```

[Static and dynamic examples](docs/GETTING_STARTED.md#real-recording-examples)
include plots from separately distributed samples. Other package use requires no WAM downloads.

## Native recordings

`parse_raw_auto()` detects the format and attaches `primary-five` diagnostics
at `meta$processing$qc` by default.

| Device | Supported input |
|---|---|
| ActiGraph LEAP | AGSD, exported CSV |
| ActiGraph wGT3X-BT / GT9X Link | GT3X |
| Axivity AX3 | CWA, exported CSV |
| GENEActiv / SENS motion | BIN |
| HBK G-Link | Exported CSV |

Check [decoder requirements and limits](docs/reference.html#parse_raw_auto) before parsing.

## Acceleration tibble

Four columns: `time` (`POSIXct`, UTC), `ax_g`, `ay_g`, `az_g` (numeric, *g*).
Attached `meta` stores acquisition settings, provenance and QC; `accel_meta()` reads it.
For decoded data, use `as_accel_tbl()` and `attach_qc()`.
[Data contract](docs/reference.html#common-data-format).

## Static characterisation

Select a stationary interval. `static_metrology_from_tbl()` returns signed 1-*g*
VM offset bias, drift rate, static noise floor, Allan deviation and plots.
[Static example](docs/GETTING_STARTED.md#static-characterisation).

## Dynamic characterisation

Specify a reference, excitation schedule and measurement range.
`clip_dynamic_stages()` selects stages; `dynamic_metrology_report()` returns
VM response slope, signed VM bias, VM integral non-linearity, composite error and plots.
[Dynamic example](docs/GETTING_STARTED.md#dynamic-characterisation).

## Feature extraction and visual comparison

`compute_accel_summaries()` returns epoch features and settings; `accel_metric_*()`
functions calculate individual features. Use `plot_accel_clip()` for acceleration,
`plot_processed_metric()` for features and `accel_metric_agcounts()` for activity counts.
[Feature comparison and settings](docs/REAL_DATA_EXAMPLES.md#feature-comparison).

## Metrology and feature reports

Retain units, reference, tested range and processing settings with the outcomes.
Static reports return `summary`/`meta`; dynamic reports return `stages`/`overall`/`meta`;
feature results return `data_long`/`data_wide`/`settings`.
[Outcome definitions](docs/reference.html#measurement-definitions).

## Optional calibration

Fit and apply a VM mapping only when warranted. Independently validate its benefit,
refresh diagnostics with `attach_qc()` and repeat the selected assessments.
[Calibration example](docs/REAL_DATA_EXAMPLES.md#calibration).

## Help and citation

Use `help("function_name", package = "metronautica")` for parameters and methods.
[Documentation builds](docs/README.md) and [activity-count validation](docs/ACTIGRAPH_COUNTS.md)
cover maintenance and benchmarks.

[Citation](CITATION.cff) | **GPL-3** ([licence](LICENSE.md), [dependency notices](docs/DEPENDENCY_LICENSING.md)).
Sample provenance and licensing are maintained in WAM.

Maintainer: [Millen James Theophilus](https://github.com/miltheo),
[ORCID](https://orcid.org/0000-0001-9823-7177).
[Report issues](https://github.com/miltheo/metronautica/issues) with the call,
error, `sessionInfo()` and a reproducible input where permitted.
